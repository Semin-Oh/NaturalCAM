function [evaluation] = GetOneRespMagnitudeEst(testImage,window,windowRect,options)
% This routine does one evaulation using Magnitude Estimation method.
% This is written for the NCAM DNN project.
%
% Syntax:
%    [evaluation] = GetOneRespMagnitudeEst(images,idxImage,intensityColorCorrect,idxColorCorrectImage,nTestPoints, ...
%    window,windowRect)
%
% Description:
%    dd
%
% Inputs:
%    testImage                  -
%    window
%    windowRect
%
% Outputs:
%    evaluation                 - Raw data of the evaluation using the
%                                 magnitude estimation method. This should
%                                 be a single integer value.
%
% Optional key/value pairs:
%    testImageSizeRatio         - Ratio of the test image size to the
%                                 resolution of the display. It's based on
%                                 the width of the resolution. For example,
%                                 if this is set to 0.5, the test image
%                                 will be placed within the 50% size of the
%                                 display resolution.
%    expKeyType                 - Method to collect the evaluation. Choose
%                                 either 'keyboard' or 'gamepad'.
%    postKeyPressDelaySec       - Time delay in sec every after pressing
%                                 the key.
%    verbose                    - Boolean. Default true. Controls
%                                 printout.
%
% See also:
%    NCAM_RunExperiment.

% History:
%   02/17/25 smo                - Wrote it.

%% Set variables.
arguments
    testImage
    window (1,1)
    windowRect (1,4)
    options.testImageSizeRatio (1,1) = 0.4;     
    options.expKeyType = 'gamepad';
    options.postKeyPressDelaySec = 0.5;
    options.verbose = true;
end

%% Color matching experiment happens here.
%
% Define the image direction.
testImageSize = size(testImage);
imageHeight = testImageSize(1);
imageWidth = testImageSize(2);
imageHeightToWidthRatio = imageHeight/imageWidth;
if imageHeightToWidthRatio == 1
    imageType = 'square';
elseif imageHeightToWidthRatio < 1
    imageType = 'landscape';
elseif imageHeightToWidthRatio > 1
    imageType = 'portrait';
end

% Set the desired image size. We set it differently over the direction of
% the test image.
displayResolutionWidth = windowRect(3);
predefinedImageSquareSize = displayResolutionWidth * options.testImageSizeRatio;
switch imageType
    case 'landscape'
        resizedImageWidth = predefinedImageSquareSize;
        resizedImageHeight = resizedImageWidth * imageHeightToWidthRatio;
    case 'portrait'
        resizedImageHeight = predefinedImageSquareSize;
        resizedImageWidth = resizedImageHeight * 1/imageHeightToWidthRatio;
    otherwise
        resizedImageHeight = predefinedImageSquareSize;
        resizedImageWidth = predefinedImageSquareSize;
end

% Define the destination rectangle for image placement.
[xCenter, yCenter] = RectCenter(windowRect);
resizedWindowRect = [xCenter - resizedImageWidth/2, yCenter - resizedImageHeight/2, ...
    xCenter + resizedImageWidth/2, yCenter + resizedImageHeight/2];

% Display the test image.
[testImageTexture testImageWindowRect rng] = MakeImageTexture(testImage, window, resizedWindowRect,'verbose',false);
FlipImageTexture(testImageTexture,window,windowRect,'verbose',false);

% Close the other textures except the one currently on. For now, we
% randonly create an array of the textures with the number from 1 to 100,
% which should generally cover all the texture numbers. The PTB texture
% number usually starts with 11,12,13,..., so theoritically it would close
% all the active textures except the one displaying now.
texturesToClose = linspace(1,100,100);
texturesToClose = setdiff(texturesToClose,testImageTexture);
CloseImageTexture('whichTexture',texturesToClose);

%% Set the available key options here over different key type either
% keyboard or gamepad.
switch options.expKeyType
    case 'gamepad'
        buttonDown = 'down';
        buttonUp = 'up';
        buttonLeft = 'left';
        buttonRight = 'right';
        buttonReset = 'sideright';
        % buttonStepSize = '';
        buttonQuit = 'sideleft';

    case 'keyboard'
        buttonDown = 'DownArrow';
        buttonUp = 'UpArrow';
        buttonLeft = 'LeftArrow';
        buttonRight = 'RightArrow';
        buttonReset = 'r';
        buttonStepSize = 's';
        buttonQuit = 'q';
end

%% This block completes a one evaluation. Get a key press.
while true
    % Get a key press here.
    switch options.expKeyType
        case 'gamepad'
            keyPressed = GetJSResp;
        case 'keyboard'
            keyPressed = GetKeyPress;
    end
    
    % Evaluation happens here.
    if strcmp(keyPressed,buttonUp)
    
    elseif strcmp(keyPressed,buttonDown)

    elseif strcmp(keyPressed,buttonRight)

    elseif strcmp(keyPressed,buttonLeft)

    elseif strcmp(keyPressed,buttonReset)

        % Close the PTB. Force quit the experiment.
    elseif strcmp(keyPressed,buttonQuit)
        CloseScreen;
        break;
    else
        % Show a message to press a valid key press.
        fprintf('Press a key either (%s) or (%s) or (%s) or (%s) \n',buttonDown,buttonUp,buttonRight,buttonLeft);
    end

    % Make a tiny time delay every after key press.
    pause(options.postKeyPressDelaySec);
end

% Collect the key press data here.
evaluation = intensityColorCorrect(idxColorCorrectImage);
end
