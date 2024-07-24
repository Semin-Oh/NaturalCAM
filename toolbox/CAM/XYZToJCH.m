function JCh = XYZToJCH(XYZ_target,XYZ_white,options)
% Convert the CIE XYZ values to the CIECAM02 stats.
%
% Syntax:
%
%
% Description:
%    Calculate the CIECAM02 perceptual attributes. This routine should
%    work for either a single pixel or multiple of an image.
%
% Inputs:
%    XYZ                      - CIE XYZ values of the interest. This could
%                               be a single pixel (3x1) or multiple (3xn).
%    XYZw                     - The white point in the scene for
%                               calculations.
%
% Outputs:
%    d
%
% Optional key/value pairs:
%    options.surround         - Set a surround condition. Choose one among
%                               three: 'average', 'dim', and 'dark'.
%                               Default to 'average'.
%    LA                       - Luminance of the adapting filed in the unit
%                               of cd/m2.
%
% See also:
%    JCHToXYZ.

% History:
%    07/23/24       smo       - Started on it.

%% Set variables.
arguments
    XYZ_target
    XYZ_white (3,1)
    options.LA (1,1) = []
    options.surround = 'average'
end

% Get the size of the target.
[R nTargets] = size(XYZ_target);

%% Viewing Condition Parameters.
%
% Luminance of the background. It is usually set as 20% of the luminance of
% the adapting field for convenience (unit cd/m2).
if isempty(option.LA)
    options.LA = XYZ_white(2);
    Yb = options.LA * 0.2;
end

% Define surround condition.
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

% More parameters based on the surround and background.
k = 1/(5*options.LA+1);
FL = 0.2*(k^4)*(5*options.LA) + 0.1*((1-k^4)^2)*((5*options.LA)^(1/3));
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
b = (1/9)*(RGBpa(1,:) + RGBpa(2,:) - 2*RGBpa(3,:));

% Hue angle.
for ii = 1:nTargets
    h_temp = rad2deg(atan2(b(ii),a(ii)));

    % When the hue angle value is negative, we set it to a positive by adding
    % 360 degrees.
    if h_temp < 0
        h(1,ii) = 360 + rad2deg(atan2(b(ii),a(ii)));
    else
        h(1,ii) = h_temp;
    end
end

% Hue quadrature.
et = (1/4)*(cos(deg2rad(h*pi/180+2))+3.8);


e = ((12500/13)*Nc*Ncb)*(cos(h*(pi/180)+2)+3.8);
t = (e.*((a.^2+b.^2).^(0.5)))./(RGBpa(:,1)+RGBpa(:,2)+(21/20)*RGBpa(:,3));

% Brightness.
A = (2*RGBpa(:,1)+RGBpa(:,2)+(1/20)*RGBpa(:,3)-0.305)*Nbb;
Aw = (2*RGBpaw(1,1)+RGBpaw(1,2)+(1/20)*RGBpaw(1,3)-0.305)*Nbb;

% Lightness.
J = 100*(A/Aw).^(c*z);

% Chroma.
nTargets = (t.^(0.9)).*((J/100).^(0.5))*(1.64-0.29^n)^(0.73);

%% Print out variables here.
JCh = [J nTargets h];
