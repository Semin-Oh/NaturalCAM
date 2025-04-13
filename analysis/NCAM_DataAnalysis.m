% NCAM_DataAnalysis.
%
% This is routine to analyze the hue data for Natual CAM project.
%
% See also:
%    NCAM_RunExperiment.m.

% History:
%    03/31/25    smo     - Started on it.
%    04/10/25    smo     - Added the estimation of dominant color of the
%                          object within each image.
%    04/13/25    smo     - Now dominant color descriptor works. Also, full
%                          pipeline works. Note: some images should use
%                          second to the dominant color (person3). The hue
%                          scale should be matched correctly for the colors
%                          near 400.

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

% Control print out and plots.
verbose = false;

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

% Also, here, we read out the test images actually used in the experiment.
testimageStringFiledir = fullfile(baseFiledir,projectName,'images');
testimageStringFilename = 'imageNames.mat';
testimageStringData = load(GetMostRecentFileName(testimageStringFiledir,testimageStringFilename));
testimageOptions = testimageStringData.imageNames;

%% Get the raw data for all subjects.
%
% Make a loop for all subjects.
for ss = 1:nSubjects
    % Set the subject name and folder to read.
    subjectName = targetSubjectsNames{ss};
    subDataFiledir = fullfile(dataFiledir,subjectName);

    % Show the progress.
    fprintf('Data loading: Subject = (%s) / Number of subjects (%d/%d) \n',subjectName,ss,nSubjects);

    % Read out raw data here.
    olderDate = 0;
    dataFilename = GetMostRecentFileName(subDataFiledir,sprintf('%s',subjectName),'olderDate',olderDate);
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

%% Calculate CAM16 values from here.
%
% Set the folders to read out the test image and corresponding segmentation data.
imageFiledir = fullfile(baseFiledir,projectName,'images','segmentation','images_labeled');
segmentationFiledir = fullfile(baseFiledir,projectName,'images','segmentation','segmentation_labeled');

% Get available image file names.
imageFileList = dir(imageFiledir);
imageNameList = {imageFileList.name};
imageNameOptions = imageNameList(~startsWith(imageNameList,'.'));

% Get available segmentation file names.
segmentFileList = dir(segmentationFiledir);
segmentNameList = {segmentFileList.name};
segmentNameOptions = segmentNameList(~startsWith(segmentNameList,'.'));

% Here we make a loop to calculate CAM16 values for all images available.
nTestImagesSegment = length(imageNameOptions);
for ii = 1:nTestImagesSegment
    numImage = ii;
    image = imread(fullfile(imageFiledir,imageNameOptions{numImage}));

    % Read out segmentation data.
    segFilename = segmentNameOptions{numImage};
    fid = fopen(fullfile(segmentationFiledir,segFilename),"r");
    segmentData = textscan(fid, '%f %s %f %f %f %f %f', 'Delimiter', ',', 'HeaderLines', 1);
    fclose(fid);

    %% Estimate the illumination within an image.
    %
    % We will define the white point within the scene using a simple so-called
    % white patch method. It basically searches the brightest pixel (R+G+B)
    % within the scene and treat it as a white point.
    whitePointCalculationMethod = 'whitepatch';
    mean_dRGB_image_bright = CalImageWhitePoint(image,'calculationMethod',whitePointCalculationMethod,'verbose',verbose);

    % Calculate the XYZ values of the white point. We will use this as
    % a white point for CIECAM02 calculations.
    XYZ_white = RGBToXYZ(mean_dRGB_image_bright,M_RGBToXYZ,gamma_display);

    %% Estimate the dominant color of the segmented object.
    %
    % Here, we will use the DCD (Dominant Color Descriptor) method.
    % Detailed explanation is given in the description inside the function.
    XYZ_targetObject = GetImageDominantColor(image,segmentData,M_RGBToXYZ,gamma_display,XYZ_white,'verbose',verbose);

    %% Actual calculations of CAM16 happens here.
    %
    % Set adapting luminance (LA) value. We set it as 20% luminance of the
    % white point, which is not uncommon.
    LA = XYZ_white(2)*0.2;

    % Calculate CAM16 values here and we extract Hue quadrature (H).
    JCH_targetObject(:,ii) = XYZToJCH(XYZ_targetObject,XYZ_white,LA);

    % Show progress.
    fprintf('Calculating CAM16 values - (%d/%d) \n', ii, nTestImagesSegment);
end

% Extract the CAM16 Hue quadrature values
CAM16_H = JCH_targetObject(3,:);

%% Comparison between experiment results vs. CAM16 estimations.
%
% Some images do not have proper correspondong segmentation data, so here
% we match the number of the images to compare. As of now (04/13/25), we
% used 31 images for the experiment while we have valid segmentation data
% ~29 images.
validTestimageOptions = {};
validSegImageOptions = {};

nImagesToCompare = min(nTestImages,nTestImagesSegment);
for ss = 1:nImagesToCompare
    % Get the image name from the segmentation data.
    [~, imagename1, ~] = fileparts(segmentNameOptions{ss});

    % Here, we make a loop to find a matching name in the test image list
    % that used in the experiment.
    ii = 1;
    while true
        [~, imagename2, ~] = fileparts(testimageOptions{ii});

        % Find the matching name.
        if strcmp(imagename1, imagename2)
            validSegImageOptions{end+1} = segmentNameOptions{ss};
            validTestimageOptions{end+1} = testimageOptions{ii};
            break;
        end

        % Keep counting.
        ii = ii + 1;
    end

    % Show progress.
    fprintf('Find valid images to compare: (%s) - (%d/%d) \n', imagename1, ss, nImagesToCompare);
end

% Exclude some images if you want.
% THIS PART WILL BE UPDATED LATER ON.
imageToExclude = {};

% Get the index valid images to compare.
[~, idxTestImages, ~] = intersect(testimageOptions, validTestimageOptions);
[~, idxSegImages, ~] = intersect(segmentNameOptions, validSegImageOptions);

% Comparison between experiment results and CAM16 H.
CAM16_H_compare = CAM16_H(idxSegImages);
hueScoreMeanAllSub_compare = hueScoreMeanAllSub(idxTestImages);
nImagesValid = length(idxTestImages);

% Plot it.
figure; hold on;
plot(hueScoreMeanAllSub_compare, CAM16_H_compare, 'o',...
    'markeredgecolor','k','markerfacecolor','g');
plot([0 400], [0 400],'k-');
xlabel('CAM16 H');
ylabel('Hue Score (Exp)');
xlim([0 400]);
ylim([0 400]);
axis square;
grid on;
legend('Images','location','southeast');
title('CAM16 vs. Hue score (experiment)');
subtitle(sprintf('Subjects (%d) / Test Images (%d)',nSubjects,nImagesValid));
