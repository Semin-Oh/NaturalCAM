function [img_only] = ExtractImageOnly(img,options)
% This extracts the parts of the pixels where the actual images are.
%
% Syntax:
%    [img_only] = ExtractImageOnly(img)
%
% Description:
%    dd
%
% Inputs:
%    image                    - An input image that you want to extract the
%                               locations of the pixels where the actual
%                               image is.
%
% Outputs:
%    img_only                 - Image where the actual target image is.
%
% Optional key/value pairs:
%    verbose                  - Control the plot and alarm messages.
%                               Default to false.
%
% See also:
%    N/A

% History:
%    10/16/24    smo    - Wrote it.

%% Set parameters.

%% Extract the pixel location of the image.

% Step 1: Load the image with transparency (e.g., PNG)
[img, ~, alpha] = imread('brownegg.png'); 

% Step 2: Find non-transparent pixels (alpha > 0)
nonTransparentIdx = find(alpha > 0);

% Step 3: Convert linear indices to row, column coordinates
[row, col] = ind2sub(size(alpha), nonTransparentIdx);

% Now, row and col contain the coordinates of the non-transparent pixels
% You can display or manipulate them as needed.
img_only = img;
for pp = 1:length(row)
    img_only(row(pp),col(pp),1) = img(row(pp),col(pp),1);
    img_only(row(pp),col(pp),2) = img(row(pp),col(pp),2);
    img_only(row(pp),col(pp),3) = img(row(pp),col(pp),3);
end

figure; imshow(img_only);

end