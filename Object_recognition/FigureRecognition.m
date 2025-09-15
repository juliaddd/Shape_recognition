function varargout = FigureRecognition(varargin)
% FIGURERECOGNITION MATLAB code for FigureRecognition.fig
%      FIGURERECOGNITION, by itself, creates a new FIGURERECOGNITION or raises the existing
%      singleton*.
%
%      H = FIGURERECOGNITION returns the handle to a new FIGURERECOGNITION or the handle to
%      the existing singleton*.
%
%      FIGURERECOGNITION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FIGURERECOGNITION.M with the given input arguments.
%
%      FIGURERECOGNITION('Property','Value',...) creates a new FIGURERECOGNITION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before FigureRecognition_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to FigureRecognition_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help FigureRecognition

% Last Modified by GUIDE v2.5 21-Apr-2025 18:08:41

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FigureRecognition_OpeningFcn, ...
                   'gui_OutputFcn',  @FigureRecognition_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before FigureRecognition is made visible.
function FigureRecognition_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to FigureRecognition (see VARARGIN)

% Choose default command line output for FigureRecognition
handles.output = hObject;

global struct;

struct.modelPath = 'RandomForestModel.mat';
set(handles.uitable1, 'Data', {});
set(handles.uitable1, 'ColumnName', {'ID', 'Centroid', 'Random Forest', 'Tree', 'KNN', 'Neural Net', 'Color'});
%selectedIndex = get(hObject.popupmenu1, 'Value');
%methods = {'RandomForestModel.mat', 'treeModel.mat', 'knnModel.mat', 'NeuralNetworkModel.mat'};
%selectedMethod = methods{selectedIndex};
%struct.selectedAlgorithm = selectedMethod;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes FigureRecognition wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = FigureRecognition_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in btnStart.
function btnStart_Callback(hObject, eventdata, handles)
% hObject    handle to btnStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.btnAnalyse, 'Enable', 'off');
vid = videoinput('winvideo', 1, 'YUY2_640x480');
vid.ReturnedColorspace = 'rgb';
    
axes(handles.axes1);
hImage = image(zeros(480, 640, 3, 'uint8'));
preview(vid, hImage);
    
handles.vid = vid;
guidata(hObject, handles);

% --- Executes on button press in btnSnap.
function btnSnap_Callback(hObject, eventdata, handles)
% hObject    handle to btnSnap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    vid = handles.vid;

    % Snap
    frame = getsnapshot(vid);
    % Stop preview
    stoppreview(vid);
    % Show in axes1
    axes(handles.axes1);
    imshow(frame);
    % Save img
    global struct;
    struct.img = frame;

    
    stop(vid);
    delete(vid);
    clear handles.vid;

    guidata(hObject, handles);
    
    set(handles.btnAnalyse, 'Enable', 'on');



% --- Executes on button press in btnAnalyse.
function btnAnalyse_Callback(hObject, eventdata, handles)
% hObject    handle to btnAnalyse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global struct;
img = struct.img;

load('FeatureMatrix_v2.mat', 'featureMatrix2');

modelFile = struct.modelPath;
loadedData = load(modelFile);
modelNames = fieldnames(loadedData);
model = loadedData.(modelNames{1});

classNames = {'Square', 'Rectangle', 'Triangle', 'Bridge'};

if size(img, 3) == 3
    gray_img = rgb2gray(img);
else
    gray_img = img;
end

binary_img = imbinarize(gray_img, 'adaptive', 'Sensitivity', 0.65);
binary_img = imcomplement(binary_img);

se = strel('cube', 1); 
clean_img = imopen(binary_img, se);
clean_img = imfill(clean_img, 'holes');
clean_img = imclose(clean_img, se);

%oriented boundingbox
labeled_img = bwlabel(clean_img);
num_objects = max(labeled_img(:));
[obb_all, obb_labels] = imOrientedBox(labeled_img);

stats = regionprops(labeled_img, 'Eccentricity','BoundingBox','Solidity', 'Area', 'ConvexArea', 'Perimeter', 'Centroid');



axes(handles.axes2);
imshow(clean_img);
hold on;

for k = 1:length(stats)
        if stats(k).Area > 100
        
            obb_idx = find(obb_labels == k);
            current_obb = obb_all(obb_idx, :);

            area = stats(k).Area;
            perimeter = stats(k).Perimeter;

            solidity = stats(k).Solidity;
            eccentricity = stats(k).Eccentricity;
            convex_area = stats(k).ConvexArea;

       
            obb_width = current_obb(3);
            obb_height = current_obb(4);
            obb_aspect_ratio = obb_width / obb_height;
            obb_extent = area / (obb_width * obb_height);
            % Новые признаки
       
            features = [eccentricity, obb_aspect_ratio, solidity, obb_extent];
            features_normalized = (features - mean(featureMatrix2)) ./ std(featureMatrix2);
            fprintf('Object %d: eccentricity=%.4f, obb_aspect_ratio=%.4f, solidity=%.4f, obb_extent=%.4f\n', ...
                k, features(1), features(2), features(3), features(4));
            predictedClass = predict(model, features_normalized);


            if isnumeric(predictedClass)
                classText = classNames{predictedClass};
            end
    

            centroid = stats(k).Centroid;
            cx = round(centroid(1));
            cy = round(centroid(2));

            rectangle('Position', stats(k).BoundingBox,  'EdgeColor', 'g', 'LineWidth', 1);

            text_str = sprintf('%s\nIDy: %.0f', classText, k);
            
            text(centroid(1)+10, centroid(2), text_str, 'Color', 'white', 'FontSize', 8, 'BackgroundColor', 'black', 'HorizontalAlignment', 'left');
            
            plot(centroid(1), centroid(2), 'o',  'MarkerFaceColor', 'red');

        end
end



hold off;


currentData = get(handles.uitable1, 'Data');
load('RandomForestModel.mat', 'rfModel' );
load('treeModel.mat', 'treeModel');
load('knnModel.mat', 'knnModel');
load('NeuralNetworkModel.mat', 'net');

for k = 1:length(stats)
        if stats(k).Area > 100
            obb_idx = find(obb_labels == k);
            if isempty(obb_idx)
                continue; % если OBB не найден
            end
            current_obb = obb_all(obb_idx, :);

            area = stats(k).Area;
            perimeter = stats(k).Perimeter;

            solidity = stats(k).Solidity;
            eccentricity = stats(k).Eccentricity;
            convex_area = stats(k).ConvexArea;

       
            obb_width = current_obb(3);
            obb_height = current_obb(4);
            obb_aspect_ratio = obb_width / obb_height;
            obb_extent = area / (obb_width * obb_height);
           
       
            form_factor = area / convex_area;
            features = [eccentricity, obb_aspect_ratio, solidity, obb_extent];
            features_normalized = (features - mean(featureMatrix2)) ./ std(featureMatrix2);


        

            rfPredict = predict(rfModel, features_normalized);
            treePredict = predict(treeModel, features_normalized);
            knnPredict = predict(knnModel, features_normalized);
            netPredict = predict(net, features_normalized);

            currentData = get(handles.uitable1, 'Data');

            classText1 = classNames{rfPredict};
            classText2 = classNames{treePredict};
            classText3 = classNames{knnPredict};
            [~, netClassIdx] = max(netPredict);
            classText4 = classNames{netClassIdx};
    

            %cetting color
            box = round(stats(k).BoundingBox);
            x = max(box(1), 1);
            y = max(box(2), 1);
            w = box(3);
            h = box(4);
            x_end = min(x + w - 1, size(img, 2));
            y_end = min(y + h - 1, size(img, 1));

            roi = img(y:y_end, x:x_end, :);
            colorName = getColorName(roi); 

    
        % creat new data row
            newRow = {['ID ', num2str(k)], ['(', num2str(centroid(1)), ',', num2str(centroid(2)), ')'], ...
                classText1, classText2, classText3, classText4, colorName};
    
        % add it to table
            newData = [currentData; newRow];
            set(handles.uitable1, 'Data', newData);

        end
    end



% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
 % Получить индекс выбранного элемента
    selectedIndex = get(hObject, 'Value');
    fileNames = {'RandomForestModel.mat', 'treeModel.mat', 'knnModel.mat', 'NeuralNetworkModel.mat'};
    modelNames = {'rfModel', 'treeModel', 'knnModel', 'net'};

    global struct;
    struct.modelPath = fileNames{selectedIndex};
    struct.model = modelNames{selectedIndex};
    disp(['Model: ',  struct.modelPath]);



% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function uitable1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to uitable1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in btnSave.
function btnSave_Callback(hObject, eventdata, handles)
% hObject    handle to btnSave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
 data = get(handles.uitable1, 'Data');
    columnNames = get(handles.uitable1, 'ColumnName');

  choice = questdlg('Do you want to create a new file or to edit an existing one?',  'Save options', 'New file', 'Edit', 'Cancel', 'New file');
    
    if strcmp(choice, 'Cancel') || isempty(choice)
        return;
    end

    if strcmp(choice, 'New file')
        [file, path] = uiputfile('*.txt', 'Save as...');
    else
        [file, path] = uigetfile('*.txt', 'Chose file to add new data there');
    end

    if isequal(file, 0)
        return;
    end

    fullFileName = fullfile(path, file);
    fileExists = exist(fullFileName, 'file') == 2;

    fid = fopen(fullFileName, 'a');
    if fid == -1
        errordlg('Could not open file.', 'Error');
        return;
    end

    if ~fileExists || strcmp(choice, 'New file')
        headerLine = strjoin(columnNames, '\t');
        fprintf(fid, '%s\n', headerLine);
    end

    % writing data row after row
    for i = 1:size(data, 1)
        row = data(i, :);
        formattedRow = cellfun(@(x) num2str(x), row, 'UniformOutput', false);
        fprintf(fid, '%s\n', strjoin(formattedRow, '\t'));
    end

    fclose(fid);
    msgbox('Sucessfully saved.', 'Done');


% --- Executes on button press in btnClear.
function btnClear_Callback(hObject, eventdata, handles)
% hObject    handle to btnClear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.uitable1, 'Data', {});
set(handles.uitable1, 'ColumnName', {'ID', 'Centroid', 'Random Forest', 'Tree', 'KNN', 'Neural Net', 'Color'});


% --- Executes on button press in btnStats.
function btnStats_Callback(hObject, eventdata, handles)
% hObject    handle to btnStats (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
fig = figure('Name', 'Training Data: Confusion Matrices', ...
                'NumberTitle', 'off', ...
                'Position', [100 100 1200 800], ...
                'Color', [0.95 0.95 0.95]);
    
    load('FeatureMatrix_v2.mat', 'featureMatrix2');
    labels = [1 1 1 1 3 3 3 3 3 3 1 3 1 3 1 3 1 3 1 3 1 3 2 3 2 3 2 3 2 3 3 2 4 3 2 4 3 2 4 3 2 4 2 2 1 2 2 1 2 2 1 2 2 1 2 2 1 2 2 1 4 4 3 4 4 3 4 4 3 3 1 2 1 1 4 3 1 2 3 2 2 4 1 2 2 3 3 4 2 2 3 3 1 3 2 4]';
    classNames = {'1', '2', '3', '4'};
    featureMatrixNorm = zscore(featureMatrix2);
    
    labels_cat = categorical(labels, [1 2 3 4], classNames);
    

    load('RandomForestModel.mat', 'rfModel');
    load('treeModel.mat', 'treeModel');
    load('knnModel.mat', 'knnModel');
    load('NeuralNetworkModel.mat', 'net');
    
    % 1. Random Forest
    subplot(2,2,1);
    rfPred = predict(rfModel, featureMatrixNorm);
    rfPred_cat = categorical(rfPred, [1 2 3 4], classNames);
    cmRF = confusionchart(labels_cat, rfPred_cat, ...
        'RowSummary', 'row-normalized', ...
        'ColumnSummary', 'column-normalized', ...
        'Title', sprintf('Random Forest\nAccuracy: %.1f%%', 100*sum(rfPred==labels)/length(labels)));
    
    % 2. Decision Tree
    subplot(2,2,2);
    treePred = predict(treeModel, featureMatrixNorm);
    treePred_cat = categorical(treePred, [1 2 3 4], classNames);
    cmTree = confusionchart(labels_cat, treePred_cat, ...
        'RowSummary', 'row-normalized', ...
        'ColumnSummary', 'column-normalized', ...
        'Title', sprintf('Decision Tree\nAccuracy: %.1f%%', 100*sum(treePred==labels)/length(labels)));
    
    % 3. k-NN
    subplot(2,2,3);
    knnPred = predict(knnModel, featureMatrixNorm);
    knnPred_cat = categorical(knnPred, [1 2 3 4], classNames);
    cmKNN = confusionchart(labels_cat, knnPred_cat, ...
        'RowSummary', 'row-normalized', ...
        'ColumnSummary', 'column-normalized', ...
        'Title', sprintf('k-NN (k=%d)\nAccuracy: %.1f%%', knnModel.NumNeighbors, 100*sum(knnPred==labels)/length(labels)));
    

 
    % 4. Neural Network
subplot(2,2,4);

nnPred = classify(net, featureMatrixNorm);
nnPred_cat = categorical(cellstr(nnPred), classNames);
accuracy = 100 * mean(nnPred == categorical(labels));

confusionchart(labels_cat, nnPred_cat, ...
    'Title', sprintf('Neural Network\nAccuracy: %.1f%%', accuracy), ...
    'RowSummary', 'row-normalized', ...
    'ColumnSummary', 'column-normalized');

    sgtitle('Model Performance on Training Data', 'FontSize', 16, 'FontWeight', 'bold');
    
    annotation('textbox', [0.1 0.01 0.8 0.04], ...
        'String', 'Rows: True Class | Columns: Predicted Class', ...
        'EdgeColor', 'none', ...
        'HorizontalAlignment', 'center', ...
        'FontSize', 10)