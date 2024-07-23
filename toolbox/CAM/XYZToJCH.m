function JCh = XYZToJCH(XYZ,whitepoint,LA,options)
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
%    whitepoint               - The white point in the scene for
%                               calculations.
%    LA                       - Luminance of the adapting filed in the unit
%                               of cd/m2.
%
% Outputs:
%    d
%
% Optional key/value pairs:
%    options.surround         - Set a surround condition. Choose one among
%                               three: 'average', 'dim', and 'dark'.
%                               Default to 'average'.
%
% See also:
%    RGBToXYZ.

% History:
%    07/23/24       smo       - Started on it.

%% Set variables.
arguments
    XYZ
    whitepoint
    LA
    options.surround = 'average'
end

% Get the size of the target.
[M S] = size(XYZ);

% Viewing Condition Parameters.
% Luminance of the background. It is usually set as 20% of the luminance of
% the adapting field for convenience.
Yb = LA * 0.2;
% Yb = 20;

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

k = 1/(5*LA+1);
FL = 0.2*(k^4)*(5*LA)+0.1*((1-k^4)^2)*((5*LA)^(1/3));
n = Yb/whitepoint(1,2);
Nbb = 0.725*(1/n)^(0.2);
Ncb = Nbb;
z = 1.48 + sqrt(n);

%% Chromatic Adaptation.
%
% Mcat02 is the matrix to convert from the XYZ to RGB for CIECAM02.
Mcat02 = [0.7328 0.4296 -0.1624;...
    -0.7036 1.6975 0.0061;...
    0.0030 0.0136 0.9834];

% XYZ to RGB of the target.
RGB = XYZ * Mcat02';

% XYZ to RGB of the white point.
RGBw = whitepoint * Mcat02';

% Degree of adaptation.
D = F*(1-(1/3.6)*exp((-LA-42)/92));

% Calculate the corresponding color of the target.
Rc = ((whitepoint(1,2)*D/RGBw(1,1))+(1-D))*RGB(:,1);
Gc = ((whitepoint(1,2)*D/RGBw(1,2))+(1-D))*RGB(:,2);
Bc = ((whitepoint(1,2)*D/RGBw(1,3))+(1-D))*RGB(:,3);
RGBc = [Rc Gc Bc];

% Calculate the corresponding color of the white point.
Rcw = ((whitepoint(1,2)*D/RGBw(1,1))+(1-D))*RGBw(1,1);
Gcw = ((whitepoint(1,2)*D/RGBw(1,2))+(1-D))*RGBw(1,2);
Bcw = ((whitepoint(1,2)*D/RGBw(1,3))+(1-D))*RGBw(1,3);
RGBcw = [Rcw Gcw Bcw];

% Here, calculate it back to the XYZ.
XYZc = RGBc*inv(Mcat02)';
XYZcw = RGBcw*inv(Mcat02)';

%% Non-Linear Response Compression.
%
% Calculate the R'G'B' here.
MH = [0.38971 0.68898 -0.07868;...
    -0.22981 1.18340 0.04641;...
    0.00000 0.00000 1.00000];

% R'G'B' of the target.
RGBp = XYZc * MH';

% R'G'B' of the white point [R'w,G'w,B'w]
RGBpw = XYZcw * MH';

% Compression happens here.
%
% From R'G'B' to R'a,G'a,B'a of the target.
RGBpa = ((400*(FL*RGBp/100).^(0.42))./(27.13+(FL*RGBp/100).^(0.42))) +0.1;
% From R'G'B' to R'a,G'a,B'a of the white point.
RGBpaw = ((400*(FL*RGBpw/100).^(0.42))./(27.13+(FL*RGBpw/100).^(0.42))) +0.1;

%% Calculate perceptual attribute correlates.
a = ones(M,1);
b = ones(M,1);
h = ones(M,1);
e = ones(M,1);
t = ones(M,1);

a = RGBpa(:,1)-12*RGBpa(:,2)/11+RGBpa(:,3)/11;
b = (1/9)*(RGBpa(:,1)+RGBpa(:,2)-2*RGBpa(:,3));

% Hue.
for i = 1:M
    if b(i,1) >= 0
        h(i,1) = (360/(2*pi))*atan2(b(i,1),a(i,1));
    else
        h(i,1) = 360+(360/(2*pi))*atan2(b(i,1),a(i,1));
    end
end

% Hue quadrature.
e = ((12500/13)*Nc*Ncb)*(cos(h*(pi/180)+2)+3.8);
t = (e.*((a.^2+b.^2).^(0.5)))./(RGBpa(:,1)+RGBpa(:,2)+(21/20)*RGBpa(:,3));

% Brightness.
A = (2*RGBpa(:,1)+RGBpa(:,2)+(1/20)*RGBpa(:,3)-0.305)*Nbb;
Aw = (2*RGBpaw(1,1)+RGBpaw(1,2)+(1/20)*RGBpaw(1,3)-0.305)*Nbb;

% Lightness.
J = 100*(A/Aw).^(c*z);

% Chroma.
C = (t.^(0.9)).*((J/100).^(0.5))*(1.64-0.29^n)^(0.73);

%% Print out variables here.
JCh = [J C h];
