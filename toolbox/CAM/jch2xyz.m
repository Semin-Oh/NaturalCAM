function XYZ = jch2xyz(JCh, LA,light,white)
% Transformation CIECAM02 to XYZ
% input
% JCh =  M X 3 Matrix
% White = XYZ tristimulus value XYZ , size [1 X 3] 
if (nargin<4)
  white = [95.05, 100, 108.88]; % illuminant D65
end


%%%%%%%%%%%%%%%Viewing Condition Parameters%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LA = 50; % Luminance of the adapting filed in cd/m2
Yb = 20.0; 

if light == 'da'
F = 0.8; % average : 1.0 / dim : 0.9 / dark : 0.8
c = 0.525; % average : 0.69 / dim : 0.59 / dark : 0.525
Nc = 0.8; % average : 1.0 / dim : 0.95 / dark : 0.8

elseif light == 'di'
F = 0.9; % average : 1.0 / dim : 0.9 / dark : 0.8
c = 0.59; % average : 0.69 / dim : 0.59 / dark : 0.525
Nc = 0.95; % average : 1.0 / dim : 0.95 / dark : 0.8

elseif light == 'av'
F = 1.0; % average : 1.0 / dim : 0.9 / dark : 0.8
c = 0.69; % average : 0.69 / dim : 0.59 / dark : 0.525
Nc = 1.0; % average : 1.0 / dim : 0.95 / dark : 0.8
end

k = 1/(5*LA+1);
FL = 0.2*(k^4)*(5*LA)+0.1*((1-k^4)^2)*((5*LA)^(1/3));
n = Yb/white(1,2);
Nbb = 0.725*(1/n)^(0.2);
Ncb = Nbb;
z = 1.48 + sqrt(n);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%Chromatic Adaptation%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%D = F*(1-(1/3.6)*exp((-LA-42)/92));
D = 1;
Mcat02 = [0.7328 0.4296 -0.1624;...
         -0.7036 1.6975 0.0061;...
          0.0030 0.0136 0.9834];   % XYZ to RGB Matrix in CIECAM02

MH = [0.38971 0.68898 -0.07868;...
     -0.22981 1.18340 0.04641;...
      0.00000 0.00000 1.00000];

%%%%%%%%%%%%%% White point Ã³¸® %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
RGBw = white * Mcat02'; %transform from XYZ to RGB of white
Rcw = ((white(1,2)*D/RGBw(1,1))+(1-D))*RGBw(1,1); % Rc of white
Gcw = ((white(1,2)*D/RGBw(1,2))+(1-D))*RGBw(1,2); % Gc of white
Bcw = ((white(1,2)*D/RGBw(1,3))+(1-D))*RGBw(1,3); % Bc of white
RGBcw = [Rcw Gcw Bcw]; % 1 x 3 Matrix of Rcw, Gcw, Bcw
XYZcw = RGBcw*inv(Mcat02)';
RGBpw = XYZcw*MH';% (R', G', B') of white
RGBpaw = ((400*(FL*RGBpw/100).^(0.42))./(27.13+(FL*RGBpw/100).^(0.42))) +0.1;
Aw = (2*RGBpaw(1,1)+RGBpaw(1,2)+(1/20)*RGBpaw(1,3)-0.305)*Nbb;

J = JCh(:,1);
C = JCh(:,2);
h_deg = JCh(:,3);
t = (C./(((J./100).^(0.5)).*(1.64 - 0.29.^n).^0.73)).^(1/0.9);
A = Aw.*((J./100).^(1/(c.*z)));
e = 50000/13*Nc*Ncb*0.25.*(cos(h_deg.*(pi/180)+2)+3.8);

%%%%%%%%%%%%%%% R'a, G'a, B'a %%%%%%%%%%%%%%%%%%%
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

Rpa(:,1) = (460/1403).*((A./Nbb) + 0.305) + (451./1403).* a + (288/1403).* b;
Gpa(:,1) = (460/1403).*((A./Nbb) + 0.305) - (891./1403).* a - (261/1403).* b;
Bpa(:,1) = (460/1403).*((A./Nbb) + 0.305) - (220./1403).* a - (6300/1403).* b;


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

Rp = Rp';
Gp = Gp';
Bp = Bp';



%%%%%%%%%%%%%% Rc, Gc, Bc of input color %%%%%%%%%%%%%%%%%%%%%%%%
Rc = (1.5591525 .* Rp) + ( - 0.544723 .* Gp) + (-0.014445 .* Bp);
Gc = (-0.71432 .* Rp) + (1.85031 .* Gp) + (-0.135976 .* Bp);
Bc = (0.010776 .* Rp) + (0.005219 .* Gp) + (0.984006 .* Bp);

RGBc = [Rc Gc Bc];

%%%%%%%%%%%%%%% R, G, B  of input color %%%%%%%%%%%%%%%%%%%%%%%%%
RGB(:,1) = RGBc(:,1)./((white(1,2)*D/RGBw(1,1))+(1-D));
RGB(:,2) = RGBc(:,2)./((white(1,2)*D/RGBw(1,2))+(1-D));
RGB(:,3) = RGBc(:,3)./((white(1,2)*D/RGBw(1,3))+(1-D));

%%%%%%%%%%%%%%%%% X Y Z of input color %%%%%%%%%%%%%%%%%%%%%%%%%
X = (1.096124 .* RGB(:,1)) + (-0.278869 .* RGB(:,2)) + (0.182745 .* RGB(:,3));
Y = (0.454369 .* RGB(:,1)) + (0.473533 .* RGB(:,2)) + (0.072098 .* RGB(:,3));
Z = (-0.009628 .* RGB(:,1)) + (-0.005698 .* RGB(:,2)) + (1.015326 .* RGB(:,3));

XYZ = [X Y Z];