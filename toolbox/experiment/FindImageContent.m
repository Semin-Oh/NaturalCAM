function croppedImage = FindImageContent(image,options)
% This routine extracts the image content from the background.
%
% Syntax:
%    croppedImage = FindImageContent(image)
%
% Description:
%    It finds the actual image contents from the unnecessary background.
%    For example, when saving out the images from the CoCo dataset, all the
%    images have the same resolution (993x1390 pixels) on the black
%    background. This routine is useful to extract the pixels where the
%    actual image contents are lying.
%
% Inputs:
%    image                      - Target image to exctract the contents.
%
% Outputs:
%    croppedImage               - Output image that only contains the
%                                 actual image contents.
%
%
% Optional key/value pairs:
%    verbose                    - Boolean. Default true. Controls
%                                 printout.
%
% See also:
%    N/A

% History:
%   03/11/25 smo                - Wrote it.

%% Set variables.
arguments
    image
    options.pixelBackground (1,1) = 0
    options.verbose (1,1) = false
end

%% Convert the image into grayscale and find non-black pixels.
%
% As the CoCo dataset image makes the background black, here we exclude the
% black background and mask for non-black pixels.
grayImg = rgb2gray(image);
mask = grayImg > options.pixelBackground;

% Find bounding box of non-black region.
[y, x] = find(mask);
xMin = min(x);
xMax = max(x);
yMin = min(y);
yMax = max(y);

% Crop the image.
croppedImage = image(yMin:yMax, xMin:xMax, :);

% Show the result if you want.
if (options.verbose)
    figure;
    imshow(croppedImage);
end
end
