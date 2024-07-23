function [dRGB] = XYZToRGB(XYZ, M, gamma, options)
% Convert the CIE XYZ values to the digital RGB values.
%
% Syntax:
%    [dRGB] = XYZToRGB(XYZ, M, gamma)
%
% Description:
%    Calculate the digital RGB values from the CIE XYZ values. It is the
%    reverse calculation from the CIE stats back to the digital RGB values.
%
% Inputs:
%    XYZ                      - CIE XYZ values that you want to convert
%                               to the digital RGB values.
%    M                        - The 3x3 matrix to convert from the digital
%                               RGB values to the CIE XYZ values. In this
%                               routine, we will calculate the inverse
%                               matrix of it.
%    gamma                    - Gamma value of the target display.
%
% Outputs:
%    dRGB                     - The converted results of the digital RGB
%                               values. The matrix would look like 3xn.
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

%% Set variables.
arguments
    XYZ
    M (3,3)
    gamma (1,1)
    options.nInputlevels (1,1) = 255;
end

%% Calculate the linear RGB from the XYZ.
% 
% Get the inverse matrix of the 3x3 matrix.
M_inverse = inv(M);

% Calculation happens here.
LRGB = M_inverse * XYZ;

%% Calculate the digital RGB from the linear RGB.
dRGB = (((LRGB).^(1/gamma)) .* options.nInputlevels);
dRGB = real(uint8(dRGB));
