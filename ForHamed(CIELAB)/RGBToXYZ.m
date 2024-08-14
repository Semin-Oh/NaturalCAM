function [XYZ] = RGBToXYZ(image,M,gamma)

%% Set variables.
nInputLevels = 255;
gamma_R = gamma;
gamma_G = gamma;
gamma_B = gamma;

% For correct calculations, make sure the class of the RGB matrix is
% 'double' so that it can be multiplied by the conversion matrix.
dRGB_Norm = double(image)./nInputLevels;
LRGB_R = dRGB_Norm(:,:,1).^gamma_R;
LRGB_G = dRGB_Norm(:,:,2).^gamma_G;
LRGB_B = dRGB_Norm(:,:,3).^gamma_B;

% Resize the matrix so that we can compute the CIE XYZ values. It should
% look like 3 x n.
LRGB(1,:) = LRGB_R(:);
LRGB(2,:) = LRGB_G(:);
LRGB(3,:) = LRGB_B(:);

% Linear RGB to CIE XYZ.
XYZ = M * LRGB;









