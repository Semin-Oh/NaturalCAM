function [matchingIntensity] = GetOneRespMagnitudeEst(testImages,idxImage,idxColorCorrectImage,intensityColorCorrect, ...
    window,windowRect,options)
% This routine does one evaulation using Magnitude Estimation method.
%
% Syntax:
%    [matchingIntensity] = GetOneRespMagnitudeEst(images,idxImage,intensityColorCorrect,idxColorCorrectImage,nTestPoints, ...
%    window,windowRect)
%
% Description:
%    dd
%
% Inputs:
%    testImages                 -
%    idxImage
%    idxColorCorrectImage
%    intensityColorCorrect
%    window
%    windowRect
%
% Outputs:
%    matchingIntensity          - dd
%
% Optional key/value pairs:
%    imageFixationType
%    expKeyType
%    postColorCorrectDelaySec
%    verbose                    - Boolean. Default true. Controls
%                                 printout.
%
% See also:
%    NCAM_RunExperiment.

% History:
%   02/17/25 smo                - Wrote it.

%% Set variables.
arguments
    testImages
    idxImage (1,1)
    idxColorCorrectImage (1,1)
    intensityColorCorrect
    window (1,1)
    windowRect (1,4)
    options.imageFixationType = 'filled-circle';
    options.expKeyType = 'gamepad';
    options.postColorCorrectDelaySec = 0.5;
    options.verbose = true;
end
nColorCorrectPoints = length(intensityColorCorrect);

%% Color matching experiment happens here.
%
% Display the test image.
testImage = testImages{idxImage,idxColorCorrectImage};
[testImageTexture testImageWindowRect rng] = MakeImageTexture(testImage, window, windowRect,...
    'addFixationPointImage',options.imageFixationType,'verbose',false);
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
        buttonDecide = 'right';
        buttonQuit = 'sideleft';
    case 'keyboard'
        buttonDown = 'LeftArrow';
        buttonUp = 'RightArrow';
        buttonDecide = 'DownArrow';
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

    % Finish the evalution.
    if strcmp(keyPressed,buttonDecide)
        fprintf('A key pressed = (%s) \n',keyPressed);
        break;

        % Update the test image with less color correction.
    elseif strcmp(keyPressed,buttonDown)
        idxColorCorrectImage = idxColorCorrectImage - 1;

        % Set the index within the feasible range.
        if idxColorCorrectImage < 1
            idxColorCorrectImage = 1;
        elseif idxColorCorrectImage > nColorCorrectPoints
            idxColorCorrectImage = nColorCorrectPoints;
        end

        % Update the image here.
        testImage = testImages{idxImage,idxColorCorrectImage};
        [testImageTexture testImageWindowRect rng] = MakeImageTexture(testImage, window, windowRect,...
            'addFixationPointImage',options.imageFixationType,'verbose', false);
        FlipImageTexture(testImageTexture, window, windowRect,'verbose',false);
        fprintf('Test image is now displaying: Color correct level (%d/%d) \n',idxColorCorrectImage,nColorCorrectPoints);

        % Close the other textures.
        texturesToClose = setdiff(texturesToClose,testImageTexture);
        CloseImageTexture('whichTexture',texturesToClose);

        % Update the test image with stronger color correction.
    elseif strcmp(keyPressed,buttonUp)
        idxColorCorrectImage = idxColorCorrectImage + 1;

        % Set the index within the feasible range.
        if idxColorCorrectImage < 1
            idxColorCorrectImage = 1;
        elseif idxColorCorrectImage > nColorCorrectPoints
            idxColorCorrectImage = nColorCorrectPoints;
        end

        % Update the image here.
        testImage = testImages{idxImage,idxColorCorrectImage};
        [testImageTexture testImageWindowRect rng] = MakeImageTexture(testImage, window, windowRect,'addFixationPointImage',options.imageFixationType,'verbose', false);
        FlipImageTexture(testImageTexture, window, windowRect,'verbose',false);
        fprintf('Test image is now displaying: Color correct level (%d/%d) \n',idxColorCorrectImage,nColorCorrectPoints);

        % Close the other textures.
        texturesToClose = setdiff(texturesToClose,testImageTexture);
        CloseImageTexture('whichTexture',texturesToClose);

    elseif strcmp(keyPressed,buttonQuit)
        % Close the PTB. Force quit the experiment.
        CloseScreen;
        break;
    else
        % Show a message to press a valid key press.
        fprintf('Press a key either (%s) or (%s) or (%s) \n',buttonDown,buttonUp,buttonDecide);
    end

    % Make a tiny time delay here so that we make sure we color
    % match in a unit step size. Without time delay, the color
    % matching would be executed in more than one step size if
    % we press the button too long.
    pause(options.postColorCorrectDelaySec);
end

% Collect the key press data here.
matchingIntensity = intensityColorCorrect(idxColorCorrectImage);
end
