function dcd = computeDCD(img, k)
% Compute a MPEG-7–style Dominant Color Descriptor (DCD)
% img: input RGB image (HxWx3)
% k: number of dominant colors (clusters)

% Convert image to Lab for perceptual clustering
img = im2double(img);
labImg = rgb2lab(img);
[h, w, ~] = size(img);
pixels = reshape(labImg, [], 3);  % N x 3

% K-means clustering
[idx, centers] = kmeans(pixels, k, 'Replicates', 5);

% Initialize descriptor struct
dcd = struct('Color', [], 'Percentage', [], 'Variance', [], 'SpatialCoherence', []);

for i = 1:k
    clusterPixels = pixels(idx == i, :);
    
    % Dominant color (Lab center)
    dcd(i).Color = centers(i, :);
    
    % Percentage of pixels in this cluster
    dcd(i).Percentage = size(clusterPixels, 1) / size(pixels, 1);
    
    % Variance around cluster center (per channel)
    dcd(i).Variance = var(clusterPixels, 0, 1);  % 1 x 3 vector
    
    % Spatial Coherence (simplified): fraction of pixels forming largest connected blob
    mask = reshape(idx == i, h, w);
    connComp = bwconncomp(mask);
    if connComp.NumObjects > 0
        largestBlobSize = max(cellfun(@numel, connComp.PixelIdxList));
        dcd(i).SpatialCoherence = largestBlobSize / sum(mask(:));
    else
        dcd(i).SpatialCoherence = 0;
    end
end
end