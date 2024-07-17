% RunCAMs.
%
% This script calculates the CIECAM stats, CIELAB and CAM16. It should be
% able to calculate the stats based on either

% History:
%    07/17/2024   smo   - Started on it.

%% Initialize.
clear; close all;

%% Set variables.
%
% Set the display type. If unknown, set it to 'sRGB'.
displayType = 'sRGB';
switch displayType
    case 'sRGB'
        % We'll draw the color gamut of the display later on. 
        xyY_targetDisplay = [0.6400 0.3000 0.1500; 0.3300 0.6000 0.0600; 0.2126 0.7152 0.0722];
        
        % 3x3 matrix to convert from the linear RGB to CIE XYZ.
        M_RGB2XYZ = [0.4124 0.3576 0.1805; 0.2126 0.7152 0.0722; 0.0193 0.1192 0.9505];

        % Display gamma. We can set it differently according to the
        % channels. Here, we set it as 2.2 for all channels.
        gamma = 2.2;
        gamma_R = gamma;
        gamma_G = gamma;
        gamma_B = gamma;
    otherwise
end

% Set it based on the 8-bit display (0-255). We may not need to change it
% this part for the calculations.
nInputLevels = 255;

% etc.
verbose = true;

%% Load the test image.
%
% Here, we are using the test image as it is, when we do it for Coco
% dataset, we believe the object would have been segmented. 
image = imread('orange.png');

% Display the image if you want.
if (verbose)
    figure; 
    imshow(image);
end

%% Convert digital RGB to CIE XYZ.
%
% Convert digital RGB to linear RGB.
%
% For correct calculations, make sure the class of the RGB matrix is
% 'double' so that it can be multiplied by the conversion matrix.
dRGB_Norm = double(image)./nInputLevels;
LRGB_R = dRGB_Norm(:,:,1).^gamma_R;
LRGB_G = dRGB_Norm(:,:,2).^gamma_G;
LRGB_B = dRGB_Norm(:,:,3).^gamma_B;

% Resize the matrix so that we can compute the CIE XYZ values. It should
% look like 3 x n.
LRGB(1,:) = LRGB_R(:);
LRGB(2,:) = LRGB_G(:);
LRGB(3,:) = LRGB_B(:);

% Linear RGB to CIE XYZ.
XYZ_testImage = M_RGB2XYZ * LRGB;
xyY_testImage = XYZToxyY(XYZ_testImage);

%% CIE XYZ to CIELAB.


%% Plot the results.
figure; hold on;
plot(xyY_testImage(1,:),xyY_testImage(2,:),'r+');

% Display gamut. For now, it's set to sRGB for convenience.
plot([xyY_targetDisplay(1,:) xyY_targetDisplay(1,1)], [xyY_targetDisplay(2,:) xyY_targetDisplay(2,1)],'k-','LineWidth',1);

% Plackian locus.
load T_xyzJuddVos
T_XYZ = T_xyzJuddVos;
T_xy = [T_XYZ(1,:)./sum(T_XYZ); T_XYZ(2,:)./sum(T_XYZ)];
plot([T_xy(1,:) T_xy(1,1)], [T_xy(2,:) T_xy(2,1)], 'k-');

% Figure stuffs.
xlim([0 1]);
ylim([0 1]);
xlabel('CIE x','fontsize',13);
ylabel('CIE y','fontsize',13);
legend('test','Location','southeast','fontsize',11);
title('Test color on the CIE xy coordinates');
