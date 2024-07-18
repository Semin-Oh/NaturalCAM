function [XYZ M N] = rgb2xyz(rgb,gamma)
rgb1 = imread(rgb);
rgb_d = double(rgb1); %digital RGB
[M N P] = size(rgb_d);

rgb_d = 100*(((rgb_d./255)).^gamma); %linear RGB
rgb2XYZ = [0.5805 0.1687 0.1700; 0.2766 0.6428 0.0814; 0.0099 0.1018 0.9065]; % Custom mode
% rgb2XYZ = [0.4124 0.3576 0.1805;0.2126 0.7152 0.0722; 0.0193 0.1192 0.9505]; %sRGB
% rgb2XYZ = [64.45 32.62 1.52;45.30 97.07 13.90;23.81 11.15 125.76]; % monitor gamut - absolute


X = rgb2XYZ(1,1).*rgb_d(:,:,1) + rgb2XYZ(1,2).*rgb_d(:,:,2) + rgb2XYZ(1,3).*rgb_d(:,:,3);
Y = rgb2XYZ(2,1).*rgb_d(:,:,1) + rgb2XYZ(2,2).*rgb_d(:,:,2) + rgb2XYZ(2,3).*rgb_d(:,:,3);
Z = rgb2XYZ(3,1).*rgb_d(:,:,1) + rgb2XYZ(3,2).*rgb_d(:,:,2) + rgb2XYZ(3,3).*rgb_d(:,:,3);


XYZ = [X(:), Y(:),Z(:)]; %tristimulus value







