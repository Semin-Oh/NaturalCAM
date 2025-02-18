function [hFOV, vFOV] = ImagePixelToDeg(xStart, yStart, width, height)
% This routine calculates the horizontal and vertical FOV of an image
% placed on a curved display.
%
% Syntax:
%    [hFOV, vFOV] = ImagePixelToDeg(xStart, yStart, width, height)
%
% Description:
%    Converts the pixel info to FOV in degrees for the curved display
%    system. This version can be directly used for the image.
%
% Inputs:
%    xStart             - starting horizontal pixel position of the image (1 to 15360)
%    yStart             - starting vertical pixel position of the image (1 to 1457)
%    width              - width of the image in pixels
%    height             - height of the image in pixels
%
% Outputs:
%    hFOV               - horizontal Field of View covered by the image in degrees
%    vFOV               - vertical Field of View covered by the image in degrees
%
% See also:
%    PixelToDeg.

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

% Calculate the total vertical field of view
totalVerticalFOV = 2 * atand((screenHeightMeters / 2) / observerDistance); % degrees
vAnglePerPixel = totalVerticalFOV / totalHeightPixels; % degrees per pixel

% Calculate the horizontal FOV covered by the image
hFOV = width * hAnglePerPixel;

% Calculate the vertical FOV covered by the image
vFOV = height * vAnglePerPixel;

% Display the center position of the image in terms of FOV
centerX = xStart + width / 2;
centerY = yStart + height / 2;
hCenterAngle = (centerX - totalWidthPixels / 2) * hAnglePerPixel;
vCenterAngle = (centerY - totalHeightPixels / 2) * vAnglePerPixel;

fprintf('Image center FOV (Horizontal, Vertical): (%.2f, %.2f) degrees\n', hCenterAngle, vCenterAngle);
end
