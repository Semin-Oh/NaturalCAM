function [XYZ] = RGBToXYZ(dRGB,M,gamma,options)
% Convert the digital RGB values to the CIE XYZ values.
%
% Syntax:
%    [XYZ] = RGBToXYZ(dRGB,M,gamma)
%
% Description:
%    Calculate the CIE XYZ values with the input of digital RGB values. It
%    aims to calculate the CIE stats of the image. This function should
%    work for a single pixel of multuple pixels for an image.
%
% Inputs:
%    dRGB                     - The digital RGB values of interest. This
%                               could be a single pixel (3x1) or multiple
%                               pixels in an image (3xn).
%    M                        - The 3x3 matrix to convert from the digital
%                               RGB values to the CIE XYZ values.
%    gamma                    - Gamma value of the target display.
%
% Outputs:
%    XYZ                      - The CIE XYZ values of the targeted digital
%                               RGB values (dRGB).
%
% Optional key/value pairs:
%    nInputlevels             - The number of input levels within the
%                               system. Default to 255 as we mostly use
%                               8-bit system.
%
% See also:
%    RGBToXYZ.

% History:
%    07/18/24       smo       - Wrote it
%    08/02/24       smo       - Modified it to work for a single pixel.

%% Set variables.
arguments
    dRGB
    M (3,3)
    gamma (1,1)
    options.nInputLevels (1,1) = 255;
end

% Set the same gamma value for all channels. We can modify it if we want
% later on.
gamma_R = gamma;
gamma_G = gamma;
gamma_B = gamma;

%% Calculation happens here.
%
% For correct calculations, make sure the class of the RGB matrix is
% 'double' so that it can be multiplied by the conversion matrix.
dRGB_Norm = double(dRGB) ./ options.nInputLevels;

% For a single pixel.
if size(dRGB_Norm,3) == 1
    LRGB_R = dRGB_Norm(1,:).^gamma_R;
    LRGB_G = dRGB_Norm(2,:).^gamma_G;
    LRGB_B = dRGB_Norm(3,:).^gamma_B;
else
    % For an image in 3-D format.
    LRGB_R = dRGB_Norm(:,:,1).^gamma_R;
    LRGB_G = dRGB_Norm(:,:,2).^gamma_G;
    LRGB_B = dRGB_Norm(:,:,3).^gamma_B;
end

% Resize the matrix so that we can compute the CIE XYZ values. It should
% look like 3 x n.
LRGB(1,:) = LRGB_R(:);
LRGB(2,:) = LRGB_G(:);
LRGB(3,:) = LRGB_B(:);

% Linear RGB to CIE XYZ.
XYZ = M * LRGB;
