% Image2CIECAM02.
%
% This routine calculates the CIECAM02 stats from an image.

% History:
%    08/02/24    smo    - Wrote it.

%% Initialize.
clear all; close all;

%% Set variables.
%
% Set the display type. If unknown, set it to 'sRGB'.
displayType = 'sRGB';
switch displayType
    case 'sRGB'
        % 3x3 matrix to convert from the linear RGB to CIE XYZ.
        M_RGB2XYZ = [0.4124 0.3576 0.1805; 0.2126 0.7152 0.0722; 0.0193 0.1192 0.9505];

        % White point.
        XYZ_white = sum(M_RGB2XYZ,2);
        
        % Scaling the 3x3 matrix and the white point to have the relative
        % luminance value (Yw) as 100.
        M_RGB2XYZ = M_RGB2XYZ * 100;
        XYZ_white = (XYZ_white./XYZ_white(2)) * 100;

        % Display gamma. We can set it differently according to the
        % channels. Here, we set it as 2.2 for all channels.
        gamma = 2.2;
        
        % Define the adapting luminance (cd/m2). Each image should have
        % different luminance of the scene. Here we set the fixed luminance
        % as 50 (cd/m2) for every image. We should update this part to
        % reflect the actual viewing situations within the image later on.
        LA = 50;
    otherwise
end

% Set it 'true' if you wanna plot the results.
verbose = true;

%% Define the target point.
%
% We will calculate the CIECAM02 stats by using the digital RGB values of
% one pixel, so here we define one pixel values (array should look like
% 3x1).
dRGB_target = [100;100;255];

%% Calculate the CIECAM02 stats.
%
% First, calculate the XYZ values of the target.
XYZ_target = RGBToXYZ(dRGB_target,M_RGB2XYZ,gamma);

% Then, calculate the CIECAM02 stats. The output 'JCH_target' contains
% three numbers, lightness (J), chroma (C), and hue angle (h).
JCH_target = XYZToJCH(XYZ_target,XYZ_white,LA);
