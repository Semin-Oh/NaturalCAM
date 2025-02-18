function [chromaticity_shiftedImage] = MakeImageShiftChromaticity(chromaticity_image,chromaticity_target,intensityColorCorrect,options)
% This makes proportional chromaticity shift of image.
%
% Syntax:
%    [chromaticity_shiftedImage] = MakeImageShiftChromaticity(chromaticity_image,chromaticity_target,intensityColorCorrect)
%
% Description:
%    This routine is written for the project of Color assimilation. We made
%    this as a routine so that we can use the same method when we generate
%    the color shifted images. Especially, when we generate an image
%    profile based on the experiment. We will use this routine for both
%    making test images and also analyzing the data.
%
% Inputs:
%    chromaticity_image       - Image profile on chromaticity coordinates.
%                               It should work for any color space (CIE xy,
%                               u'v' etc). It's important that the color
%                               space should be the same as the one using
%                               for the target.
%    chromaticity_target      - Target chromaticity to shift the image.
%    intensityColorCorrect    - Ratio to shift toward the target
%                               chromaticity. Should be a single number
%                               from 0 to 1. The number 0 would make no
%                               shift and 1 make the whole chromaticity
%                               shifted to the target.
%
% Outputs:
%    uv_shiftedImage          - Chromaticity coordinates of the shifted
%                               image.
%
% Optional key/value pairs:
%    verbose                  - Control the plot and alarm messages.
%                               Default to false.
%
% See also:
%    MakeImageCanvas.

% History:
%    10/29/24    smo          - Wrote it.

%% Set variables.
arguments
    chromaticity_image
    chromaticity_target (2,1)
    intensityColorCorrect (1,1)
    options.verbose (1,1) = false
end

%% Image shift happens here.
chromaticity_shiftedImage(1:2,:) = chromaticity_image(1:2,:) + intensityColorCorrect * (chromaticity_target - chromaticity_image(1:2,:));

end
