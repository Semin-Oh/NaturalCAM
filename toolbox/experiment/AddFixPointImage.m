function [imageEdit] = AddFixPointImage(image, options)
% Add a fixation point at the center of the image.
%
% Syntax:
%    [imageEdit] = AddFixPointImage(image)
%
% Description:
%    Add a fixation point at the center of the image. You can choose
%    diffrent type of patterns as you like. This is to achieve a better
%    focus at the center of the image during the experiment so that we can
%    minimize the artifacts for SACC project.
%
% Inputs:
%    image                      - Image that you want to add a fixation
%                                 point on.
%
% Outputs:
%    imageEdit                  - Edited image with fixation point
%
% Optional key/value pairs:
%    patternType                - Default to 'line'. Choose a desired
%                                 pattern type to display.
%    patternColor               - Deafult to black ([0 0 0]). Set color of
%                                 the pattern. Each value should be ranged
%                                 within 0-1.
%    patternSize                - Default to 10. Set the size of the
%                                 fixation point in pixel.
%    verbose                    - Boolean. Default true. Controls
%                                 printout.
%
% See also:
%    N/A

% History:
%   08/08/22 smo                - Wrote it.
%   09/03/24 smo                - Modified to work for non-square images.
%   09/09/24 smo                - Added an option of using filled-circle.

%% Set parameters.
arguments
    image
    options.patternType = 'line'
    options.patternColor (1,3) = [0 0 0]
    options.patternSize (1,1) = 8
    options.patternWidth (1,1) = 5
    options.verbose (1,1) = false
end

%% Set the position of the fixation point.
imageSize = size(image);
imageCenterHorizontal = imageSize(2) * 0.5;
imageCenterVertical = imageSize(1) * 0.5;

fixHorizontalPosition = [imageCenterHorizontal-options.patternSize imageCenterVertical imageCenterHorizontal+options.patternSize imageCenterVertical];
fixVerticalPosition = [imageCenterHorizontal imageCenterVertical-options.patternSize imageCenterHorizontal imageCenterVertical+options.patternSize];

switch (options.patternType)
    case 'line'
        patternPosition = [fixHorizontalPosition; fixVerticalPosition];
    case 'circle'
        patternPosition = [imageCenterHorizontal imageCenterVertical options.patternSize];
    case 'filled-circle'
        patternPosition = [imageCenterHorizontal imageCenterVertical options.patternSize];
end

% Set fixation point on the image here.
imageEdit = insertShape(image, options.patternType, patternPosition, ...
    'Color', options.patternColor, 'LineWidth', options.patternWidth,'opacity',1);
end
