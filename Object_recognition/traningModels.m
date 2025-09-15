%% Machine Learning Pipeline for Shape Classification

%% 1. Data Loading and Preparation
clc; clear; close all;

% Load feature matrix
try
    load('FeatureMatrix_v2.mat', 'featureMatrix2');
    fprintf('Loaded feature matrix with %d samples\n', size(featureMatrix2, 1));
catch
    error('Failed to load FeatureMatrix.mat - file missing or corrupted');
end

% Define class labels and names
labels = [1 1 1 1 3 3 3 3 3 3 1 3 1 3 1 3 1 3 1 3 1 3 2 3 2 3 2 3 2 3 3 2 4 3 2 4 3 2 4 3 2 4 2 2 1 2 2 1 2 2 1 2 2 1 2 2 1 2 2 1 4 4 3 4 4 3 4 4 3 3 1 2 1 1 4 3 1 2 3 2 2 4 1 2 2 3 3 4 2 2 3 3 1 3 2 4]';
classNames = {'Square', 'Rectangle', 'Triangle', 'Bridge'};

% Verify data dimensions match
if length(labels) > size(featureMatrix2, 1)
    fprintf('Trimming labels from %d to %d to match feature matrix\n', ...
            length(labels), size(featureMatrix2, 1));
    labels = labels(1:size(featureMatrix2, 1));
elseif size(featureMatrix2, 1) ~= length(labels)
    error('Data mismatch: featureMatrix has %d samples but labels has %d', ...
          size(featureMatrix2, 1), length(labels));
end

% Normalize features
featureMatrixNorm = zscore(featureMatrix2);

% Show class distribution
disp('Class distribution:');
tabulate(labels)

%% 2. Random Forest Model
fprintf('\n=== Training Random Forest ===\n');

% Train random forest with 100 trees
rfModel = fitcensemble(featureMatrixNorm, labels, ...
    'Method', 'Bag', ...
    'NumLearningCycles', 100, ...
    'Learners', templateTree('MaxNumSplits', 10));

% Cross-validate and evaluate
cvRf = crossval(rfModel, 'KFold', 5);
rfPredictions = kfoldPredict(cvRf);
rfStats = evaluateModel(labels, rfPredictions, 'Random Forest', classNames);


%% 3. Decision Tree Model
%rng(1); % For reproducibility

fprintf('\n=== Training Decision Tree ===\n');

% Train basic decision tree
treeModel = fitctree(featureMatrixNorm, labels);

% Cross-validate and evaluate
cvTree = crossval(treeModel, 'KFold', 5);
treePredictions = kfoldPredict(cvTree);
treeStats = evaluateModel(labels, treePredictions, 'Decision Tree', classNames);

%% 4. k-Nearest Neighbors Model
fprintf('\n=== Training k-NN ===\n');

% Train final model with best parameters
knnModel = fitcknn(featureMatrixNorm, labels, ...
                 'NumNeighbors', 1, ...
                 'Distance', 'euclidean');

% Evaluate final model
cvKnn = crossval(knnModel, 'KFold', 5);
knnPredictions = kfoldPredict(cvKnn);
knnStats = evaluateModel(labels, knnPredictions, ...
                       sprintf('k-NN (k=%d, %s)', bestK, bestDistance), ...
                       classNames);

%% 5. Neural Network Model
fprintf('\n=== Training Neural Network ===\n');

% Prepare data for neural net
labels_cat = categorical(labels);

% Stratified 70/30 split
cv = cvpartition(labels_cat, 'HoldOut', 0.3, 'Stratify', true);
XTrain = featureMatrixNorm(cv.training, :);
YTrain = labels_cat(cv.training);
XTest = featureMatrixNorm(cv.test, :);
YTest = labels_cat(cv.test);

% network architecture
layers = [
    featureInputLayer(4)
    fullyConnectedLayer(32)
    batchNormalizationLayer
    reluLayer
    fullyConnectedLayer(16)
    batchNormalizationLayer
    reluLayer
    fullyConnectedLayer(4)
    softmaxLayer    
    classificationLayer
];

% Training options
options = trainingOptions('adam', ...
    'MaxEpochs', 100, ...
    'MiniBatchSize', 16, ...
    'InitialLearnRate', 0.0005, ...
    'Shuffle', 'every-epoch', ...
    'ValidationData', {XTest, YTest}, ...
    'ValidationFrequency', 5, ...
    'L2Regularization', 0.01, ...
    'Plots', 'training-progress', ...
    'Verbose', true);

% Train network
net = trainNetwork(XTrain, YTrain, layers, options);

% Evaluate network
nnPredictions = classify(net, XTest);
nnStats = evaluateModel(YTest, nnPredictions, 'Neural Network', classNames);

%% 6. comparison
fprintf('\n=== Final Model Comparison ===\n');
fprintf('1. Random Forest: %.2f%% accuracy\n', rfStats.accuracy*100);
fprintf('2. Decision Tree: %.2f%% accuracy\n', treeStats.accuracy*100);
fprintf('3. k-NN (k=%d): %.2f%% accuracy\n', bestK, knnStats.accuracy*100);
fprintf('4. Neural Network: %.2f%% accuracy\n', nnStats.accuracy*100);


%% func to evaluate models
function stats = evaluateModel(trueLabels, predLabels, modelName, classNames)
    % Calculate confusion matrix and accuracy
    confMat = confusionmat(trueLabels, predLabels);
    accuracy = sum(diag(confMat))/sum(confMat(:));

    fprintf('\n%s Evaluation:\n', modelName);
    fprintf('Accuracy: %.2f%%\n', accuracy*100);
    
    % Plot confusion matrix
    figure('Name', modelName);
    confusionchart(trueLabels, predLabels, ...
        'RowSummary', 'row-normalized', ...
        'ColumnSummary', 'column-normalized', ...
        'Title', [modelName ' Performance']);
    

    stats.accuracy = accuracy;
    stats.confusionMatrix = confMat;
end