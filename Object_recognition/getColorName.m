function colorName = getColorName(rgbRegion)
    % getting mean color to the region
    meanColor = mean(reshape(double(rgbRegion), [], 3), 1) / 255;

    % Transforming to HSV
    hsvColor = rgb2hsv(meanColor);

    h = hsvColor(1); s = hsvColor(2); v = hsvColor(3);

    if v < 0.2
        colorName = 'Black';
    elseif s < 0.2 && v > 0.8
        colorName = 'White';
    elseif s < 0.3
        colorName = 'Gray';
    elseif h < 0.05 || h > 0.95
        colorName = 'Red';
    elseif h < 0.1
        colorName = 'Orange';
    elseif h < 0.18
        colorName = 'Yellow';
    elseif h < 0.4
        colorName = 'Green';
    elseif h < 0.6
        colorName = 'Cyan';
    elseif h < 0.8
        colorName = 'Blue';
    else
        colorName = 'Magenta';
    end
end

% Process each connected component
for k = 1:CC.NumObjects
   % Get properties of current component
   s = stats(k);
   bbox = s.BoundingBox;
   aspectRatio = bbox(4)/bbox(3);  % Height/width ratio
   feat = [s.EulerNumber, s.Eccentricity, aspectRatio, s.Solidity, s.Extent];
   
   % Normalize features using training parameters
   featuresNorm = (feat - mu) ./ sigma;
   
   % Predict character class using kNN model
   classIdx = predict(knnModel, featuresNorm);
   recognizedChar = classNames{classIdx};
   
   % Add to results array
   recognizedChars = [recognizedChars, string(recognizedChar)];
end

% Display results in the application's text area
recognizedText = strjoin(recognizedChars, ' ');
app.textTextArea.Value = recognizedText; % Removes trailing space