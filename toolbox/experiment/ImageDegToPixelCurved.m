function [xStart, yStart, widthPixels, heightPixels] = ImageDegToPixelCurved(hCenterAngle, vCenterAngle, hFOV, vFOV)
% visualAngleToPixelCurved converts visual angles to pixel coordinates
% for an image on a curved display (assumed cylindrical curvature).
%
% Inputs:
%   hCenterAngle - Horizontal center angle of the image in degrees
%   vCenterAngle - Vertical center angle of the image in degrees
%   hFOV         - Horizontal Field of View of the image in degrees
%   vFOV         - Vertical Field of View of the image in degrees
%
% Outputs:
%   xStart       - Starting horizontal pixel position of the image (1 to 15360)
%   yStart       - Starting vertical pixel position of the image (1 to 1457)
%   widthPixels  - Width of the image in pixels
%   heightPixels - Height of the image in pixels

% History:
%    11/11/24    smo    - Wrote it.

%% Display specifications
totalWidthPixels = 15360;    % Total horizontal resolution
totalHeightPixels = 1457;    % Total vertical resolution
horizontalFOV = 180;         % Total horizontal FOV in degrees
screenHeightMeters = 0.335;  % Physical height of the screen in meters
observerDistance = 1;        % Distance from the screen to the observer in meters

%% Calculate the horizontal visual angle per pixel using the arc formula
hAnglePerPixel = horizontalFOV / totalWidthPixels; % degrees per pixel

% Adjust horizontal angle using the arc length of the cylindrical display
arcLength = observerDistance * tand(horizontalFOV / 2) * 2; % total width in meters
pixelWidthMeters = arcLength / totalWidthPixels; % meters per horizontal pixel

% Calculate the total vertical field of view (still using flat plane approximation)
totalVerticalFOV = 2 * atand((screenHeightMeters / 2) / observerDistance); % degrees
vAnglePerPixel = totalVerticalFOV / totalHeightPixels; % degrees per vertical pixel

% Calculate width and height in pixels
widthPixels = round((hFOV / horizontalFOV) * totalWidthPixels);
heightPixels = round((vFOV / totalVerticalFOV) * totalHeightPixels);

% Calculate center pixel coordinates based on angular positions
centerX = round((hCenterAngle / hAnglePerPixel) + (totalWidthPixels / 2));
centerY = round((vCenterAngle / vAnglePerPixel) + (totalHeightPixels / 2));

% Convert center to top-left
xStart = centerX - round(widthPixels / 2);
yStart = centerY - round(heightPixels / 2);

% Ensure pixel bounds
xStart = max(1, min(xStart, totalWidthPixels - widthPixels + 1));
yStart = max(1, min(yStart, totalHeightPixels - heightPixels + 1));
end
