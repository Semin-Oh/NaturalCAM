function M_update = GetPrimariesWithSetWhite(xy_primaries, xy_whitepoint)
% Calculating a new XYZ primaries with a desired white point.
%
% Syntax:
%
%
% Description:
%
%
% Inputs:
%    xy_primaries               -
%
% Outputs:
%    xy_whitepoint              -
%
% Optional key/value pairs:
%
% See also:
%
% History:
%    08/07/24    smo            - Wrote it.

%% Set variables.
arguments
    xy_primaries (3,2)
    xy_whitepoint
end

%% Calculation as follows.
%
% xy_primaries is a 3x2 matrix where each row contains [x, y] coordinates
% of the red, green, and blue primaries respectively.
% xy_whitepoint is a 1x2 vector containing [x, y] coordinates of the white point.
%
% Extract xy coordinates of the primaries
x_r = xy_primaries(1,1);
y_r = xy_primaries(1,2);
x_g = xy_primaries(2,1);
y_g = xy_primaries(2,2);
x_b = xy_primaries(3,1);
y_b = xy_primaries(3,2);

% Calculate z coordinates of the primaries
z_r = 1 - x_r - y_r;
z_g = 1 - x_g - y_g;
z_b = 1 - x_b - y_b;

% Extract xy coordinates of the white point
x_w = xy_whitepoint(1);
y_w = xy_whitepoint(2);
z_w = 1 - x_w - y_w;

% Construct the RGB to XYZ conversion matrix
M = [x_r, x_g, x_b; y_r, y_g, y_b; z_r, z_g, z_b];

% Calculate the scaling factors for the white point
S = inv(M) * [x_w / y_w; 1; z_w / y_w];

% Construct the final RGB to XYZ conversion matrix with the scaling factors
M = M * diag(S);

% Output the XYZ coordinates of the primaries
X_r = M(1,1);
Y_r = M(2,1);
Z_r = M(3,1);

X_g = M(1,2);
Y_g = M(2,2);
Z_g = M(3,2);

X_b = M(1,3);
Y_b = M(2,3);
Z_b = M(3,3);

% Store the XYZ values in a 3x3 matrix for output
M_update = [X_r, Y_r, Z_r; X_g, Y_g, Z_g; X_b, Y_b, Z_b];
end
