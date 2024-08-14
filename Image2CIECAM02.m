% Image2CIECAM02.
%
% This routine calculates the CIECAM02 stats from an image.

% History:
%    08/02/24    smo    - Wrote it.
%    08/14/24    smo    - Searching white point based on 'White-patch
%                         method' is working.

%% Initialize.
clear all; close all;

%% Read a test image and target digital RGB values.
% 
% Read out an image. We will set the white point and adapting luminance
% (cd/m2) based on each image for CIECAM02 calculations.
image = imread('football.jpg');

% Define a target point of one pixel pixel (array should look like 3x1).
%
% As we already extracted a representing color in one pixel of each object
% for all images, so here we're gonna use that information according to the
% object within the image.
dRGB_target = [100; 100; 255];

%% Set variables.
%
% Set the display type. If unknown, set it to 'sRGB'.
displayType = 'sRGB';
switch displayType
    case 'sRGB'
        % 3x3 matrix to convert from the linear RGB to CIE XYZ.
        M_RGB2XYZ = [0.4124 0.3576 0.1805; 0.2126 0.7152 0.0722; 0.0193 0.1192 0.9505];

        % Scaling the 3x3 matrix and the white point to have the relative
        % luminance value (Y) as 100.
        M_RGB2XYZ = M_RGB2XYZ * 100;

        % Display gamma. We can set it differently according to the
        % channels. Here, we set it as 2.2 for all channels.
        gamma = 2.2;

    otherwise
        % We can add different display settings later on if we want.
end

% Set it 'true' if you wanna plot the results.
verbose = true;

%% Define the white point within the scene.
%
% Here, we searches a white point within the scene. We will use a simple
% method, so-called 'White patch method'. It basically searches the
% brightest pixel (R+G+B) within the scene and treat it as a white point.
%
% Reference: H. R. V., Drew, M. S., Finlayson, G. D., & Rey, P. A. T.
% (2012, January). The role of bright pixels in illumination estimation. In
% Color and Imaging Conference (Vol. 2012, No. 1, pp. 41-46). Society for
% Imaging Science and Technology.
SETWHITEPOINT = 'whitepatch';
switch SETWHITEPOINT
    case 'whitepatch'
        % First, cut off the extreme pixels. We will remove pixels which exceed
        % 90% of the dynamic range.
        %
        % Rearrange the image in 2-D for calculation.
        [row column nChannels] = size(image);
        dRGB_image = reshape(image,[nChannels row*column]);

        % Set the boundary to cut off the pixels. Here we will cut off the
        % pixel exceeds the 90% of the dynamic range.
        maxRGB = 255;
        percentCutoff = 0.9;
        dRGB_cutoff = uint8(maxRGB * percentCutoff);

        % Find the index of the array where the pixel exceeds the criteria.
        idxCutoff_R = find(dRGB_image(1,:)>dRGB_cutoff);
        idxCutoff_G = find(dRGB_image(2,:)>dRGB_cutoff);
        idxCutoff_B = find(dRGB_image(3,:)>dRGB_cutoff);
        idxCutoff = unique([idxCutoff_R idxCutoff_G idxCutoff_B]);

        % Cutting off happens here.
        dRGB_image_cutoff = dRGB_image;
        dRGB_image_cutoff(:,idxCutoff) = [];

        % Get the cut off dummy pixels here. We may want to see what pixels
        % were cut off.
        dRGB_image_cutoff_dummy = dRGB_image;
        dRGB_image_cutoff_dummy = dRGB_image_cutoff_dummy(:,idxCutoff);

        % Now we will take the bright pixels within the pixels after
        % cutting off.
        %
        % We can use different statistical estimator, but use 5% for mean,
        % and 3% for median. These numbers are based on the referred paper.
        %
        % Here, we use the mean with 5% brightnest pixels, which makes the
        % lowest mean angular errors.
        sumRGB_image = sum(dRGB_image_cutoff);
        [sumRGB_image_sorted I] = sort(sumRGB_image,'descend');

        % Sort the dRGB in the same order.
        dRGB_image_cutoff_sorted = dRGB_image_cutoff(:,I);

        % Get the mean of the bright pixels.
        percentBrightest = 0.05;
        nPixels = length(sumRGB_image_sorted);
        idxPecentBrightest = ceil(percentBrightest*nPixels);
        dRGB_image_bright = dRGB_image_cutoff_sorted(:,1:idxPecentBrightest);
        mean_dRGB_image_bright = mean(dRGB_image_bright,2);

        % Calculate the rg coordinates.
        rg_image = RGBTorg(dRGB_image);
        rg_image_cutoff = RGBTorg(dRGB_image_cutoff);
        rg_image_cutoff_dummy = RGBTorg(dRGB_image_cutoff_dummy);
        rg_image_bright = RGBTorg(dRGB_image_bright);
        rg_image_white = RGBTorg(mean_dRGB_image_bright);
        rg_white_d65 = RGBTorg([255;255;255]);

        % Plot it how we did.
        if (verbose)
            figure; hold on;

            % Image.
            subplot(1,2,1);
            imshow(image);
            title('Test image');

            % Image profile.
            subplot(1,2,2); hold on;
            plot(rg_image(1,:),rg_image(2,:),'k.');
            plot(rg_image_cutoff_dummy(1,:),rg_image_cutoff_dummy(2,:),'y.');
            plot(rg_image_bright(1,:),rg_image_bright(2,:),'g.');
            plot(rg_image_white(1),rg_image_white(2),'ro', ...
                'markersize',5,'markerfacecolor','r','markeredgecolor','k');
            plot(rg_white_d65(1),rg_white_d65(2),'bo',...
                'markersize',3,'markerfacecolor','b','markeredgecolor','k');
            xlabel('r','FontSize',14);
            ylabel('g','FontSize',14);
            xlim([0 1]);
            ylim([0 1]);
            title('Image profile on the rg-coordinates');
            legend('original','cut-off','bright','white point','d65',...
                'FontSize',14);
        end

        % Calculate the XYZ values of the white point. We will use this as
        % a white point for CIECAM02 calculations.
        XYZ_white = RGBToXYZ(mean_dRGB_image_bright,M_RGB2XYZ,gamma);

    otherwise
        % Otherwise, set it to standard d65.
        XYZ_white = sum(M_RGB2XYZ,2);
end

%% Define the adapting luminance (cd/m2).
%
% Each image should have different luminance of the scene. Here we set the
% fixed luminance as 50 (cd/m2) for every image. We should update this part
% to reflect the actual viewing situations within the image later on.
switch SETWHITEPOINT
    case 'whitepatch'
        % We set the luminance of the adapting field based on the white
        % point that we searched from the above setting the white point.
        LA = XYZ_white(2);
    otherwise
        % You can fix the value if you want. Not sure if if is a good idea
        % to train the model with COCO image set.
        LA = 50;
end

%% Calculate the CIECAM02 stats.
%
% First, calculate the XYZ values of the target.
XYZ_target = RGBToXYZ(dRGB_target,M_RGB2XYZ,gamma);

% Scale it to have the luminance value (Yw) as 100.
XYZ_white = (XYZ_white./XYZ_white(2)) * 100;

% Then, calculate the CIECAM02 stats. The output 'JCH_target' contains
% three numbers, lightness (J), chroma (C), and hue angle (h).
JCH_target = XYZToJCH(XYZ_target,XYZ_white,LA);
