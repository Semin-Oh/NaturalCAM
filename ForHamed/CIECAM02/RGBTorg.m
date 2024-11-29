function rg = RGBTorg(dRGB)
% This routine calculates the small rg coordinates from the digital RGB
% values.

% History:
%    08/13/24    smo   - Wrote it.

%% Initialize.
arguments
    dRGB
end

%% Convert the class to double.
dRGB = double(dRGB);

%% Calculation happens here.
%
% Separate the components across the channels.
dR = dRGB(1,:);
dG = dRGB(2,:);
dB = dRGB(3,:);

% Calculate the rg coordinates here.
sumRGB = dR+dG+dB;
r = dR./sumRGB;
g = dG./sumRGB;

rg = [r; g];
end
