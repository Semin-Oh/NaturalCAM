function XYZ = JCHToXYZ(JCh,XYZ_white,LA,options)
% Convert the CIECAM02 JCH values to the CIE XYZ values
%
% Syntax: XYZ = JCHToXYZ(JCh,XYZ_white,LA)
%
% Description:
%    This routine does the inverse calculates the CIECAM02. It takes input
%    of lightness (J), chroma (C), and hue angle (h) to calculate the
%    CIE XYZ values. This routine should work for either a single pixel or
%    multiple of an image.
%
% Inputs:
%    JCh                      - The CIECAM02 lightness (J), chroma (C), and
%                               hue angle (h) values of the target. This
%                               could be a single pixel (3x1) or multiple
%                               (3xn).
%    XYZ_white                - CIE XYZ values of the white point in the
%                               scene for calculations. This should be the
%                               absolute XYZ values where its Y value
%                               equals to the luminance (cd/m2).
%    LA                       - Luminance of the adapting field (cd/m2).
%
% Outputs:
%    XYZ                      - The CIE XYZ values of the target.
%
% Optional key/value pairs:
%    options.surround         - Set a surround condition. Choose one among
%                               three: 'average', 'dim', and 'dark'.
%                               Default to 'average'.
%
% See also:
%    XYZToJCH.

% History:
%    07/25/24       smo       - Started on it. And it's working fine. The
%                               routine gives the same calculation results
%                               as the official excel file does.

%% Set variables.
arguments
    JCh
    XYZ_white (3,1)
    LA (1,1)
    options.surround = 'average'
end

% Get the number of the target.
nTargets = size(JCh,2);

% Transformation CIECAM02 to XYZ
% input
% JCh =  M X 3 Matrix
% White = XYZ tristimulus value XYZ , size [1 X 3]

%% Viewing Condition Parameters.
%
% Luminance of the background. It is usually set as 20% of the white point
% for convenience. As we normalized the white point (Y=100), Yb gonna be 20
% cd/m2.
Yb = 20.0;

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
FL = 0.2*(k^4)*(5*LA)+0.1*((1-k^4)^2)*((5*LA)^(1/3));
n = Yb/XYZ_white(2);
Nbb = 0.725*(1/n)^(0.2);
Ncb = Nbb;
z = 1.48 + sqrt(n);

%% The 3x3 conversion matrixes from XYZ to RGB.
%
% Chromatic adaptation transfer.
M_CAT02 = [0.7328 0.4296 -0.1624;...
    -0.7036 1.6975 0.0061;...
    0.0030 0.0136 0.9834];

% For non-linear post processing.
M_HPE = [0.38971 0.68898 -0.07868;...
    -0.22981 1.18340 0.04641;...
    0.00000 0.00000 1.00000];

%% Calculate the white point.
%
% RGB after chromatic adaptation.
RGBw =  M_CAT02 * XYZ_white;

D = F*(1-(1/3.6)*exp((-LA-42)/92));
Rcw = ((XYZ_white(2)*D/RGBw(1))+(1-D))*RGBw(1);
Gcw = ((XYZ_white(2)*D/RGBw(2))+(1-D))*RGBw(2);
Bcw = ((XYZ_white(2)*D/RGBw(3))+(1-D))*RGBw(3);
RGBcw = [Rcw; Gcw; Bcw];

% Calculate it back to the XYZ.
XYZcw = inv(M_CAT02) * RGBcw;

% Then, calculate the post non-linear processing.
RGBpw = M_HPE * XYZcw;
RGBpaw = ((400*(FL*RGBpw/100).^(0.42)) ./ (27.13+(FL*RGBpw/100).^(0.42)))+0.1;
Aw = (2*RGBpaw(1) + RGBpaw(2) + (1/20)*RGBpaw(3)-0.305) * Nbb;

J = JCh(1,:);
C = JCh(2,:);
h_deg = JCh(3,:);
t = (C./(((J./100).^(0.5)).*(1.64 - 0.29.^n).^0.73)).^(1/0.9);
A = Aw.*((J./100).^(1/(c.*z)));
e = 50000/13*Nc*Ncb*0.25.*(cos(h_deg.*(pi/180)+2)+3.8);

%% Calculate the post non-linear processed signal of the target (R'a,G'a,B'a).
crt1 = abs(sin(h_deg .* pi./180));
crt2 = abs(cos(h_deg .* pi./180));

a = (((A./Nbb) + 0.305).*(2 + (21/20)).*(460/1403))./(((e./t)./sin(h_deg.*pi./180)) + (2 + (21/20)).* (220/1403).*(cos(h_deg.*pi./180)./sin(h_deg.*pi./180))-(27./1403)+(21./20).*(6300./1403)).*(cos(h_deg.*pi./180)./sin(h_deg.*pi./180));
b = (((A./Nbb) + 0.305).*(2 + (21/20)).*(460/1403))./(((e./t)./sin(h_deg.*pi./180)) + (2 + (21/20)).* (220/1403).*(cos(h_deg.*pi./180)./sin(h_deg.*pi./180)) - (27./1403) + (21/20).*(6300/1403));

k2 = find(crt1<crt2);
a(k2) = (((A(k2)./Nbb) + 0.305).* (2 + (21/20)) .*(460/1403))./(((e(k2)./t(k2))./cos(h_deg(k2).*pi./180)) + (2 + (21/20)).*(220/1403) - ((27 ./1403)- (21/20).* (6300/1403)).*(sin(h_deg(k2).*pi/180)./ cos(h_deg(k2).*pi./180)));
b(k2) = (((A(k2)./Nbb) + 0.305).* (2 + (21/20)) .* (460/1403))./ (((e(k2)./t(k2))./ cos(h_deg(k2).*pi ./180)) + ((2 + (21/20)) .* (220/1403)) - ((27 ./1403) - (21/20) * (6300/1403)) .* (sin(h_deg(k2).*pi./180) ./ cos(h_deg(k2).*pi./180))).*sin(h_deg(k2).*pi./180)./cos(h_deg(k2).*pi./180);

k3 = find(t == 0);
a(k3) = 0;
b(k3) = 0;

Rpa(1,:) = (460/1403).*((A./Nbb) + 0.305) + (451./1403).* a + (288/1403).* b;
Gpa(1,:) = (460/1403).*((A./Nbb) + 0.305) - (891./1403).* a - (261/1403).* b;
Bpa(1,:) = (460/1403).*((A./Nbb) + 0.305) - (220./1403).* a - (6300/1403).* b;

cri3_1 = Rpa-0.1;
cri3 = find(cri3_1 > 0);
Rp(cri3) = (100./FL) .* (((27.13 .* abs(Rpa(cri3) - 0.1))./(400 - abs(Rpa(cri3) - 0.1))).^(1/0.42));
cri4 = find(cri3_1 <= 0);
Rp(cri4) = (-1) .* (100./FL).*(((27.13.*abs(Rpa(cri4)-0.1))./(400 - abs(Rpa(cri4) - 0.1))).^(1/0.42));

cri5_1 = Gpa-0.1;
cri5 = find(cri5_1 > 0);
Gp(cri5) = (100./FL).*(((27.13.* abs(Gpa(cri5) - 0.1))./(400 - abs(Gpa(cri5) - 0.1))).^(1/0.42));
cri6 = find(cri5_1 <= 0);
Gp(cri6) = (-1) .* (100./FL).*(((27.13.* abs(Gpa(cri6) - 0.1))./(400 - abs(Gpa(cri6) - 0.1))).^(1/0.42));

cri7_1 = Bpa - 0.1;
cri7 = find(cri7_1 > 0);
Bp(cri7) = (100./FL).*(((27.13.* abs(Bpa(cri7) - 0.1))./(400 - abs(Bpa(cri7) - 0.1))).^(1/0.42));
cri8 = find(cri7_1 <= 0);
Bp(cri8) = (-1) .* (100./FL).*(((27.13.* abs(Bpa(cri8) - 0.1))./(400 - abs(Bpa(cri8) - 0.1))).^(1/0.42));

RGBp = [Rp; Gp; Bp];

%% Calculate the RGB signals of the corresponding color (Rc,Gc,Bc).
XYZp = inv(M_HPE)*RGBp;
RGBc = M_CAT02*XYZp;

%% RGB of the target.
RGB(1,:) = RGBc(1,:)./((XYZ_white(2)*D/RGBw(1))+(1-D));
RGB(2,:) = RGBc(2,:)./((XYZ_white(2)*D/RGBw(2))+(1-D));
RGB(3,:) = RGBc(3,:)./((XYZ_white(2)*D/RGBw(3))+(1-D));

%% Calculate the XYZ of the target.
XYZ = inv(M_CAT02) * RGB;
