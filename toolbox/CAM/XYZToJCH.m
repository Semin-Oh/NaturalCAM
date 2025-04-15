function JCH = XYZToJCH(XYZ_target,XYZ_white,LA,options)
% Convert XYZ into JCH using CIECAM02 or CAM16.
%
% Syntax: JCH = XYZToJCH(XYZ_target,XYZ_white,LA)
%
% Description:
%    Calculate the CIECAM02 perceptual attributes. This routine should
%    work for either a single pixel or multiple of an image.
%
% Inputs:
%    XYZ_target               - CIE XYZ values of the interest. This could
%                               be a single pixel (3x1) or multiple (3xn).
%    XYZ_white                - CIE XYZ values of the white point in the
%                               scene for calculations. This should be the
%                               absolute XYZ values where its Y value
%                               equals to the luminance (cd/m2).
%    LA                       - Luminance of the adapting field (cd/m2).
%
% Outputs:
%    JCh                      - The CIECAM02 lightness (J), chroma (C), and
%                               hue angle (h) of the target.
%
% Optional key/value pairs:
%    options.surround         - Set a surround condition. Choose one among
%                               three: 'average', 'dim', and 'dark'.
%                               Default to 'average'.
%    options.whichCAM         - Decide which CAM to calculate. Default to
%                               CAM16.
%    options.size             - Define the size of stimuli. This is only
%                               applied when using CAM16 model. Default to
%                               medium.
%    HPM21                    - Use parameters from the model HPM21_Oh. It
%                               happens in the Degree of Adaptation (D) and
%                               Unique hue settings. Default to false.
%
% See also:
%    JCHToXYZ.

% History:
%    07/23/24       smo       - Started on it.
%    07/25/24       smo       - Working fine. The calculation results match
%                               with the official CIECAM02 excel file.
%    04/01/25       smo       - Added an option to calculate CAM16 values.
%    04/15/25       smo       - Added an option to calculate HPM21.

%% Set variables.
arguments
    XYZ_target
    XYZ_white (3,1)
    LA (1,1)
    options.surround = 'average'
    options.whichCAM = 'CAM16'
    options.size = 'medium'
    options.HPM21 = false;
end

% Get the number of the target.
nTargets = size(XYZ_target,2);

%% Viewing Condition Parameters.
%
% Luminance of the background. It is usually set as 20% of the white point
% for convenience. As we normalized the white point (Y=100), Yb gonna be 20
% cd/m2.
Yb = 20;

% Define surround condition. Choose one among three.
switch options.surround
    % ~1deg field (slide).
    case 'dark'
        F = 0.8;
        c = 0.525;
        Nc = 0.8;
        % ~4deg field (TV/movie).
    case 'dim'
        F = 0.9;
        c = 0.59;
        Nc = 0.95;
        % ~20deg field (normal room).
    case 'average'
        F = 1.0;
        c = 0.69;
        Nc = 1.0;
end

% More parameters based on the surround and adapting field.
k = 1/(5*LA+1);
FL = 0.2*(k^4)*(5*LA) + 0.1*((1-k^4)^2)*((5*LA)^(1/3));
n = Yb/XYZ_white(2);
Nbb = 0.725*(1/n)^0.2;
Ncb = Nbb;
z = 1.48 + sqrt(n);

%% Chromatic Adaptation.
%
% M_CAT is the matrix to convert from the XYZ to RGB.
switch options.whichCAM
    case 'CIECAM02'
        M_CAT02 = [0.7328 0.4296 -0.1624;...
            -0.7036 1.6975 0.0061;...
            0.0030 0.0136 0.9834];
        M_CAT = M_CAT02;
    case 'CAM16'
        M_CAT16 = [0.401288,  0.650173, -0.051461;...
            -0.250268,  1.204414,  0.045854;...
            -0.002079,  0.048952,  0.953127];
        M_CAT = M_CAT16;
end

% XYZ to RGB of the target.
RGB = M_CAT * XYZ_target;

% XYZ to RGB of the white point.
RGBw = M_CAT * XYZ_white;

% Degree of adaptation.
D = F*(1-(1/3.6)*exp((-LA-42)/92));

% Add chromaticity factor in the degree of adaptation (HPM21_Oh).
if (options.HPM21)
    % Calculate the u'v' of the white point.
    uv_white = XYZTouv(XYZ_white);

    % Calculate the chroma effect on the adaptation. This is from the model
    % HPM21_Oh.
    a=0.19595;
    b=0.07332;
    c=0.48135;
    d=0.06547;
    f_chroma = exp(-0.5*((uv_white(1)-a)/b)^2+((uv_white(2)-c)/d)^2);

    % Compensate the chroma of the illuminant here.
    D = D * f_chroma;
end

if strcmpi(options.whichCAM, 'CAM16')
    D = max(0, min(1, D));
end

% Calculate the corresponding color of the target. Note that the part of
% the luminance of the white point ('whitepoint(2)') is equal to 100 if
% we normalized the CIE XYZ values in advance. But, here we set it this way
% for general use. Thus, this equation should work fine for either
% normalized or non-normalized values.
Rc = ((XYZ_white(2)*D/RGBw(1))+(1-D))*RGB(1,:);
Gc = ((XYZ_white(2)*D/RGBw(2))+(1-D))*RGB(2,:);
Bc = ((XYZ_white(2)*D/RGBw(3))+(1-D))*RGB(3,:);
RGBc = [Rc; Gc; Bc];

% Calculate the corresponding color of the white point.
Rcw = ((XYZ_white(2)*D/RGBw(1))+(1-D))*RGBw(1);
Gcw = ((XYZ_white(2)*D/RGBw(2))+(1-D))*RGBw(2);
Bcw = ((XYZ_white(2)*D/RGBw(3))+(1-D))*RGBw(3);
RGBcw = [Rcw; Gcw; Bcw];

% Here, calculate it back to the XYZ.
XYZc  = inv(M_CAT) * RGBc;
XYZcw = inv(M_CAT) * RGBcw;

%% Post adaptation non-linear response compression.
%
% Calculate the R'G'B' here.
switch options.whichCAM
    case 'CIECAM02'
        M_HPE_CIECAM02 = [0.38971 0.68898 -0.07868;...
            -0.22981 1.18340 0.04641;...
            0.00000 0.00000 1.00000];
        M_HPE = M_HPE_CIECAM02;
    case 'CAM16'
        M_HPE_CAM16 = [0.389986,  0.688859, -0.078846;...
            -0.229646,  1.183883,  0.045762;...
            0.000000,  0.000000,  1.000000];
        M_HPE = M_HPE_CAM16;
end

% R'G'B' of the target.
RGBp = M_HPE * XYZc;

% R'G'B' of the white point [R'w,G'w,B'w]
RGBpw = M_HPE * XYZcw;

% Set the exponent value differently over different models.
switch options.whichCAM
    case 'CIECAM02'
        numExponent = 0.42;
    case 'CAM16'
        numExponent = 0.43;
end

% From R'G'B' to R'a,G'a,B'a of the target.
RGBpa  = (400*(FL*RGBp/100).^(numExponent))./(27.13+(FL*RGBp/100).^(numExponent)) + 0.1;
% From R'G'B' to R'a,G'a,B'a of the white point.
RGBpaw = (400*(FL*RGBpw/100).^(numExponent))./(27.13+(FL*RGBpw/100).^(numExponent)) + 0.1;

%% Calculate perceptual attribute correlates.
a = ones(1,nTargets);
b = ones(1,nTargets);
h = ones(1,nTargets);
e = ones(1,nTargets);
t = ones(1,nTargets);

% Initial opponent responses.
a = RGBpa(1,:) - 12*RGBpa(2,:)/11 + RGBpa(3,:)/11;
b = (RGBpa(1,:) + RGBpa(2,:) - 2*RGBpa(3,:))/9;

% Hue angle.
for ii = 1:nTargets
    h_temp = rad2deg(atan2(b(ii),a(ii)));

    % When the hue angle value is negative, we set it to a positive by
    % adding 360 degrees.
    if h_temp < 0
        h(1,ii) = 360 + rad2deg(atan2(b(ii),a(ii)));
    else
        h(1,ii) = h_temp;
    end
end

%% Hue quadrature.
%
% Unique hue angles defined in CIECAM02. As the hue angle circles within
% 360, so red (20.14) is equivalent with the red (380.14).
if (options.HPM21)
    h_Red = 1.78;
    h_Yellow = 86.34;
    h_Green = 142.82;
    h_Blue = 238.34;
    h_Red360 = 361.78;
else
    h_Red = 20.14;
    h_Yellow = 90;
    h_Green = 164.25;
    h_Blue = 234.79;
    h_Red360 = 380.14;
end
h_Unique = [h_Red h_Yellow h_Green h_Blue h_Red360];

% Hue eccentricity factors.
e_Red = 0.8;
e_Yellow = 0.7;
e_Green = 1;
e_Blue = 1.2;
e_Red360 = 0.8;
e_Unique = [e_Red e_Yellow e_Green e_Blue e_Red360];

% Unique hue quadrature;
H_Unique = [0 100 200 300 400];

% Set the hue angle (hq) for calculation of the hue quadrature.
for ii = 1:nTargets
    if h(ii) < h_Unique(1)
        hq(1,ii) = h(ii) + 360;
    else
        hq(1,ii) = h(ii);
    end
end

% Get a unique hue index.
for ii = 1:nTargets
    if hq(ii) < h_Unique(2)
        idx_UniqueHue(1,ii) = 1;
    elseif hq(ii) < h_Unique(3)
        idx_UniqueHue(1,ii) = 2;
    elseif hq(ii) < h_Unique(4)
        idx_UniqueHue(1,ii) = 3;
    else
        idx_UniqueHue(1,ii) = 4;
    end
end

% Get two adjacent unique hues and eccentricity.
for ii = 1:nTargets
    % Hue angle.
    hi(1,ii) = h_Unique(idx_UniqueHue(ii));
    hi_next(1,ii) = h_Unique(idx_UniqueHue(ii)+1);

    % Eccentricity.
    ei(1,ii) = e_Unique(idx_UniqueHue(ii));
    ei_next(1,ii) = e_Unique(idx_UniqueHue(ii)+1);

    % Hue quadrature.
    Hi(1,ii) = H_Unique(idx_UniqueHue(ii));
end

% Finally, calculate the hue quadrature (H) here.
H = Hi + (100 * (hq-hi)./ei) ./ ((hq-hi)./ei + (hi_next-hq)./ei_next);

% Lightness (J).
A  = (2*RGBpa(1,:) + RGBpa(2,:) + (1/20)*RGBpa(3,:) - 0.305)*Nbb;
Aw = (2*RGBpaw(1) + RGBpaw(2) + (1/20)*RGBpaw(3) - 0.305)*Nbb;
J = 100*(A/Aw).^(c*z);

% Brightness (Q).
Q = (4/c)*sqrt(J/100)*(Aw+4)*FL^0.25;

% Chroma (C).
et = (1/4)*(cos(hq*pi/180+2)+3.8);
t = (50000/13)*Nc*Ncb*et.*sqrt(a.^2+b.^2)./(RGBpa(1,:)+RGBpa(2,:)+(21/20)*RGBpa(3,:));
C = t.^(0.9) .* sqrt(J/100) * (1.64-0.29^n)^0.73;

% For CAM16, adjust chroma over size.
if strcmpi(options.whichCAM,'CAM16')
    % CAM16 size correction factors from CIE TC1-34.
    switch options.size
        case 'small'
            c_size_factor = 0.9;
        case 'medium'
            c_size_factor = 0.95;
        otherwise
            c_size_factor = 1.0;
    end
    C = C * c_size_factor;
end

% Colorfulness (M).
M = C * FL^0.25;

% Saturation (s).
s = 100 * sqrt(M./Q);

%% Print out variables here.
JCH = [J; C; H];

% This part has been deactivated for now. We can customize the variables to
% print out later on.
%
% JCH.h = h;
% JCH.H = H;
% JCH.J = J;
% JCH.Q = Q;
% JCH.C = C;
% JCH.M = M;
% JCH.s = s;
%
% % Description of each color correlate.
% JCH.describe.h = 'Hue angle (360)';
% JCH.describe.H = 'Hue quadrature (400)';
% JCH.describe.J = 'Lightness';
% JCH.describe.Q = 'Brightness';
% JCH.describe.C = 'Chroma';
% JCH.describe.M = 'Colorfulness';
% JCH.describe.s = 'Saturation';
