function [evaluation] = GetOneRespMagnitudeEst(testImage,testImageArrow,window,windowRect,options)
% This routine does one evaulation using Magnitude Estimation method.
% This is written for the NCAM DNN project.
%
% Syntax:
%    [evaluation] = GetOneRespMagnitudeEst(images,idxImage,intensityColorCorrect,idxColorCorrectImage,nTestPoints, ...
%    window,windowRect)
%
% Description:
%    This function is used for hue evaluation using Magnitude Estimation
%    method. Inside the routine, a test image will be displayed with an
%    arrow flashing within the image, and getting one evaluation in hue for
%    the object. This could be modified for further experiment evaluating
%    brightness, chroma, etc.
%
% Inputs:
%    testImage                  - Test image for evaluation.
%    testImageArrow             - Test image with arrow on it indiciating
%                                 an object for evaluation
%    window                     - PTB window number.
%    windowRect                 - PTB window resolution.
%
% Outputs:
%    evaluation                 - Raw data of the evaluation using the
%                                 magnitude estimation method. This should
%                                 be a single integer value. For now, it's
%                                 hue 400 score.
%
% Optional key/value pairs:
%    testImageSizeRatio         - Ratio of the test image size to the
%                                 resolution of the display. It's based on
%                                 the height of the resolution. For example,
%                                 if this is set to 0.5, the test image
%                                 will be placed within the 50% size of the
%                                 display resolution. Default to 0.9.
%    secIntvFlashingArrow       - Time of an arrow staying per flash.
%                                 Default to 0.4 (sec).
%    nArrowFlashes              - The number of repetitions of an arrow
%                                 indicating an object to evaluate. Default
%                                 to 3.
%    expKeyType                 - Method to collect the evaluation. Choose
%                                 either 'keyboard' or 'gamepad'.
%    postKeyPressDelaySec       - Time delay in sec every after pressing
%                                 the key.
%    postKeyPressDelayPropSec   - Time delay in sec every after a key press
%                                 for evaluation of the proportion of two
%                                 hues. This is shorter than the above one
%                                 so that the evaluation could be done
%                                 efficiently.
%    stepSizeProp               - Step size to control the proportion of
%                                 each unique hue. Default to 5.
%    font                       - Font type to display some texts on the
%                                 screen. Default to DejaVuSans.
%    fontSize                   - Font size of the texts displaying on the
%                                 screen. Default to 25.
%    verbose                    - Boolean. Default true. Controls
%                                 printout.
%
% See also:
%    NCAM_RunExperiment.

% History:
%    02/17/25 smo               - Wrote it.
%    02/18/25 smo               - Draft using Magnitude estimation method
%                                 using either gamepad or keyboard. Needs
%                                 to be tested if it works.
%    03/05/25 smo               - Added the part adding arrow to indicate
%                                 an object for evaluation.
%    03/11/25 smo               - Now we only use the image with its actual
%                                 image contents by excluding the
%                                 background. Also, now we set the
%                                 pre-defined square to put the image based
%                                 on the display height of the display
%                                 resolution, which seems making more
%                                 sense.
%    03/14/25 smo               - Now we make two pre-defined square on the
%                                 screen, one being the background as the
%                                 size of the display resolution, and put a
%                                 smaller square inside the square to put
%                                 the actual image content in. This way, we
%                                 can avoid the overlapping between the
%                                 image and the texts. 
%    03/19/25 smo               - After meeting with Karl, the 'select'
%                                 text has been substituted with dashed
%                                 lines.
%    03/21/25 smo               - Now, screen is down by pressing 'back'
%                                 button on the gamepad.

%% Set variables.
arguments
    testImage
    testImageArrow
    window (1,1)
    windowRect (1,4)
    options.testImageSizeHeightRatio (1,1) = 0.9;
    options.secIntvFlashingArrow (1,1) = 0.4;
    options.nArrowFlashes (1,1) = 3;
    options.expKeyType = 'gamepad';
    options.postKeyPressDelaySec = 0.15;
    options.postKeyPressDelayPropSec = 0.05;
    options.stepSizeProp = 1;
    options.font = 'DejaVuSans'
    options.fontSize = 25;
    options.verbose = true;
end

% Define unique hues.
uniqueHues = {'Red', 'Green', 'Yellow', 'Blue'};
numUniqueHues = [0 100 200 300 400];
selectedHues = {};

% Set the available key options here over different key type either
% keyboard or gamepad.
switch options.expKeyType
    case 'gamepad'
        buttonDown = 'down';
        buttonUp = 'up';
        buttonLeft = 'left';
        buttonRight = 'right';
        buttonQuit = 'back';

    case 'keyboard'
        buttonDown = 'DownArrow';
        buttonUp = 'UpArrow';
        buttonLeft = 'LeftArrow';
        buttonRight = 'RightArrow';
        buttonQuit = 'q';
end

%% First, find the actual image content within the input image.
%
% CoCo image dataset makes every image in the same resolution by filling
% the background in black. We want to keep the resolution as the original
% image, so here we extract the area where the actual images are lying.
testImage = FindImageContent(testImage,'verbose',false);
testImageArrow = FindImageContent(testImageArrow,'verbose',false);

% Sanity check.
if ~isequal(size(testImage),size(testImageArrow))
    error('Image resolution mismatch between raw image and arrow image!');
end

%% Resize the test image over its direction.
testImageSize = size(testImage);
testImageHeight = testImageSize(1);
testImageWidth = testImageSize(2);
imageHeightToWidthRatio = testImageHeight/testImageWidth;
if imageHeightToWidthRatio == 1
    imageType = 'square';
elseif imageHeightToWidthRatio < 1
    imageType = 'landscape';
elseif imageHeightToWidthRatio > 1
    imageType = 'portrait';
end

%% Resize the test image to fit in the screen.
%
% The idea here is that we make a pre-defined square in the size of display
% resolution width, then set a smaller square to put the actual image
% content in it. We will put the text on the background outside the image
% content. This way, we can avoid overapping between the image and the text
% while presenting them at the same time. Could be elaborated later, but
% should be good for now.

% Get the display size.
displayResolutionWidth = windowRect(3);
displayResolutionHeight = windowRect(4);

% Set the size of pre-defined square to put the image in. The BG is a
% bigger background, and the BGImage will contain the actual image content.
sizeBG = displayResolutionHeight;
sizeBGImage = displayResolutionHeight * options.testImageSizeHeightRatio;
switch imageType
    case 'landscape'
        resizedImageWidth = sizeBGImage;
        resizedImageHeight = round(resizedImageWidth * imageHeightToWidthRatio);
    case 'portrait'
        resizedImageHeight = sizeBGImage;
        resizedImageWidth = round(resizedImageHeight * 1/imageHeightToWidthRatio);
    otherwise
        resizedImageHeight = sizeBGImage;
        resizedImageWidth = sizeBGImage;
end

% Define the desired size for image placement.
bGImage = zeros(sizeBG,sizeBG,3,'uint8');

% Resize the test images.
testImageResized = imresize(testImage, [resizedImageHeight resizedImageWidth]);
testImageArrowResized = imresize(testImageArrow, [resizedImageHeight resizedImageWidth]);

% Define the pixel position to center the test image.
testImageResizedOnBG = bGImage;
testImageArrowResizedOnBG = bGImage;

% Set the vertical position of the test image.
pixelStart_height = sizeBG/2 - resizedImageHeight/2;
pixelEnd_height = pixelStart_height + resizedImageHeight-1;

% Set the horizontal position of the test image.
pixelStart_width = sizeBG/2 - resizedImageWidth/2;
pixelEnd_width = pixelStart_width + resizedImageWidth-1;

% Place images on the background.
testImageResizedOnBG(pixelStart_height:pixelEnd_height, pixelStart_width:pixelEnd_width, :) = testImageResized;
testImageArrowResizedOnBG(pixelStart_height:pixelEnd_height, pixelStart_width:pixelEnd_width, :) = testImageArrowResized;

%% Here, flashing an arrow to indicate an object to evaluate.
%
% Test image.
[testImageTexture testImageWindowRect rng] = MakeImageTexture(testImageResizedOnBG, window, windowRect,'verbose',false);
% Test image with an arrow.
[testImageArrowTexture testImageWindowRect rng] = MakeImageTexture(testImageArrowResizedOnBG, window, windowRect,'verbose',false);

% Flip the test image one another to make an effect of flashing arrow.
for ff = 1:options.nArrowFlashes
    % Test image.
    FlipImageTexture(testImageTexture,window,testImageWindowRect,'verbose',false);
    pause(options.secIntvFlashingArrow);
    % Test image with arrow.
    FlipImageTexture(testImageArrowTexture,window,testImageWindowRect,'verbose',false);
    pause(options.secIntvFlashingArrow);
end

%% Display a test image with unique hues in text.
%
% We will display four unique hues in letters so that subjects evaluate the
% hue of the objects.
%
% Set the string and location on the test image.
text_select_hue = '   ^';
text_select_YN = '  ^';
texts = [uniqueHues text_select_hue];

% TEXT POSITION WILL BE DECIDED RELATING TO THE LOCATION OF THE PRE-DEFINED
% SQUARE. For now, we are displaying all the texts horizontally.
positionHorz = sizeBG/2;
positionVert = sizeBG*0.05;
positionHorzGap = sizeBG*0.08;

% Set the positions of unique hue text.
textPosition_red = [positionHorz positionVert];
textPosition_green = [positionHorz + positionHorzGap positionVert];
textPosition_yellow = [positionHorz + positionHorzGap*2 positionVert];
textPosition_blue = [positionHorz + positionHorzGap*3 positionVert];
textPositions_UH = [textPosition_red; textPosition_green; textPosition_yellow; textPosition_blue];

% Set the positions of the marker for each unique hue. We will place it
% right below each unique hue text with another text 'select'.
%
% Set how much we will shift the marker from the texts of unique hue.
shiftPositionVert = sizeBG*0.03;

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
testImageWithText = insertText(testImageResizedOnBG,textPositions,texts,...
    'font',options.font,'fontsize',options.fontSize,'BoxColor',[1 1 1],'BoxOpacity',0,'TextColor','white','AnchorPoint','LeftCenter');

% Display the resized test image.
[testImageTexture testImageWindowRect rng] = MakeImageTexture(testImageWithText, window, windowRect,'verbose',false);
FlipImageTexture(testImageTexture,window,testImageWindowRect,'verbose',false);

% Close the other textures except the one currently on. For now, we
% randonly create an array of the textures with the number from 1 to 100,
% which should generally cover all the texture numbers. The PTB texture
% number usually starts with 11,12,13,..., so theoritically it would close
% all the active textures except the one displaying now.
texturesToClose = linspace(1,100,100);
texturesToClose = setdiff(texturesToClose,testImageTexture);
CloseImageTexture('whichTexture',texturesToClose);

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
    % Right button.
    if strcmp(keyPressed,buttonRight)
        if idxHue < nUniqueHues
            idxHue = idxHue + 1;
        end

        % Left button.
    elseif strcmp(keyPressed,buttonLeft)
        if idxHue >= 2
            idxHue = idxHue - 1;
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

    % Update the marker on the image. Marker is basically texts, so
    % we update the text and make a new image texture.
    textPosition_marker_updated = textPositions_marker{idxHue};
    textPositions = [textPositions_UH; textPosition_marker_updated];
    testImageWithText = insertText(testImageResizedOnBG,textPositions,texts,...
        'font',options.font,'fontsize',options.fontSize,'BoxColor',[1 1 1],'BoxOpacity',0,'TextColor','white','AnchorPoint','LeftCenter');

    % Display the test image with updated texts.
    [testImageTexture testImageWindowRect rng] = MakeImageTexture(testImageWithText, window, windowRect,'verbose',false);
    FlipImageTexture(testImageTexture,window,testImageWindowRect,'verbose',false);

    % Make a tiny time delay every after key press.
    pause(options.postKeyPressDelaySec);
end
selectedHues = uniqueHues(idxHue);

% Make a delay between the selection.
secDelayBTWQuestions = 0.5;
pause(secDelayBTWQuestions);

%% Ask if subject wants to add a secondary hue.
%
% Add some more texts to display.
text_secondHue = 'Do you want to add a secondary hue?';
text_yes = 'yes';
text_no = 'no';
texts = [uniqueHues text_secondHue text_yes text_no text_select_YN];

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
textPositions_question = [textPosition_secondHue; textPosition_yes; textPosition_no];

% Set the position of the marker and merge all of them.
textPosition_marker_yes = textPosition_yes;
textPosition_marker_no = textPosition_no;
textPosition_marker_yes(2) = textPosition_marker_yes(2) + shiftPositionVert;
textPosition_marker_no(2) = textPosition_marker_no(2) + shiftPositionVert;

textPositions_markerYN = {textPosition_marker_yes textPosition_marker_no};
textPosition_marker_initial_YN = textPositions_markerYN{1};
textPositions = [textPositions_UH; textPositions_question; textPosition_marker_initial_YN];

% Update the texts on the image.
testImageWithText = insertText(testImageResizedOnBG,textPositions,texts,...
    'font',options.font,'fontsize',options.fontSize,'BoxColor',[1 1 1],'BoxOpacity',0,'TextColor','white','AnchorPoint','LeftCenter');

% Display the test image with updated texts.
[testImageTexture testImageWindowRect rng] = MakeImageTexture(testImageWithText, window, windowRect,'verbose',false);
FlipImageTexture(testImageTexture,window,testImageWindowRect,'verbose',false);

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
        if idxYN >= 2
            idxYN = idxYN - 1;
        end
        % Down button.isSecondaryHue = YNOptions{idxYN};
    elseif strcmp(keyPressed,buttonDown)
        break;

        % Close the PTB. Force quit the experiment.
    elseif strcmp(keyPressed,buttonQuit)
        CloseScreen;
        break;
    else
        % Show a message to press a valid key press.
        fprintf('Press a key either (%s) or (%s) or (%s) or (%s) \n',buttonLeft,buttonRight,buttonDown);
    end

    % Update the image with an updated marker position. Again, it should be
    % the same image with different position of the text.
    textPosition_marker_updated = textPositions_markerYN{idxYN};
    textPositions = [textPositions_UH; textPositions_question; textPosition_marker_updated];
    testImageWithText = insertText(testImageResizedOnBG,textPositions,texts,...
        'font',options.font,'fontsize',options.fontSize,'BoxColor',[1 1 1],'BoxOpacity',0,'TextColor','white','AnchorPoint','LeftCenter');

    % Display the test image with updated texts.
    [testImageTexture testImageWindowRect rng] = MakeImageTexture(testImageWithText, window, windowRect,'verbose',false);
    FlipImageTexture(testImageTexture,window,testImageWindowRect,'verbose',false);

    % Make a tiny time delay every after key press.
    pause(options.postKeyPressDelaySec);
end

% We set the proportion over using one or two unique hues.
isSecondaryHue = YNOptions{idxYN};
switch isSecondaryHue
    % Two unique hues. Starting 100/0. This way is more intuitive than
    % starting from 50/50.
    case 'yes'
        prop1 = 100;
        prop2 = 0;
        % Only one unique hue.
    case 'no'
        prop1 = 100;
        prop2 = 0;
end
proportions = [prop1 prop2];

% Make a delay between the selection.
pause(secDelayBTWQuestions);

%% Choose which secondary hue to select.
%
% This part is only running when the secondary hue is mixed.
if strcmp(isSecondaryHue,'yes')

    % From here, evaluate the secondary hue.
    idxSecondHue = 1;

    % When either red or green was chosen as a dominant hue.
    if ismember(selectedHues,{'Red','Green'})
        secondaryHueOptions = {'Yellow','Blue'};
        textPositions_marker_secondHue = {textPosition_marker_yellow textPosition_marker_blue};
        % Otherwise, it should be either yellow or blue was chosen.
    else
        secondaryHueOptions = {'Red','Green'};
        textPositions_marker_secondHue = {textPosition_marker_red textPosition_marker_green};
    end

    % First, display the initial hue selection screen again.
    texts = [uniqueHues text_select_hue];
    textPosition_marker_initial_SH = textPositions_marker_secondHue{1};
    textPositions = [textPositions_UH; textPosition_marker_initial_SH];
    testImageWithText = insertText(testImageResizedOnBG,textPositions,texts,...
        'font',options.font,'fontsize',options.fontSize,'BoxColor',[1 1 1],'BoxOpacity',0,'TextColor','white','AnchorPoint','LeftCenter');

    % Flip the screen.
    [testImageTexture testImageWindowRect rng] = MakeImageTexture(testImageWithText, window, windowRect,'verbose',false);
    FlipImageTexture(testImageTexture,window,testImageWindowRect,'verbose',false);

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
        if strcmp(keyPressed,buttonRight)
            if (idxSecondHue < nSecondHueOptions)
                idxSecondHue = idxSecondHue + 1;
            end
            % Down button.
        elseif strcmp(keyPressed,buttonLeft)
            if (idxSecondHue > 1)
                idxSecondHue = idxSecondHue - 1;
            end
            % Right button.
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
        texts = [uniqueHues text_select_hue];
        textPosition_marker_updated = textPositions_marker_secondHue{idxSecondHue};
        textPositions = [textPositions_UH; textPosition_marker_updated];
        testImageWithText = insertText(testImageResizedOnBG,textPositions,texts,...
            'font',options.font,'fontsize',options.fontSize,'BoxColor',[1 1 1],'BoxOpacity',0,'TextColor','white','AnchorPoint','LeftCenter');

        % Display the test image with updated texts.
        [testImageTexture testImageWindowRect rng] = MakeImageTexture(testImageWithText, window, windowRect,'verbose',false);
        FlipImageTexture(testImageTexture,window,testImageWindowRect,'verbose',false);

        % Make a tiny time delay every after key press.
        pause(options.postKeyPressDelaySec);
    end

    % Add the chosen secondary hue to the selected hues.
    selectedHues{end+1} = secondaryHueOptions{idxSecondHue};
end

% Make a delay between the selection.
pause(secDelayBTWQuestions);

%% AS a final step, evaluate two unique hues in proportion.
if strcmp(isSecondaryHue,'yes')

    % Get the index of the selected hues. This part runs only if the secondary
    % hue was selected.
    idx_selectedHue1 = find(strcmp(uniqueHues,selectedHues{1}));
    idx_selectedHue2 = find(strcmp(uniqueHues,selectedHues{2}));

    % Set the text positions of the proportions of two unique hues.
    textPosition_prob1 = textPositions_UH(idx_selectedHue1,:);
    textPosition_prob2 = textPositions_UH(idx_selectedHue2,:);

    textPosition_prob1(2) = textPosition_prob1(2) + shiftPositionVert;
    textPosition_prob2(2) = textPosition_prob2(2) + shiftPositionVert;
    textPositions_probs = [textPosition_prob1; textPosition_prob2];

    % First, display the initial hue selection screen with probs.
    texts = [uniqueHues num2str(prop1) num2str(prop2)];
    textPositions = [textPositions_UH; textPositions_probs];
    testImageWithText = insertText(testImageResizedOnBG,textPositions,texts,...
        'font',options.font,'fontsize',options.fontSize,'BoxColor',[1 1 1],'BoxOpacity',0,'TextColor','white','AnchorPoint','LeftCenter');

    % Flip the screen.
    [testImageTexture testImageWindowRect rng] = MakeImageTexture(testImageWithText, window, windowRect,'verbose',false);
    FlipImageTexture(testImageTexture,window,testImageWindowRect,'verbose',false);

    % Evaluation happens in this loop.
    while true
        % Get a key press here.
        switch options.expKeyType
            case 'gamepad'
                keyPressed = GetJSResp;
            case 'keyboard'
                keyPressed = GetKeyPress;
        end

        % Evaluation happens here.
        dominantHueSelected = selectedHues{1};
        % Right button.
        if strcmp(keyPressed,buttonRight)
            % When the dominant hue was either red or green.
            if or(strcmp(dominantHueSelected,'Red'),strcmp(dominantHueSelected,'Green'))
                if prop1 > 0
                    prop1 = prop1 - options.stepSizeProp;
                end
            else
                % For the dominant hue is either yellow or blue.
                if prop1 < 100
                    prop1 = prop1 + options.stepSizeProp;
                end
            end

            % Left button.
        elseif strcmp(keyPressed,buttonLeft)
            % When the dominant hue was either yellow or blue.
            if or(strcmp(dominantHueSelected,'Yellow'),strcmp(dominantHueSelected,'Blue'))
                if prop1 > 0
                    prop1 = prop1 - options.stepSizeProp;
                end
            else
                % For the dominant hue is either red or green.
                if prop1 < 100
                    prop1 = prop1 + options.stepSizeProp;
                end
            end

            % Decide button. Move on to the next.
        elseif strcmp(keyPressed,buttonDown)
            break;

            % Close the PTB. Force quit the experiment.
        elseif strcmp(keyPressed,buttonQuit)
            CloseScreen;
            break;
        else
            % Show a message to press a valid key press.
            fprintf('Press a key either (%s) or (%s) or (%s) or (%s) \n',buttonDown,buttonRight,buttonLeft);
        end

        % Set the proportion of the dominant hue in the right range.
        if prop1 > 100
            prop1 = 100;
        elseif prop1 < 0
            prop1 = 0;
        end

        % Set the proportion of the secondary hue.
        prop2 = 100 - prop1;

        % Sanity check.
        proportions = [prop1 prop2];
        sumProps = sum(proportions);
        if ~(sumProps == 100)
            error('The sum of the proportion does not make sense!')
        end

        % Dislpay the test image with an updated proportions. This would look like
        % sort of a real time control.
        texts = [uniqueHues num2str(prop1) num2str(prop2)];
        textPositions = [textPositions_UH; textPositions_probs];
        testImageWithText = insertText(testImageResizedOnBG,textPositions,texts,...
            'font',options.font,'fontsize',options.fontSize,'BoxColor',[1 1 1],'BoxOpacity',0,'TextColor','white','AnchorPoint','LeftCenter');

        % Display the test image with updated texts.
        [testImageTexture testImageWindowRect rng] = MakeImageTexture(testImageWithText, window, windowRect,'verbose',false);
        FlipImageTexture(testImageTexture,window,testImageWindowRect,'verbose',false);

        % Make a tiny time delay every after key press.
        pause(options.postKeyPressDelayPropSec);
    end
end

% Convert the evaluation into hue-400 score.
evaluation = ComputeHueScore(selectedHues,proportions);
end
