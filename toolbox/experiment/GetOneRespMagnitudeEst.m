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
%    stepSizeProp               - Step size to control the proportion of
%                                 each unique hue. Default to 5.
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
    options.stepSizeProp = 5;
    options.verbose = true;
end

%% Define unique hues.
uniqueHues = {'Red', 'Green', 'Yellow', 'Blue'};
numUniqueHues = [0 100 200 300 400];
selectedHues = {};

%% Define the image direction and resize it to fit in the screen.
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

% Define the desired size for image placement.
[xCenter, yCenter] = RectCenter(windowRect);
resizedWindowRect = [xCenter - resizedImageWidth/2, yCenter - resizedImageHeight/2, ...
    xCenter + resizedImageWidth/2, yCenter + resizedImageHeight/2];

% Display the resized test image.
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

%% Choose a dominant hue.
%
% Set the initial hue.
idxHue = 1;
initialHue = uniqueHues{idxHue};
selectedHues = initialHue;

% Choose either one hue or another to be mixed.
nUniqueHues = length(uniqueHues);
while true
    % Get a key press here.
    switch options.expKeyType
        case 'gamepad'
            keyPressed = GetJSResp;
        case 'keyboard'
            keyPressed = GetKeyPress;
    end

    % Evaluation happens here.
    %
    % Up button.
    if strcmp(keyPressed,buttonUp)
        if idxHue < nUniqueHues
            idxHue = idxHue + 1;
        end

        % Down button.
    elseif strcmp(keyPressed,buttonDown)
        if idxHue > 2
            idxHue = idxHue - 1;
        end

        % Right button.
    elseif strcmp(keyPressed,buttonRight)
        break;

        % Close the PTB. Force quit the experiment.
    elseif strcmp(keyPressed,buttonQuit)
        CloseScreen;
        break;
    else
        % Show a message to press a valid key press.
        fprintf('Press a key either (%s) or (%s) or (%s) or (%s) \n',buttonDown,buttonUp,buttonRight);
    end

    % Make a tiny time delay every after key press.
    pause(options.postKeyPressDelaySec);
end
selectedHues = uniqueHues{idxHue};

%% Ask if subject wants to add a secondary hue.
%
% THIS PART WILL BE SUBSTITUTED BY DISPLAYING ON THE SCREEN.
fprintf('\nDo you want to add a second hue? (Y/N)\n');

% Answer options to add the secondary hue.
YNOptions = {'yes','no'};
idxYNOptions = [1 2];
idxYN = 1;

while true
    % Get a key press here.
    switch options.expKeyType
        case 'gamepad'
            keyPressed = GetJSResp;
        case 'keyboard'
            keyPressed = GetKeyPress;
    end

    % Up or Down button. Both button updates the secondary hue option.
    if or(strcmp(keyPressed,buttonUp), strcmp(keyPressed,buttonDown))
        idxYN = setdiff(idxYNOptions,idxYN);

        % Right button.
    elseif strcmp(keyPressed,buttonRight)
        break;

        % Close the PTB. Force quit the experiment.
    elseif strcmp(keyPressed,buttonQuit)
        CloseScreen;
        break;
    else
        % Show a message to press a valid key press.
        fprintf('Press a key either (%s) or (%s) or (%s) or (%s) \n',buttonDown,buttonUp,buttonRight);
    end

    % Make a tiny time delay every after key press.
    pause(options.postKeyPressDelaySec);
end

% We set the proportion over using one or two unique hues.
isSecondaryHue = YNOptions{idxYN};
switch isSecondaryHue
    % Two unique hues. Starting 50/50.
    case 'yes'
        prop1 = 50;
        prop2 = 50;
        % Only one unique hue.
    case 'no'
        prop1 = 100;
        prop2 = 0;
end

%% Choose which secondary hue to select.
%
% This part is only running when the secondary hue is mixed.
if strcmp(isSecondaryHue,'yes')

    % Set secondary hue options differently over the dominant hue.
    idxSecondaryHue = 1;
    switch selectedHues
        case or('red','green')
            secondaryHueOptions = {'yellow','blue'};
        case or('yellow','blue')
            secondaryHueOptions = {'red','green'};
    end

    while true
        % Get a key press here.
        switch options.expKeyType
            case 'gamepad'
                keyPressed = GetJSResp;
            case 'keyboard'
                keyPressed = GetKeyPress;
        end

        % Up button.
        nSecondaryHueOptions = length(secondaryHueOptions);
        if strcmp(keyPressed,buttonUp)
            if (idxSecondaryHue < nSecondaryHueOptions)
                idxSecondaryHue = idxSecondaryHue + 1;
            end
            % Down button.
        elseif strcmp(keyPressed,buttonDown)
            if (idxSecondaryHue > 1)
                idxSecondaryHue = idxSecondaryHue - 1;
            end
            % Right button.
        elseif strcmp(keyPressed,buttonRight)
            break;

            % Close the PTB. Force quit the experiment.
        elseif strcmp(keyPressed,buttonQuit)
            CloseScreen;
            break;
        else
            % Show a message to press a valid key press.
            fprintf('Press a key either (%s) or (%s) or (%s) or (%s) \n',buttonDown,buttonUp,buttonRight);
        end

        % Make a tiny time delay every after key press.
        pause(options.postKeyPressDelaySec);
    end

    % Add the chosen secondary hue to the selected hues.
    selctedHues{end+1} = secondaryHueOptions{idxSecondaryHue};
end

%% If the secondary hue was chosen, evaluate it in ratio.
%
% This part also only runs when the secondary hue was selected.
if strcmp(isSecondaryHue,'yes')

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
            if prop1 < 100
                prop1 = prop1 + options.stepSizeProp;
            end
        elseif strcmp(keyPressed,buttonDown)
            if prop1 > 0
                prop1 = prop1 - options.stepSizeProp;
            end
        elseif strcmp(keyPressed,buttonRight)
            break;

            % Close the PTB. Force quit the experiment.
        elseif strcmp(keyPressed,buttonQuit)
            CloseScreen;
            break;
        else
            % Show a message to press a valid key press.
            fprintf('Press a key either (%s) or (%s) or (%s) or (%s) \n',buttonDown,buttonUp,buttonRight,buttonLeft);
        end

        % Set the proportion of the dominant hue in the right range.
        if prop1 > 100
            prop1 = 100;
        elseif prop1 < 0
            prop1 = 0;
        end

        % Set the proportion of the secondary hue.
        prop2 = 100 - prop1;

        % Make a tiny time delay every after key press.
        pause(options.postKeyPressDelaySec);
    end
end

% Sanity check.
proportions = [prop1 prop2];
sumProps = sum(proportions);
if ~(sumProps == 100)
    error('The sum of the proportion does not make sense!')
end

% Convert the evaluation into hue-400 score.
evaluation = computeHueScore(selctedHues,proportions);
end

%% We might want to make this part as a separate function later on.
%
% Convert Hue Selection and Proportions to a Hue 400 Score
function hueScore = computeHueScore(selectedHues, proportions)
% Assign values to unique hues
hue_values = struct('Red', 0, 'Yellow', 100, 'Green', 200, 'Blue', 300);

% Convert selected hues to corresponding values
hue_numeric = zeros(1, length(selectedHues));
for i = 1:length(selectedHues)
    hue_numeric(i) = hue_values.(selectedHues{i});
end

% Compute the weighted sum
hueScore = sum(hue_numeric .* (proportions / 100));

% Ensure circularity: Convert scores above 400 to within 0-400 range
if hueScore >= 400
    hueScore = hueScore - 400;
end

% Display the result
fprintf('Hue 400 Score: %.2f\n', hueScore);
end
