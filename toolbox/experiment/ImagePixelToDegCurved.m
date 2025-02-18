function [hAngle, vAngle] = ImagePixelToDegCurved(xStart, yStart, widthPixels, heightPixels)
% This routine calculates the visual angle of an image on a
% cylindrical curved display. The function returns the total horizontal
% and vertical visual angle spans for the image.
%
% Inputs:
%   xStart - starting horizontal pixel position of the image
%   yStart - starting vertical pixel position of the image
%   widthPixels  - width of the image in pixels
%   heightPixels - height of the image in pixels
%
% Outputs:
%   hAngle - horizontal visual angle range for the image (in degrees)
%   vAngle - vertical visual angle range for the image (in degrees)

%% Display specifications
totalWidthPixels = 15360;    % Total horizontal resolution
totalHeightPixels = 1457;    % Total vertical resolution
horizontalFOV = 180;         % Total horizontal FOV of the curved display (in degrees)
screenHeightMeters = 0.335;  % Physical height of the screen (in meters)
observerDistance = 1;        % Distance from the screen to the observer (in meters)

%% Calculate the horizontal angle per pixel
hAnglePerPixel = horizontalFOV / totalWidthPixels; % degrees per pixel

% Calculate the total vertical field of view (flat-plane approximation)
totalVerticalFOV = 2 * atand((screenHeightMeters / 2) / observerDistance); % vertical FOV in degrees
vAnglePerPixel = totalVerticalFOV / totalHeightPixels; % degrees per pixel for vertical direction

% Adjust for cylindrical curvature (horizontal visual angle)
%
% We will use the same approach as before to calculate the horizontal angle range.
% For the left and right edges of the image:

% Starting point (left edge of the image)
relativeStartX = xStart - (totalWidthPixels / 2);

% Ending point (right edge of the image)
relativeEndX = (xStart + widthPixels) - (totalWidthPixels / 2);

% Calculate the horizontal angle span (taking curvature into account)
hAngle = (relativeEndX - relativeStartX) * hAnglePerPixel;

% Vertical angle remains linear (flat-plane approximation)
% Calculate the vertical angle range:
relativeStartY = yStart - (totalHeightPixels / 2);
relativeEndY = (yStart + heightPixels) - (totalHeightPixels / 2);
vAngle = (relativeEndY - relativeStartY) * vAnglePerPixel;

% Display the results.
fprintf('Image center FOV (Horizontal, Vertical): (%.2f, %.2f) degrees\n', hAngle, vAngle);
end
