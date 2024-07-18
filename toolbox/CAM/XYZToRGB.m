function dRGB = XYZToRGB(XYZ, M, gamma)

%% Set variables.
nInputlevels = 255;

%% Calculation happens here.
M_inverse = inv(M);

LRGB = M_inverse * XYZ;

dRGB = (((LRGB).^(1/gamma)).*nInputlevels);
dRGB = real(uint8(dRGB));