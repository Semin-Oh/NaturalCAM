function [hAngle, vAngle] = PixelToDegCurved(xPixel, yPixel)
% pixelToVisualAngleCurved converts pixel coordinates to visual angles
% for a cylindrical curved display.
%
% Inputs:
%   xPixel - horizontal pixel coordinate (1 to 15360)
%   yPixel - vertical pixel coordinate (1 to 1457)
%
% Outputs:
%   hAngle - horizontal visual angle in degrees
%   vAngle - vertical visual angle in degrees

% History:
%    11/11/24    smo    - Wrote it.

%% Display specifications
totalWidthPixels = 15360;    % Total horizontal resolution
totalHeightPixels = 1457;    % Total vertical resolution
horizontalFOV = 180;         % Total horizontal FOV in degrees
screenHeightMeters = 0.335;  % Physical height of the screen in meters
observerDistance = 1;        % Distance from the screen to the observer in meters

%% Calculate the horizontal visual angle per pixel
hAnglePerPixel = horizontalFOV / totalWidthPixels; % degrees per pixel

% Calculate the total vertical field of view (for flat-plane approximation)
totalVerticalFOV = 2 * atand((screenHeightMeters / 2) / observerDistance); % degrees
vAnglePerPixel = totalVerticalFOV / totalHeightPixels; % degrees per vertical pixel

% Calculate the horizontal angle considering cylindrical curvature
% Convert the pixel position to a center-referenced coordinate system
relativeX = xPixel - (totalWidthPixels / 2);

% Calculate the corresponding horizontal visual angle
hAngle = relativeX * hAnglePerPixel; % This assumes a linear spread on a cylindrical display

% Calculate the vertical angle (using flat-plane approximation)
relativeY = yPixel - (totalHeightPixels / 2);
vAngle = relativeY * vAnglePerPixel;

% Display the results.
fprintf('Image center FOV (Horizontal, Vertical): (%.2f, %.2f) degrees\n', hAngle, vAngle);
end
