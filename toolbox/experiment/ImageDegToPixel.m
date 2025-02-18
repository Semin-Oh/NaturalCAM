function [xStart, yStart, widthPixels, heightPixels] = ImageDegToPixel(hCenterAngle, vCenterAngle, hFOV, vFOV)
% This routine converts visual angles to pixel coordinates for an image on a curved display.
%
% Syntax:
%    [xStart, yStart, widthPixels, heightPixels] = ImageDegToPixel(hCenterAngle, vCenterAngle, hFOV, vFOV)
%
% Description:
%    This is the inverse function of ImagePixelToDeg.m.
%
% Inputs:
%   hCenterAngle        - Horizontal center angle of the image in degrees
%   vCenterAngle        - Vertical center angle of the image in degrees
%   hFOV                - Horizontal Field of View of the image in degrees
%   vFOV                - Vertical Field of View of the image in degrees
%
% Outputs:
%   xStart              - Starting horizontal pixel position of the image (1 to 15360)
%   yStart              - Starting vertical pixel position of the image (1 to 1457)
%   widthPixels         - Width of the image in pixels
%   heightPixels        - Height of the image in pixels

% See also:
%    PixelToDeg, ImagePixelToDeg.

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

% Calculate the width of the image in pixels from its horizontal FOV
widthPixels = round(hFOV / hAnglePerPixel);

% Calculate the height of the image in pixels from its vertical FOV
heightPixels = round(vFOV / vAnglePerPixel);

% Calculate the center pixel coordinates
centerX = round((hCenterAngle / hAnglePerPixel) + (totalWidthPixels / 2));
centerY = round((vCenterAngle / vAnglePerPixel) + (totalHeightPixels / 2));

% Calculate the top-left corner pixel coordinates
xStart = centerX - round(widthPixels / 2);
yStart = centerY - round(heightPixels / 2);

% Ensure the pixel coordinates are within the screen bounds
xStart = max(1, min(xStart, totalWidthPixels - widthPixels + 1));
yStart = max(1, min(yStart, totalHeightPixels - heightPixels + 1));
end
