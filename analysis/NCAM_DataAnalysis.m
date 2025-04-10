% NCAM_DataAnalysis.
%
% This is routine to analyze the hue data for Natual CAM project.
%
% See also:
%    NCAM_RunExperiment.m.

% History:
%    03/31/25    smo     - Started on it.

%% Initialize.
clear; close all;

%% Set variables.
%
% Set display type and its 3x3 characterization matrix. The matrix is read
% from the recent measurement that made using the routine
% CalibrateMonitor.m and AnalyzeMonitor.m.
displayType = 'EIZO';
switch displayType
    case 'EIZO'
        % 3x3 matrix.
        M_RGBToXYZ =  [62.1997 22.8684 19.2310;...
            28.5133 78.5446 6.9256;...
            0.0739 6.3714 99.5962];
        
        % Monitor gamma. (R=2.2267, G=2.2271, B=2.1652, Gray=2.1904). We
        % will use the gray channel gamma for further calculations for now.
        gamma_display = 2.1904;
end

verbose = true;

%% Get available subject info.
%
% Get computer info.
sysInfo = GetComputerInfo();

% Set the file dir differently depending on the computer.
switch sysInfo.userShortName
    % Semin office computer.
    case 'semin'
        baseFiledir = '/Users/semin/Dropbox (Personal)/JLU/2) Projects';
        % Lab Linux computer.
    case 'gegenfurtner'
        baseFiledir = '/home/gegenfurtner/Dropbox/JLU/2) Projects';
    otherwise
        % Semin's laptop.
        baseFiledir = 'C:\Users\ohsem\Dropbox (Personal)\JLU\2) Projects';
end

% Set repository name.
projectName = 'NaturalCAM';
dataFiledir = fullfile(baseFiledir,projectName,'data');

% Get available subject names.
subjectNameContent = dir(dataFiledir);
subjectNameList = {subjectNameContent.name};
subjectNames = subjectNameList(~startsWith(subjectNameList,'.'));

% Exclude some subjects if you want.
exclSubjectNames = {};
targetSubjectsNames = subjectNames(~ismember(subjectNames,exclSubjectNames));
nSubjects = length(targetSubjectsNames);

%% Get the raw data for all subjects.
%
% Make a loop for all subjects.
for ss = 1:nSubjects
    % Set the subject name and folder to read.
    subjectName = targetSubjectsNames{ss};
    dataFiledir = fullfile(dataFiledir,subjectName);

    % Show the progress.
    fprintf('Data loading: Subject = (%s) / Number of subjects (%d/%d) \n',subjectName,ss,nSubjects);

    % Read out raw data here.
    olderDate = 0;
    dataFilename = GetMostRecentFileName(dataFiledir,sprintf('%s',subjectName),'olderDate',olderDate);
    rawData = load(dataFilename);

    % Rearrange the raw data. In the experiment, test images were displayed
    % in a random order, so the raw data is sorted in that order. Here, we
    % sort out the results.
    %
    % Read out some variables.
    nRepeat = rawData.data.expParams.nRepeat;
    nTestImages = rawData.data.expParams.nTestImages;

    % Get the index to sort out the results.
    [randOrderSorted idxOrder_sorted] = sort(rawData.data.expParams.randOrder);

    % Sort out the results. Array should look [TestImages x
    % Repeatitions]. For example, if you used 5 test images and 10
    % repeatitions per each test image, the array will look like 5x10.
    %
    % Be careful when sorting out the array. When the experiment was
    % repeated more than one time, there will be more than two different
    % random orders. Each array should be sorted in a corresponding random
    % order. Here, to be careful on this, we make a loop to sort one by
    % one.
    for rr = 1:nRepeat
        hueScoreTemp =  rawData.data.hueScore(:,rr);
        idxOrderSortedTemp = idxOrder_sorted(:,rr);
        hueScore_sorted(:,rr) = hueScoreTemp(idxOrderSortedTemp);
    end
    % Mean results.
    hueScorePerSub{ss} = hueScore_sorted;
end

%% Check repeatability - within observer.
CHECKREPEATABILITY = true;

if (CHECKREPEATABILITY)
    figure; hold on;
    sgtitle('Repeatability within subject');

    % Make a loop for all subjects.
    for ss = 1:nSubjects
        % Get subject name.
        subjectName = subjectNames{ss};

        % Get one subject data.
        hueScoreOneSub = hueScorePerSub{ss};

        % Plot it here.
        nColumns = 5;
        subplot(ceil(nSubjects/nColumns),nColumns,ss); hold on;
        plot(hueScoreOneSub(:,1),hueScoreOneSub(:,2),'k.');
        plot([0 400],[0 400],'k-');
        axis square;
        xlabel('Hue score');
        ylabel('Hue score');
        title(subjectName);
    end
end

%% Check reproducibiliy - across observer.
CHECKREPRODUCIBILITY = true;

if (CHECKREPRODUCIBILITY)
    figure; hold on;
    sgtitle('Reproducibility across subjects');

    % Calculate the mean results across all subjects. We will compare each
    % subject's data with the mean.
    %
    % First, put all subjects data into one matrix. The size of the matrix
    % depends on the number of test images, the number of repetitions, and the
    % number of subjects. For example, 31 images were used with 2 repetitions
    % and 10 subjects, the matrix will have the size of 31 x 20 (2 rep x 10
    % subs).
    hueScoreAllSub = horzcat(hueScorePerSub{:});

    % Make an average per each test image across all subjects and repetitions.
    % WE NEED TO THINK ABOUT HOW TO MANAGE THE DATA WITHIN THE RANGE BLUE-RED.
    hueScoreMeanAllSub = mean(hueScoreAllSub,2);

    % Make a loop for all subjects.
    for ss = 1:nSubjects
        % Get subject name.
        subjectName = subjectNames{ss};

        % Get one subject data.
        hueScoreOneSub = hueScorePerSub{ss};

        % Plot it here.
        subplot(ceil(nSubjects/5),nColumns,ss); hold on;
        plot(hueScoreMeanAllSub,hueScoreOneSub(:,1),'k.');
        plot(hueScoreMeanAllSub,hueScoreOneSub(:,2),'r.');
        plot([0 400],[0 400],'k-');
        axis square;
        xlabel('Hue score (mean)');
        ylabel('Hue score (individual)');
        title(subjectName);
    end
end

%% Read out the test image.
imageFiledir = fullfile(baseFiledir,projectName,'images','raw');

% Get available image file names.
imageNameContent = dir(imageFiledir);
imageNameList = {imageNameContent.name};
imageNames = imageNameList(~startsWith(imageNameList,'.'));

% Load the image here.
% image = imread(fullfile(imageFiledir,imageNames{1}));
image = imread(fullfile('/Users/semin/Dropbox (Personal)/JLU/2) Projects/NaturalCAM/images/segmentation/images_labeled','apple2.jpg'));

%% Get dominant color of the object
%

% Step 1: RGB to Lab
img = im2double(image);
[h, w, ~] = size(img);
pixels = reshape(img, [], 3);
labPixels = rgb2lab(pixels);  % Requires Image Processing Toolbox

% Step 2: Clustering in Lab
k = 3;
[idx, centers] = kmeans(labPixels, k, 'Replicates', 5);
counts = histcounts(idx, k);
[~, domIdx] = max(counts);
dominantLab = centers(domIdx, :);



%% Estimate the illumination.
%
% We will define the white point within the scene using a simple so-called
% white patch method. It basically searches the brightest pixel (R+G+B)
% within the scene and treat it as a white point.
whitePointCalculationMethod = 'whitepatch';
mean_dRGB_image_bright = CalImageWhitePoint(image,'calculationMethod',whitePointCalculationMethod);

% Calculate the XYZ values of the white point. We will use this as
% a white point for CIECAM02 calculations.
XYZ_white = RGBToXYZ(mean_dRGB_image_bright,M_RGBToXYZ,gamma_display);

%% Define the adapting luminance (cd/m2).
switch whitePointCalculationMethod
    case 'whitepatch'
        % We set the luminance of the adapting field based on the white
        % point that we searched from the above setting the white point.
        LA = XYZ_white(2);

    otherwise
        % You can fix the value if you want. Not sure if if is a good idea
        % to train the model with COCO image set.
        LA = 50;
end

%% Calculate CAM16 values here.
XYZToJCH

%% Comparison between experiment results vs. CAM16 estimations.

