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
%   02/18/25 smo                - Draft using Magnitude estimation method
%                                 using either gamepad or keyboard. Needs
%                                 to be tested if it works.

%% Set variables.
arguments
    testImage
    window (1,1)
    windowRect (1,4)
    options.testImageSizeRatio (1,1) = 0.4;
    options.expKeyType = 'gamepad';
    options.postKeyPressDelaySec = 0.5;
    options.stepSizeProp = 5;
    options.font = 'DejaVuSans'
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

% Set the string and location on the test image.
text_select = 'select';
texts = [uniqueHues text_select];

% TEXT POSITION WILL BE DECIDED RELATING TO THE LOCATION OF THE PRE-DEFINED
% SQUARE. For now, we are displaying all the texts horizontally.
positionHorz = 150;
positionVert = 50;

% Set the positions of unique hue text.
textPosition_red = [1 positionVert];
textPosition_green = [positionHorz*0.8 positionVert];
textPosition_yellow = [positionHorz*2 positionVert];
textPosition_blue = [positionHorz*3 positionVert];
textPositions_UH = [textPosition_red; textPosition_green; textPosition_yellow; textPosition_blue];

% Set the positions of the marker for each unique hue. We will place it
% right below each unique hue text with another text 'select'.
%
% Set how much we will shift the marker from the texts of unique hue.
shiftPositionVert = 40;

% Copy the text positions and make a shift from it.
textPosition_marker_red = textPosition_red;
textPosition_marker_green = textPosition_green;
textPosition_marker_yellow = textPosition_yellow;
textPosition_marker_blue = textPosition_blue;

textPosition_marker_red(2) = textPosition_marker_red(2) + shiftPositionVert;
textPosition_marker_green(2) = textPosition_marker_green(2) + shiftPositionVert;
textPosition_marker_yellow(2) = textPosition_marker_yellow(2) + shiftPositionVert;
textPosition_marker_blue(2) = textPosition_marker_blue(2) + shiftPositionVert;
textPositions_marker = {textPosition_marker_red textPosition_marker_green textPosition_marker_yellow textPosition_marker_blue};
textPosition_marker_initial = textPositions_marker{1};

% Collect all the positions in a variable.
textPositions = [textPositions_UH; textPosition_marker_initial];

% Add text to the test image for evaluation.
testImageWithText = insertText(testImage,textPositions,texts,...
    'font',options.font,'fontsize',40,'BoxColor',[1 1 1],'BoxOpacity',0,'TextColor','black','AnchorPoint','LeftCenter');

% Display the resized test image.
[testImageTexture testImageWindowRect rng] = MakeImageTexture(testImageWithText, window, resizedWindowRect,'verbose',false);
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
% Set the initial hue to start the evaluation.
idxHue = 1;

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

    % Update the marker on the image. Marker is basically texts, so
    % we update the text and make a new image texture.
    textPosition_marker_updated = textPositions_marker{idxHue};
    textPositions = [textPositions_UH textPosition_marker_updated];
    testImageWithText = insertText(testImage,textPositions,texts,...
        'font',options.font,'fontsize',40,'BoxColor',[1 1 1],'BoxOpacity',0,'TextColor','black','AnchorPoint','LeftCenter');

    % Display the test image with updated texts.
    [testImageTexture testImageWindowRect rng] = MakeImageTexture(testImageWithText, window, resizedWindowRect,'verbose',false);
    FlipImageTexture(testImageTexture,window,windowRect,'verbose',false);

    % Make a tiny time delay every after key press.
    pause(options.postKeyPressDelaySec);
end
selectedHues = uniqueHues{idxHue};

%% Ask if subject wants to add a secondary hue.
%
% Add some more texts to display.
text_secondHue = 'Do you want to add a second hue?';
text_yes = 'yes';
text_no = 'no';
texts = [uniqueHues text_secondHue text_yes text_no text_select];

% Set the text message positions. These are arbitrary positions set for
% now. We will update these once we decide where we display the image on
% the screen.
textPosition_secondHue = textPosition_red;
textPosition_yes = textPosition_red;
textPosition_no = textPosition_green;

% These positions will not be changed during the experiment.
textPosition_secondHue(2) = textPosition_secondHue(2) + shiftPositionVert;
textPosition_yes(2) = textPosition_yes(2) + shiftPositionVert*2;
textPosition_no(2) = textPosition_no(2) + shiftPositionVert*2;
textPositions_question = {textPosition_secondHue textPosition_yes textPosition_no};

% Set the position of the marker and merge all of them.
textPosition_marker_yes = textPosition_yes;
textPosition_marker_no = textPosition_no;
textPosition_marker_yes(2) = textPosition_marker_yes(2) + shiftPositionVert;
textPosition_marker_no(2) = textPosition_marker_no(2) + shiftPositionVert;

textPositions_markerYN = {textPosition_marker_yes textPosition_marker_no};
textPosition_marker_initial = textPositions_markerYN{1};
textPositions = [textPositions_UH textPositions_question textPosition_marker_initial];

% Update the texts on the image.
testImageWithText = insertText(testImage,textPositions,texts,...
    'font',options.font,'fontsize',40,'BoxColor',[1 1 1],'BoxOpacity',0,'TextColor','black','AnchorPoint','LeftCenter');

% Display the test image with updated texts.
[testImageTexture testImageWindowRect rng] = MakeImageTexture(testImageWithText, window, resizedWindowRect,'verbose',false);
FlipImageTexture(testImageTexture,window,windowRect,'verbose',false);

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

    % Right button.
    if strcmp(keyPressed,buttonRight)
        if idxYN < length(idxYNOptions)
            idxYN = idxYN + 1;
        end
        % Left button.
    elseif strcmp(keyPressed,buttonLeft)
        if idxYN > 1
            idxYN = idxYN - 1;
        end
        % Down button.
    elseif strcmp(keyPressed,buttonDown)
        break;

        % Close the PTB. Force quit the experiment.
    elseif strcmp(keyPressed,buttonQuit)
        CloseScreen;
        break;
    else
        % Show a message to press a valid key press.
        fprintf('Press a key either (%s) or (%s) or (%s) or (%s) \n',buttonDown,buttonUp,buttonRight);
    end

    % Update the image with an updated marker position. Again, it should be
    % the same image with different position of the text.
    textPosition_marker_updated = textPositions_markerYN{idxYN};
    textPositions = [uniqueHues textPositions_question textPosition_marker_updated];
    testImageWithText = insertText(testImage,textPositions,texts,...
        'font',options.font,'fontsize',40,'BoxColor',[1 1 1],'BoxOpacity',0,'TextColor','black','AnchorPoint','LeftCenter');

    % Display the test image with updated texts.
    [testImageTexture testImageWindowRect rng] = MakeImageTexture(testImageWithText, window, resizedWindowRect,'verbose',false);
    FlipImageTexture(testImageTexture,window,windowRect,'verbose',false);

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
    idxSecondHue = 1;
    switch selectedHues
        case or('Red','Green')
            secondaryHueOptions = {'Yellow','Blue'};
            textPositions_marker_secondHue = {textPosition_marker_yellow textPosition_marker_blue};
        case or('Yellow','Blue')
            secondaryHueOptions = {'Red','Green'};
            textPositions_marker_secondHue = {textPosition_marker_red textPosition_marker_green};
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
        nSecondHueOptions = length(secondaryHueOptions);
        if strcmp(keyPressed,buttonUp)
            if (idxSecondHue < nSecondHueOptions)
                idxSecondHue = idxSecondHue + 1;
            end
            % Down button.
        elseif strcmp(keyPressed,buttonDown)
            if (idxSecondHue > 1)
                idxSecondHue = idxSecondHue - 1;
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

        % Update the image with an updated marker position. Again, it should be
        % the same image with different position of the text.
        texts = [uniqueHues text_select];
        textPosition_marker_updated = textPositions_marker_secondHue{idxSecondHue};
        textPositions = [textPositions_UH textPosition_marker_updated];
        testImageWithText = insertText(testImage,textPositions,texts,...
            'font',options.font,'fontsize',40,'BoxColor',[1 1 1],'BoxOpacity',0,'TextColor','black','AnchorPoint','LeftCenter');

        % Display the test image with updated texts.
        [testImageTexture testImageWindowRect rng] = MakeImageTexture(testImageWithText, window, resizedWindowRect,'verbose',false);
        FlipImageTexture(testImageTexture,window,windowRect,'verbose',false);

        % Make a tiny time delay every after key press.
        pause(options.postKeyPressDelaySec);
    end

    % Add the chosen secondary hue to the selected hues.
    selectedHues{end+1} = secondaryHueOptions{idxSecondHue};
end

%% AS a final step, evaluate two unique hues in proportion.
%
% This part runs only if the secondary hue was selected.

% Get the index of the selected hues.
idx_selectedHue1 = find(uniqueHues,selectedHues{1});
idx_selectedHue2 = find(uniqueHues,selectedHues{2});

% Set the text positions of the proportions of two unique hues.
textPosition_prob1 = textPositions_UH{idx_selectedHue1};
textPosition_prob2 = textPositions_UH{idx_selectedHue2};

textPosition_prob1(2) = textPosition_prob1(2) + shiftPositionVert;
textPosition_prob2(2) = textPosition_prob2(2) + shiftPositionVert;
textPositions_probs = {textPosition_prob1 textPosition_prob2};

% Evaluation happens in this loop.
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

% Dislpay the test image with an updated proportions. This would look like
% sort of a real time control.
texts = [uniqueHues string(prob1) string(prob2)];
textPositions = [textPositions_UH textPositions_probs];
testImageWithText = insertText(testImage,textPositions,texts,...
    'font',options.font,'fontsize',40,'BoxColor',[1 1 1],'BoxOpacity',0,'TextColor','black','AnchorPoint','LeftCenter');

% Display the test image with updated texts.
[testImageTexture testImageWindowRect rng] = MakeImageTexture(testImageWithText, window, resizedWindowRect,'verbose',false);
FlipImageTexture(testImageTexture,window,windowRect,'verbose',false);

% Convert the evaluation into hue-400 score.
evaluation = computeHueScore(selctedHues,proportions);
end

%% We might want to make this part as a separate function later on.
%
% Convert Hue Selection and Proportions to a Hue 400 Score.
function hueScore = computeHueScore(selectedHues, proportions)

% Assign values to unique hues.
hue_values = struct('Red', 0, 'Yellow', 100, 'Green', 200, 'Blue', 300);

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

% Display the result.
fprintf('Hue 400 Score: %.2f\n', hueScore);
end
