function dcd = GetImageDominantColor(image, options)
% Compute a MPEG-7–style Dominant Color Descriptor (DCD) to pick a dominant
% color (pixel) within an image.
%
% Syntax:
%    dcd = GetImageDominantColor(image)
%
% Description:
%    Idea is based on the MPEG-7 Dominant Color Descriptor (DCD). Paper
%    reference is as follows:
%
%    Manjunath, B. S., Ohm, J. R., Vasudevan, V. V., & Yamada, A. (2001).
%    Color and texture descriptors. IEEE Transactions on circuits and
%    systems for video technology, 11(6), 703-715.
%
%    The DCD is also fully defined in the following document: ISO/IEC
%    15938-3:2002 — Multimedia Content Description Interface – Part 3:
%    Visual.
%
% Input:
%    img                     - Input RGB image in image format (HxWx3).
%    k                       - Number of dominant colors (clusters).
%
% Output:
%    dcd
%
% Optional key/value pairs:
%    k                       - Number of clusters to find using k-means.
%                              Default to 3.
%    verbose                 - Controls message output and plots. Default
%                              to false.
%
% See also:
%

% History:
%    04/10/25   smo          - Wrote it.

%% Set variables.
arguments
    image
    options.displayType = 'EIZO'
    options.nClusters (1,1) = 3
    options.nReplicates (1,1) = 5
    options.clusterSpace = 'ab'
    options.verbose = false
end

%% Get display charactieristics.
switch options.displayType
    case 'EIZO'
        % 3x3 matrix.
        M_RGBToXYZ =  [62.1997 22.8684 19.2310;...
            28.5133 78.5446 6.9256;...
            0.0739 6.3714 99.5962];

        % Monitor gamma. (R=2.2267, G=2.2271, B=2.1652, Gray=2.1904). We
        % will use the gray channel gamma for further calculations for now.
        gamma_display = 2.1904;

        % White point.
        XYZw = sum(M_RGBToXYZ,2);
end

%% First, segment the image. We are using CoCo segmentation date here.
%
% Each segmenation file is saved in .csv file. The file contains a total of
% 7 columns, each being 'image_id', 'object_name', 'x', 'y', 'r', 'g', 'b'.
%
% We may want to check if the (x, y) coordinates match with an object.
% Further, we will cluster the dominant colored pixels using the rgb info.
% It might not be the most elaborate way to read .csv file, but it's good
% for now.
fid = fopen(fullfile('/Users/semin/Dropbox (Personal)/JLU/2) Projects/NaturalCAM/images/segmentation/segmentation_labeled','apple2.csv'),"r");
segmentData = textscan(fid, '%f %s %f %f %f %f %f', 'Delimiter', ',', 'HeaderLines', 1);
fclose(fid);

% Get the pixel location and corresponding RGB values of the segmented
% object.
pixel_SegmentedObject = [segmentData{3} segmentData{4}];
dRGB_segmentedObject = [segmentData{5} segmentData{6} segmentData{7}];

%% Convert segmentation to CIELAB values.
%
% Get the image size.
[h, w, ~] = size(image);

% Calculate CIELAB values of the segmented area.
% labImage = rgb2lab(im2double(image));
XYZ_segmentedObject = RGBToXYZ(dRGB_segmentedObject',M_RGBToXYZ,gamma_display);
lab_segmentedObject = XYZToLab(XYZ_segmentedObject,XYZw);

% Decide which space to cluster the pixels. We can do either on CIELAB a*b*
% (good for hue only) or L*a*b* space.
switch options.clusterSpace
    case 'ab'
        L = lab_segmentedObject(1,:);
        a = lab_segmentedObject(2,:);
        b = lab_segmentedObject(3,:);
        pixels = reshape(cat(3, a, b), [], 2);
    case 'lab'
        pixels = reshape(lab_segmentedObject, [], 3);
end

%% Cluster pixels on CIELAB using K-means.
%
% K-means clustering.
[idxCluster, centers] = kmeans(pixels, options.nClusters, 'Replicates', options.nReplicates);

% Initialize descriptor struct.
dcd = struct('Lab', [], 'Percentage', [], 'Variance', []);
% dcd = struct('ab', [], 'Percentage', [], 'Variance', [], 'SpatialCoherence', []);

for i = 1:options.nClusters
    clusterPixels = pixels(idxCluster == i, :);

    % Dominant color (Lab center).
    dcd(i).Lab = centers(i, :);

    % Percentage of pixels in this cluster.
    dcd(i).Percentage = size(clusterPixels, 1) / size(pixels, 1);

    % Variance around cluster center (per channel).
    dcd(i).Variance = var(clusterPixels, 0, 1);

    % DISABLED FOR NOW AS WE ARE WORKING ON PIXEL-BASED, NOT IMAGE.
    %
    % Spatial Coherence. Fraction of pixels forming largest
    % connected blob. In MPEG-7, this helps distinguish dominant objects
    % vs. distributed background colors.
    %
    % Values near 1 means that pixels are grouped together in the image
    % (e.g. a red car), while if the values are close to 0, pixels are
    % scattered all over (e.g. random red noise).
    %
    % mask = reshape(idxCluster == i, h, w);
    % connComp = bwconncomp(mask);
    % if connComp.NumObjects > 0
    %     largestBlobSize = max(cellfun(@numel, connComp.PixelIdxList));
    %     dcd(i).SpatialCoherence = largestBlobSize / sum(mask(:));
    % else
    %     dcd(i).SpatialCoherence = 0;
    % end
end

% Get L*a*b* and digital RGB values of the center of dominant cluster.
idxDominantCluster = mode(idxCluster);
dominantLab = dcd(idxDominantCluster).Lab;
% dominantRGB = round(lab2rgb(dominantLab)*255);

%% Plot the results if you want.
if (options.verbose)

    % Extract image pixel information of the dominant cluster.
    idxDominantPixels = find(idxCluster==idxDominantCluster);
    pixelPositionDominantCluster = pixel_SegmentedObject(idxDominantPixels,:);

    %% Calculate L* value for the center of the dominant cluster.
    %
    % As we find the clusters on the CIELAB a*b* plane, each center of the
    % cluster does not have the L* information. Here, we simply calculate
    % the mean of all pixels in the cluster

    %% Plot some results
    %
    % Original image.
    figure;
    subplot(2,2,1);
    imshow(image); hold on;
    title('Original image');

    % Segmentation on the image.
    subplot(2,2,2);
    imshow(image); hold on;
    s = scatter(pixel_SegmentedObject(:,1),pixel_SegmentedObject(:,2),'b.');
    title('With segmentation');
    legend('Segmentation','Location','southeast');

    % Dominant cluster on the image.
    subplot(2,2,3);
    imshow(image); hold on;
    plot(pixelPositionDominantCluster(:,1),pixelPositionDominantCluster(:,2),'r.');
    title('With dominant cluster');
    legend('Dominant','Location','southeast');

    % Distributions of the clusters on the CIELAB a*b* plane.
    figure; hold on;
    idx_cluster_a = find(idxCluster==1);
    idx_cluster_b = find(idxCluster==2);
    idx_cluster_c = find(idxCluster==3);

    % Distributions of all clusters.
    plot(pixels(idx_cluster_a,1), pixels(idx_cluster_a,2),'r.');
    plot(pixels(idx_cluster_b,1), pixels(idx_cluster_b,2),'g.');
    plot(pixels(idx_cluster_c,1), pixels(idx_cluster_c,2),'b.');

    % Center of dominant cluster.
    plot(dominantLab(1),dominantLab(2),'o','MarkerFaceColor','k');

    % Figure stuff.
    xlabel('CIELAB a*');
    ylabel('CIELAB b*');
    axis square;
    grid on;
    title(sprintf('Clusters on a*b* plane (N=%d)',options.nClusters));
    legend(sprintf('Cluster a (%.2f)',dcd(1).Percentage),...
        sprintf('Cluster b (%.2f)',dcd(2).Percentage),...
        sprintf('Cluster c (%.2f)',dcd(3).Percentage),...
        'Estimated dominant color','Location','northeast');
end
end
