%eccentricity 
%Form Factor
%solidity 
%Aspect Ratio (OBB)
%Extent (OBB)

%это сделано
img = imread('C:\Users\dobre\Documents\MATLAB\final_practice\img\new\4.png');
top_crop = 0;
bottom_crop = 0;
left_crop = 0;
right_crop = 0;


img =  img(top_crop+1:end-bottom_crop, left_crop+1:end-right_crop, :);
if size(img, 3) == 3
    gray_img = rgb2gray(img);
else
    gray_img = img;
end
binary_img = imbinarize(gray_img, 'adaptive', 'Sensitivity', 0.616);
binary_img = imcomplement(binary_img);



% Morfological operations to better divide elements
se = strel('cube', 6); 
clean_img = imopen(binary_img, se);
clean_img = imfill(clean_img, 'holes');
clean_img = imclose(clean_img, se);

%% Boundaries for regionprops
% Finding boundaries
boundaries = bwperim(clean_img);

% Making thick bounderies
thick_boundaries = imdilate(boundaries, strel('cube', 4));

%Showing bounds
boundary_img = imoverlay(img, thick_boundaries, [1 0 0]);

%oriented boundingbox
labeled_img = bwlabel(clean_img);
num_objects = max(labeled_img(:));
[obb_all, obb_labels] = imOrientedBox(labeled_img);

stats = regionprops(labeled_img, 'Eccentricity','BoundingBox','Solidity', 'Area', 'ConvexArea', 'Perimeter', 'Centroid');

figure;
subplot(1,2,1), imshow(boundary_img), title('Borders');
subplot(1,2,2), imshow(clean_img), title('Filled figures');
hold on;
for k = 1:length(stats)
    if stats(k).Area > 100
    rectangle('Position', stats(k).BoundingBox, ...
              'EdgeColor', 'g', 'LineWidth', 1);
    text(stats(k).Centroid(1), stats(k).Centroid(2), ...
         num2str(k), 'Color', 'r', 'FontSize', 14);
    end
end
hold off;

if exist('FeatureMatrix_v2.mat', 'file')
    load('FeatureMatrix_v2.mat', 'featureMatrix2');
else
    featureMatrix2 = [];
end

for k = 1:length(stats)
    if stats(k).Area > 300


       obb_idx = find(obb_labels == k);
       if isempty(obb_idx)
          continue;
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
       
       features = [eccentricity, obb_aspect_ratio, solidity, obb_extent];

     
        featureMatrix2(end+1, :) = features;
        % Вывод для проверки
        fprintf('Object %d: eccentricity=%.4f, obb_aspect_ratio=%.4f, solidity=%.4f, obb_extent=%.4f\n', ...
                k, features(1), features(2), features(3), features(4));
    end
end

% Сохранение в файл
%save('FeatureMatrix_v2.mat', 'featureMatrix2');