function JCH = XYZToJCH(XYZ_target,XYZ_white,LA,options)
% Convert the CIE XYZ values to the CIECAM02 stats.
%
% Syntax: JCH = XYZToJCH(XYZ_target,XYZ_white,LA)
% 
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
%    JCH                      - The CIECAM02 lightness (J), chroma (C), and
%                               hue quadrature (H) of the target.
%
% Optional key/value pairs:
%    options.surround         - Set a surround condition. Choose one among
%                               three: 'average', 'dim', and 'dark'.
%                               Default to 'average'.
%
% See also:
%    JCHToXYZ.

% History:
%    07/23/24       smo       - Started on it.
%    07/25/24       smo       - Working fine. The calculation results match
%                               with the official CIECAM02 excel file.

%% Set variables.
arguments
    XYZ_target
    XYZ_white (3,1)
    LA (1,1)
    options.surround = 'average'
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
    case 'dark'
        F = 0.8;
        c = 0.525;
        Nc = 0.8;
    case 'dim'
        F = 0.9;
        c = 0.59;
        Nc = 0.95;
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
% Mcat02 is the matrix to convert from the XYZ to RGB for CIECAM02.
M_CAT02 = [0.7328 0.4296 -0.1624;...
    -0.7036 1.6975 0.0061;...
    0.0030 0.0136 0.9834];

% XYZ to RGB of the target.
RGB = M_CAT02 * XYZ_target;

% XYZ to RGB of the white point.
RGBw = M_CAT02 * XYZ_white;

% Degree of adaptation.
D = F*(1-(1/3.6)*exp((-LA-42)/92));

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
XYZc  = inv(M_CAT02) * RGBc;
XYZcw = inv(M_CAT02) * RGBcw;

%% Post adaptation non-linear response compression.
%
% Calculate the R'G'B' here.
M_HPE = [0.38971 0.68898 -0.07868;...
    -0.22981 1.18340 0.04641;...
    0.00000 0.00000 1.00000];

% R'G'B' of the target.
RGBp = M_HPE * XYZc;

% R'G'B' of the white point [R'w,G'w,B'w]
RGBpw = M_HPE * XYZcw;

% From R'G'B' to R'a,G'a,B'a of the target.
RGBpa  = (400*(FL*RGBp/100).^(0.42))./(27.13+(FL*RGBp/100).^(0.42)) + 0.1;
% From R'G'B' to R'a,G'a,B'a of the white point.
RGBpaw = (400*(FL*RGBpw/100).^(0.42))./(27.13+(FL*RGBpw/100).^(0.42)) + 0.1;

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
h_Red = 20.14;
h_Yellow = 90;
h_Green = 164.25;
h_Blue = 234.79;
h_Red360 = 380.14;
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
t = (50000/13)*Nc*Ncb*et*sqrt(a.^2+b.^2)./(RGBpa(1,:)+RGBpa(2,:)+(21/20)*RGBpa(3,:));
C = t.^(0.9) * sqrt(J/100) * (1.64-0.29^n)^0.73;

% Colorfulness (M).
M = C * FL^0.25;

% Saturation (s).
s = 100 * sqrt(M./Q);

%% Print out variables here.
JCH.h = h;
JCH.H = H;
JCH.J = J;
JCH.Q = Q;
JCH.C = C;
JCH.M = M;
JCH.s = s;

% Description of each color correlate.
JCH.describe.h = 'Hue angle (360)';
JCH.describe.H = 'Hue quadrature (400)';
JCH.describe.J = 'Lightness';
JCH.describe.Q = 'Brightness';
JCH.describe.C = 'Chroma';
JCH.describe.M = 'Colorfulness';
JCH.describe.s = 'Saturation';
