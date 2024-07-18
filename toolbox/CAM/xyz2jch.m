function JCh = xyz2jch(XYZ,LA,light,white)
% Transformation XYZ to CIECAM02
% input
% XYZ =  X,Y,Z M X 3 Matrix XYZ(:,1) = X, XYZ(:,2) = Y, XYZ(:,3) = Z
% White = XYZ 1 X 3 Matrix of white

if (nargin<4)
  white = [95.05, 100, 108.88]; % illuminant D65
end


[M S] = size(XYZ);
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
Mcat02 = [0.7328 0.4296 -0.1624;...
         -0.7036 1.6975 0.0061;...
          0.0030 0.0136 0.9834];   %XYZ to RGB Matrix for CIECAM02
%D = F*(1-(1/3.6)*exp((-LA-42)/92));
D=1;

RGB = XYZ * Mcat02';% XYZ to RGB
RGBw = white * Mcat02'; % XYZ to RGB of white
Rc = ((white(1,2)*D/RGBw(1,1))+(1-D))*RGB(:,1); % Rc of input color
Gc = ((white(1,2)*D/RGBw(1,2))+(1-D))*RGB(:,2); % Gc of input color
Bc = ((white(1,2)*D/RGBw(1,3))+(1-D))*RGB(:,3); % Bc of input color
RGBc = [Rc Gc Bc]; %M X 3 Matrix

Rcw = ((white(1,2)*D/RGBw(1,1))+(1-D))*RGBw(1,1); % Rc of white
Gcw = ((white(1,2)*D/RGBw(1,2))+(1-D))*RGBw(1,2); % Rc of white
Bcw = ((white(1,2)*D/RGBw(1,3))+(1-D))*RGBw(1,3); % Rc of white
RGBcw = [Rcw Gcw Bcw]; %1 X 3 Matrix of white value

MH = [0.38971 0.68898 -0.07868;...
     -0.22981 1.18340 0.04641;...
      0.00000 0.00000 1.00000];
XYZc = RGBc*inv(Mcat02)';
XYZcw = RGBcw*inv(Mcat02)';
RGBp = XYZc*MH';% R',G', B' 
RGBpw = XYZcw*MH';% R', G',B' of white [R'w, G'w,B'w]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%% Non-Linear Response Compression %%%%%%%%%%%%%%%%%%%%%%%
RGBpa = ((400*(FL*RGBp/100).^(0.42))./(27.13+(FL*RGBp/100).^(0.42))) +0.1; % R' G' B'  to R'a, G'a, B'a of input color
RGBpaw = ((400*(FL*RGBpw/100).^(0.42))./(27.13+(FL*RGBpw/100).^(0.42))) +0.1;% R' G' B'  to R'a, G'a, B'a of white

%%%%%%%%%%%%%% Perceptual Attribute Correlates %%%%%%%%%%%%%%%%%%%%%%%
a = ones(M,1);
b = ones(M,1);
h = ones(M,1);
e = ones(M,1);
t = ones(M,1);

a = RGBpa(:,1)-12*RGBpa(:,2)/11+RGBpa(:,3)/11;
b = (1/9)*(RGBpa(:,1)+RGBpa(:,2)-2*RGBpa(:,3));

for i = 1:M
    if b(i,1) >= 0
        h(i,1) = (360/(2*pi))*atan2(b(i,1),a(i,1));
    else
        h(i,1) = 360+(360/(2*pi))*atan2(b(i,1),a(i,1));
    end
end

e = ((12500/13)*Nc*Ncb)*(cos(h*(pi/180)+2)+3.8);
t = (e.*((a.^2+b.^2).^(0.5)))./(RGBpa(:,1)+RGBpa(:,2)+(21/20)*RGBpa(:,3));


A = (2*RGBpa(:,1)+RGBpa(:,2)+(1/20)*RGBpa(:,3)-0.305)*Nbb;
Aw = (2*RGBpaw(1,1)+RGBpaw(1,2)+(1/20)*RGBpaw(1,3)-0.305)*Nbb;
J = 100*(A/Aw).^(c*z);

C = (t.^(0.9)).*((J/100).^(0.5))*(1.64-0.29^n)^(0.73);
JCh = [J C h];

