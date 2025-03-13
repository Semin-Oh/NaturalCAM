function hueScore = ComputeHueScore(selectedHues, proportions)
% This routine converts hue selection and proportions to a Hue 400 Score.
%
% Syntax:
%    hueScore = ComputeHueScore(selectedHues, proportions)
%
% Description:
%    This function converts one hue evaluation using magnitude estimation
%    method into 400-hue score. Taking input as either one or two chosen
%    unique hues and their mixed proportions, and ouput as a single integer
%    of 400-hue score.
%
% Inputs:
%    SelectedHues                 - Either one or two uniques hues chosen.
%    proportions                  - Proportions how much mixed between two
%                                   unique hues. It works by passing only
%                                   one value for this if there's only one
%                                   unique hue was passed for
%                                   'SelectedHues'.
%
% Outputs:
%    hueScore                     - A single integer number for 400-hue
%                                   score.
%
% Optional key/value pairs:
%    N/A
%
% See also:
%    GetOneREspMagnitudeEst.m

% History:
%    03/13/25      smo            - Wrote it.

%% Assign values to unique hues.
%
% When, Blue was chosen, set the red numeric as 400 so that it keeps the
% circularity.
if ismember('Blue',selectedHues)
    hue_values = struct('Red', 400, 'Yellow', 100, 'Green', 200, 'Blue', 300);
else
    hue_values = struct('Red', 0, 'Yellow', 100, 'Green', 200, 'Blue', 300);
end

% Convert selected hues to corresponding values
hue_numeric = zeros(1, length(selectedHues));
for i = 1:length(selectedHues)
    hue_numeric(i) = hue_values.(selectedHues{i});
end

% Compute the weighted sum.
hueScore = sum(hue_numeric .* (proportions / 100));

% Ensure circularity: Convert scores above 400 to within 0-400 range.
if hueScore >= 400
    hueScore = hueScore - 400;
end
end
