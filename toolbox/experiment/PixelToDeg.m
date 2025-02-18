function [horizontalDeg, verticalDeg] = PixelToDeg(horizontalPixel, verticalPixel)
% This routine converts pixel coordinates to visual angles. The numbers are
% based on the curved display system.
%
% Syntax:
%    [horizontalDeg, verticalDeg] = PixelToDeg(horizontalPixel, verticalPixel)
%
% Description:
%    Converts the pixel info to FOV in degrees for the curved display
%    system. This routine was written for Color Assimilation project.
%
% Inputs:
%    horizontalPixel    - horizontal pixel coordinate (1 to 15360).
%    verticalPixel      - vertical pixel coordinate (1 to 1457).
%
% Outputs:
%    horizontalDeg      - horizontal visual angle in degrees.
%    verticalDeg        - vertical visual angle in degrees.
%
% Optional key/value pairs:
%
% See also:
%

% History:
%    11/11/24    smo    - Wrote it.

%% Display specifications.
totalWidthPixels = 15360;    % Total horizontal resolution
totalHeightPixels = 1457;    % Total vertical resolution
horizontalFOVDeg = 180;         % Horizontal field of view in degrees
screenHeightMeters = 0.335;  % Physical height of the screen in meters
observerDistanceMeters = 1;        % Distance from the screen to the observer in meters

%% Calculate the horizontal visual angle per pixel
hAnglePerPixel = horizontalFOVDeg / totalWidthPixels; % degrees per pixel

% Calculate the total vertical field of view
totalVerticalFOV = 2 * atand((screenHeightMeters / 2) / observerDistanceMeters); % degrees
vAnglePerPixel = totalVerticalFOV / totalHeightPixels; % degrees per pixel

% Calculate the visual angles for the given pixel coordinates
% Center the origin (0,0) to the middle of the screen
horizontalDeg = (horizontalPixel - totalWidthPixels / 2) * hAnglePerPixel;
verticalDeg = (verticalPixel - totalHeightPixels / 2) * vAnglePerPixel;
end
