function [] = CloseImageTexture(options)
% Close the currently active PTB image texture.
%
% Syntax:
%    [] = CloseImageTexture()
%
% Description:
%    This is to close the PTB texture of given image. This would be useful
%    to save the memory when dealing with the high volume test images.
%
% Inputs:
%
% Outputs:
%
% Optional key/value pairs:
%    whichTexture               - Default to empty. Choose which texture to
%                                 close. Otherwise, it'll close every
%                                 active texture.
%    verbose                      Boolean. Default true.  Controls plotting
%                                 and printout.
% See also:
%    MakeImageTexture, FlipImageTexture

% History:
%    09/05/24      smo          - Wrote it.

%% Set variables.
arguments
    options.whichTexture = [];
    options.verbose = true;
end

%% Close the PTB image texture.
if ~isempty(options.whichTexture)
    Screen('Close',options.whichTexture);
    dispMessage = 'Specified PTB textures have been closed';
else
    Screen('CloseAll');
    dispMessage = 'All PTB textures have been closed';
end

if (options.verbose)
    disp(dispMessage);
end
