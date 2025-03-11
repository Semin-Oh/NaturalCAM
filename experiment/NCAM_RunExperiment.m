% NCAM_RunExperiment.
%
% This is an experiment running code for color appearance model using DNN.
% The base code is from the Color Assimilation project which uses the
% similiar framework.
%
% We need to consider that the computer connected to the EIZO monitor that
% we plan to use does not connect to the internet, so we may want to move
% all test images in advance in the computer.
%
% See also:
%    CA_RunExperiment.

% History:
%    02/13/25    smo    - Started on it.
%    03/05/25    smo    - It is working.
%    03/06/25    smo    - working from the start to the end.
%    03/10/25    smo    - Made it work on EIZO computer. Also, font sizes
%                         are updated to fit better on the EIZO monitor.

%% Initialize.
close all; clear;

% Path names specified per computer.
pathProjectLinux = '/home/gegenfurtner/Documents/MATLAB';
pathProjectEIZO = 'C:\Users\fulvous.uni-giessen\Documents\MATLAB';

if isfolder(pathProjectLinux)
    pathProject = pathProjectLinux;
    computerType = 'linux';
elseif isfolder(pathProjectEIZO)
    pathProject = pathProjectEIZO;
    computerType = 'windows';
else
    error('None of the paths are found. Check out the path again.');
end

% Add path here.
addpath(genpath(pathProject));
fprintf('Project repository has been added to path - Running on (%s) \n',computerType);

%% Add the repository to the path.
sysInfo = GetComputerInfo();

% Set the file dir differently depending on the computer.
switch sysInfo.userShortName
    case 'semin'
        % Office computer.
        baseFiledir = '/Users/semin/Dropbox (Personal)/JLU/d2) Projects';
    case 'gegenfurtner'
        % Lab Linux computer Dropbox directory.
        baseFiledir = '/home/gegenfurtner/Dropbox/JLU/2) Projects';
    otherwise
        % EIZO computer at the color lab.
        baseFiledir = 'C:\Users\fulvous.uni-giessen\Dropbox\JLU\2) Projects';
end

% Set repository name.
projectName = 'NaturalCAM';
testFiledir = fullfile(baseFiledir,projectName);

%% Get subject info.
inputMessageName = 'Enter subject name: ';
subjectName = input(inputMessageName, 's');

%% Starting from here to the end, if error occurs, we automatically close the PTB screen.
try
    %% Set variables.
    %
    % Experimental variables.
    expParams.nRepeat = 1;
    expParams.postIntervalDelaySec = 2;
    expParams.postKeyPressDelaySec = 0.15;
    expParams.secIntvFlashingArrow = 0.3;
    expParams.testImageSizeHeightRatio = 0.9;
    expParams.fontSize = 25;
    expParams.nArrowFlashes = 3;
    expParams.subjectName = subjectName;
    expParams.expKeyType = 'gamepad';

    % etc.
    SAVETHERESULTS = true;

    %% Load the test images.
    %
    % Get the directory where the test images are saved.
    testImageFiledir = fullfile(testFiledir,'images','raw');
    testImageArrowFiledir = fullfile(testFiledir,'images','arrow');

    % Get available images.
    imageNameContent = dir(testImageFiledir);
    imageNameList = {imageNameContent.name};
    imageNames = imageNameList(~startsWith(imageNameList,'.'));

    % Count the number of available images.
    expParams.nTestImages = length(imageNames);

    % Load the images here. We will read out as an image format.
    for ii = 1:expParams.nTestImages
        imageName = imageNames{ii};
        % Read out test image.
        testImageFilename = GetMostRecentFileName(testImageFiledir,imageName);
        testImage.testImage{ii} = imread(testImageFilename);

        % Read out test image with an arrow on it. We saved each image with
        % an arrow in the same name as the raw test image.
        testImageArrowFilename = GetMostRecentFileName(testImageArrowFiledir,imageName);
        if isfile(testImageArrowFilename)
            testImage.testImageArrow{ii} = imread(testImageArrowFilename);
        end
    end

    % Sanity Check. Make sure there are equal numbers of images with and without arrow.
    if ~(length(testImage.testImage) == length(testImage.testImageArrow))
        error('The number of the test images mismatches with and without arrow.');
    end

    % Set the random order of displaying the test images.
    %
    % The array should look like the number of test images x the number of
    % repeatitions per each test image. For example, if there are 5 test
    % images and repeat each test image for 10 times, the array should look
    % like 5x10.
    for rr = 1:expParams.nRepeat
        expParams.randOrder(:,rr) = randperm(expParams.nTestImages)';
    end

    % Sanity check.
    if any(or(size(expParams.randOrder,1) ~= expParams.nTestImages,...
            size(expParams.randOrder,2) ~= expParams.nRepeat))
        error('The random order array size does not match!');
    end

    %% Pre-experiment screen shows up here.
    %
    % Open the PTB screen. We will display an uniform black screen.
    initialScreenSetting = [0 0 0]';
    [window windowRect] = OpenPlainScreen(initialScreenSetting);

    % Make a null image here. We set a null image as uniform black screen.
    nullImage = zeros(windowRect(4), windowRect(3), 3);
    nullImageSize = size(nullImage);

    % Set the texts to display.
    text_1stLine = 'Press any button';
    text_2ndLine = 'To start the experiment';
    texts = {text_1stLine text_2ndLine};

    % Set the text position.
    textPositionRatioHorz = 0.43;
    textPositionRatioVert = 0.02;
    textPositions = [nullImageSize(2)*textPositionRatioHorz nullImageSize(1)/2-nullImageSize(1)*textPositionRatioVert;
        nullImageSize(2)*textPositionRatioHorz nullImageSize(1)/2+nullImageSize(1)*textPositionRatioVert];

    % Define the font.
    switch sysInfo.userShortName
        % For Linux.
        case 'gegenfurtner'
            font = 'Ubuntu-B';
            % The others.
        otherwise
            font = 'arial';
    end

    % Add text into the image.
    nullImageWithTexts = insertText(nullImage,textPositions,texts,...
        'fontsize',35,'Font',font,'BoxColor',[1 1 1],'BoxOpacity',0,'TextColor','white','AnchorPoint','LeftTop');

    % Display an image texture of the initial image.
    [nullImageWithTextsTexture nullImageWithTextsWindowRect rng] = MakeImageTexture(nullImageWithTexts, window, windowRect,'verbose',false);
    FlipImageTexture(nullImageWithTextsTexture, window, windowRect,'verbose',false);

    % Get the PTB texture info in an array.
    activeTextures = [];
    activeTextures(end+1) = nullImageWithTextsTexture;

    % Get any key press to proceed.
    switch (expParams.expKeyType)
        case 'gamepad'
            GetJSResp;
        case 'keyboard'
            GetKeyPress;
    end
    disp('Experiment is going to be started!');

    %% Experiment happens here.
    %
    % Display a null image. We will not include the null image texture in
    % the 'activeTextures' as we will recall it every after test image
    % display.
    [nullImageTexture nullImageWindowRect rng] = MakeImageTexture(nullImage, window, windowRect, 'verbose', false);
    FlipImageTexture(nullImageTexture, window, windowRect,'verbose',false);

    % First loop for the number of trials.
    for rr = 1:expParams.nRepeat

        % Second loop for different test images. We will display them
        % together in randomized order.
        for ii = 1:expParams.nTestImages
            idxImageName = expParams.randOrder(ii,rr);

            % One evaluation happens here using Magnitude estimation method.
            data.hueScore(ii,rr) = GetOneRespMagnitudeEst(testImage.testImage{ii},testImage.testImageArrow{ii},window,windowRect,...
                'expKeyType',expParams.expKeyType,'postKeyPressDelaySec',expParams.postKeyPressDelaySec,'testImageSizeHeightRatio',expParams.testImageSizeHeightRatio,...
                'secIntvFlashingArrow',expParams.secIntvFlashingArrow,'nArrowFlashes',expParams.nArrowFlashes,'fontsize',expParams.fontSize,...
                'font',font,'verbose',true);

            % Display a null image again and pause for a second before
            % displaying the next test image.
            [nullImageTexture nullImageWindowRect rng] = MakeImageTexture(nullImage, window, windowRect, 'verbose', false);
            FlipImageTexture(nullImageTexture, window, windowRect,'verbose',false);
            pause(expParams.postIntervalDelaySec);

            % Show the progress.
            fprintf('Experiment progress - (%d/%d) \n',rr,expParams.nRepeat);
        end
    end

    %% Show the screen every after finishing one primary session.
    %
    % DISABLED FOR NOW.
    % %
    % % It takes a while saving the results and moving on to the next primary
    % % session, so here we show some screen to say it will take a while.
    % messageAfterSessionImage_1stLine = 'Session completed';
    % messageAfterSessionImage_2ndLine = 'Wait for the next session started';
    %
    % afterSessionInstructionImage = insertText(nullImage,[nullImageSize(2)*textPositionRatioHorz nullImageSize(1)/2-nullImageSize(1)*textPositionRatioVert; nullImageSize(2)*textPositionRatioHorz nullImageSize(1)/2+nullImageSize(1)*textPositionRatioVert],...
    %     {messageAfterSessionImage_1stLine messageAfterSessionImage_2ndLine},...
    %     'fontsize',40,'Font',font,'BoxColor',[1 1 1],'BoxOpacity',0,'TextColor','black','AnchorPoint','LeftCenter');
    %
    % % Display an image texture of the initial image.
    % [afterSessionImageTexture afterSessionImageWindowRect rng] = MakeImageTexture(afterSessionInstructionImage, window, windowRect,'verbose',false);
    % FlipImageTexture(afterSessionImageTexture, window, windowRect,'verbose',false);

    %% Save the data. We will save the results separately per each primary.
    if (SAVETHERESULTS)
        % Save out the data only if we reached the desired number of trials.
        nTargetTrials = expParams.nTestImages * expParams.nRepeat;
        nTrialsDone = ii * rr;
        if (nTrialsDone == nTargetTrials)
            saveFiledir = fullfile(testFiledir,'data');

            % Make folder with subject name if it does not exist.
            saveFoldername = fullfile(saveFiledir,subjectName);
            if ~exist(saveFoldername, 'dir')
                mkdir(saveFoldername);
                fprintf('Folder has been successfully created: (%s)\n',saveFoldername);
            end

            % Save out the experiment params in the structure.
            data.expParams = expParams;

            % Set the file name and save.
            dayTimestr = datestr(now,'yyyy-mm-dd_HH-MM-SS');
            saveFilename = fullfile(saveFoldername,...
                sprintf('%s_%s',subjectName,dayTimestr));
            save(saveFilename,'data');
            disp('Data has been saved successfully!');
        end
    end

    %% Close the PTB screen once the experiment is done.
    CloseScreen;

catch
    % If error occurs, close the screen.
    CloseScreen;
    tmpE = lasterror;

    % Display the error message.
    tmpE.message
    tmpE.stack.name
    tmpE.stack.line
end
