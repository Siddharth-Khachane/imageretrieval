function simal(numOfReturnedImages, queryImageFeatureVector, dataset, folder_name, img_ext)
query_image_name = queryImageFeatureVector(:, end);
dataset_image_names = dataset(:, end);

queryImageFeatureVector(:, end) = [];
dataset(:, end) = [];
dist = zeros(size(dataset, 1), 1);
for k=1:size(dataset,1)
    
    a=0;
    b=0;
    for i=1:10
        a=a+min(dataset(k,i),queryImageFeatureVector(i));
        b=b+max(dataset(k,i),queryImageFeatureVector(i));
    end
    dist(k)=a/b;
end

dist=[dist dataset_image_names];
[sortedDist indx] = sortrows(dist,'descend');
sortedImgs = sortedDist(:, 2);
arrayfun(@cla, findall(0, 'type', 'axes'));

% display query image
str_name = int2str(query_image_name);
queryImage = imread( strcat(folder_name, '\', str_name, img_ext) );
subplot(3, 7, 1);
imshow(queryImage, []);
title('Query Image', 'Color', [1 0 0]);

% dispaly images returned by query
for m = 1:numOfReturnedImages
    img_name = sortedImgs(m);
    img_name = int2str(img_name);
    str_name = strcat(folder_name, '\', img_name, img_ext);
    returnedImage = imread(str_name);
    subplot(3, 7, m+1);
    imshow(returnedImage, []);
end
