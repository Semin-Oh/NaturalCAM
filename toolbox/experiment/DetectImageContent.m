function [image_detected] = DetectImageContent(image,options)
% This routine detects the actual contents of the image.
%
% Syntax:
%    [canvas] = MakeImageCanvas(image)
%
% Description:
%    It detects the actual image content and resize it. The result image
%    would be the same size as the input image in pixel. Also, 
%
% Inputs:
%    image                    - An input image to detect its contents.
%
% Outputs:
%    image_detected           - Detected image contents in desired size.
%
% Optional key/value pairs:
%    verbose                  - Control the plot and alarm messages.
%                               Default to false.
%
% See also:
%    MakeImageCanvas.

% History:
%    11/05/24    smo    - Wrote it.

%% Set variables.
arguments
    image
    options.verbose (1,1) = false
end

%% Get the original image size.
[originalHeight originalWidth nChannels] = size(image);
desiredHeightPixel = originalHeight;

%% Detect the actual contents of the image.
%
% Find the edges of the contents. We will do this after converting the
% image black and white to make it easier.
grayImage = rgb2gray(image);
edges = edge(grayImage, 'canny');
[row, col] = find(edges);

% Get the cropped the image content.
topRow = min(row);
bottomRow = max(row);
leftCol = min(col);
rightCol = max(col);
croppedImage = image(topRow:bottomRow, leftCol:rightCol, :);

% Get the size of the image content.
[croppedHeight croppedWidth nChannels] = size(croppedImage);
ratioWidthToHeight = croppedWidth/croppedHeight;

% Resize the detected image content.
desiredWidthPixel = desiredHeightPixel * ratioWidthToHeight;
image_detected = imresize(croppedImage, [desiredHeightPixel, desiredWidthPixel]);

%% Plot the result image if you want.
if (options.verbose)
    figure; hold on;
    subplot(1,2,1);
    imshow(image);
    title('Original');

    subplot(1,2,2);
    imshow(image_detected);
    title('Detected');
end
end
