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
%    04/14/25    smo     - Added correlation coefficient for both subjects
%                          repeatability and reproducibility. Also, now we
%                          can choose test images not to be included in
%                          data analysis.

%% Initialize.
clear; close all;

%% Choose which date to analyze.
while 1
    inputMessageExpMode = 'Which data to analyze? [1:hue, 2:lightness]: ';
    ansExpMode = input(inputMessageExpMode);
    ansOptions = [1 2];

    if ismember(ansExpMode, ansOptions)
        break
    end

    disp('Type either 1 or 2!');
end
expModeOptions = {'hue','lightness'};
expMode = expModeOptions{ansExpMode};

% Display which experiment is running.
fprintf('(%s) experiment data will be analyzed! \n',expMode);

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
projectName = 'NaturalCAM';

% Control print out and plots.
SUBJECTANON = true;
CHECKREPEATABILITY = true;
CHECKREPRODUCIBILITY = true;
PLOTIMAGEWHITEPOINT = true;
PLOTOBJECTDOMINANTCOLOR = false;

%% Get available subject info.
%
% Set the repository.
dataFiledir = fullfile(baseFiledir,projectName,'data',expMode);

% Get available subject names.
subjectNameContent = dir(dataFiledir);
subjectNameList = {subjectNameContent.name};
subjectNames = subjectNameList(~startsWith(subjectNameList,'.'));

% Exclude some subjects if you want.
exclSubjectNames = {'Blaise'};
targetSubjectsNames = subjectNames(~ismember(subjectNames,exclSubjectNames));
nSubjects = length(targetSubjectsNames);

%% Read out test image and segmentation info.
%
% This part read out the test image names that actually used in the
% experiment.
testimageStringFiledir = fullfile(baseFiledir,projectName,'images');
testimageStringFilename = 'imageNames.mat';
testimageStringData = load(GetMostRecentFileName(testimageStringFiledir,testimageStringFilename));
testimageOptions = testimageStringData.imageNames;

% Set the folders to read out the test image and corresponding segmentation
% data. Here, we read out images and their corresponding segmentation data.
% images are basically the same as above, but in different file format.
%
% Get available image file names.
imageFiledir = fullfile(baseFiledir,projectName,'images','segmentation','images_labeled');
imageFileList = dir(imageFiledir);
imageNameList = {imageFileList.name};
imageOptions = imageNameList(~startsWith(imageNameList,'.'));

% Get available segmentation file names.
segmentationFiledir = fullfile(baseFiledir,projectName,'images','segmentation','segmentation_labeled');
segmentFileList = dir(segmentationFiledir);
segmentNameList = {segmentFileList.name};
segmentationOptions = segmentNameList(~startsWith(segmentNameList,'.'));

%% Find valid images to compare. Also, exclude some if you want.
%
% Some images do not have proper correspondong segmentation data, so here
% we match the number of the images to compare. As of now (04/13/25), we
% used 31 images for the experiment while we have valid segmentation data
% ~29 images.
validTestimageOptions = {};
validSegmentationOptions = {};

% Exclude the test images if you want. For now, we have some images with no
% proper segmentation, which will be excluded for now.
exclImageNameOnly = {'kite1','orange1','orange2','orange3',...
    'person1','person3','person4','surfboard1'};

% Here, we make a loop to find the test image names that was used in the
% experiment, and also having the valid segmentation data.
nTestImagesSegment = length(imageOptions);
for ss = 1:nTestImagesSegment
    % Get the image name from the segmentation data.
    [~, imagename1, ~] = fileparts(segmentationOptions{ss});

    % Here, we make a loop to find a matching name in the test image list
    % that used in the experiment.
    ii = 1;
    while true
        [~, imagename2, ~] = fileparts(testimageOptions{ii});

        % Find the matching name.
        if strcmp(imagename1, imagename2)
            % Add the image name unless it's not the images that we want to
            % exclude.
            if ~any(strcmp(exclImageNameOnly,imagename1))
                validSegmentationOptions{end+1} = segmentationOptions{ss};
                validTestimageOptions{end+1} = testimageOptions{ii};
            end
            break;
        end

        % Keep counting.
        ii = ii + 1;
    end

    % Show progress.
    fprintf('Find valid images to compare: (%s) - (%d/%d) \n', imagename1, ss, nTestImagesSegment);
end
nTestImagesValid = length(validTestimageOptions);
fprintf('Total of (%d) valid test images were found! \n',nTestImagesValid);

% Get the image index to update further experimental data.
[~, idxTestImages, ~] = intersect(testimageOptions, validTestimageOptions);
nTestImagesToCompare = length(idxTestImages);

% Get the image index to update further CAM16 calculations.
[~, idxSegImages, ~] = intersect(segmentationOptions, validSegmentationOptions);
validImageOptions = imageOptions(idxSegImages);

% % Remove extensions to sort the image excluded.
% segNamesOnly  = erase(validSegmentationOptions, '.csv');
% imageNamesOnly  = erase(validTestimageOptions, '.png');
%
% % Get the index of excluded images based on name.
% isExcludedSeg  = ismember(segNamesOnly, exclImageNameOnly);
% isExcludedImage  = ismember(imageNamesOnly, exclImageNameOnly);
%
% % Filter out the excluded images.
% segImageOptions_filtered  = validSegmentationOptions(~isExcludedSeg);
% validTestimageOptions_filtered  = validTestimageOptions(~isExcludedImage);
%
% % Get the index valid images to compare.
% [~, idxTestImages, ~] = intersect(testimageOptions, validTestimageOptions_filtered);
% [~, idxSegImages, ~] = intersect(segmentationOptions, segImageOptions_filtered);

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
        hueScore_rawTemp =  rawData.data.hueScore(:,rr);
        idxOrderSortedTemp = idxOrder_sorted(:,rr);
        hueScore_sortedTemp(:,rr) = hueScore_rawTemp(idxOrderSortedTemp);
    end
    % We will save out the results with only valid segmentation data.
    hueScore_raw{ss} = hueScore_sortedTemp(idxTestImages,:);

    % Calculate the mean of the repeatitions within subject.
    hueScore_meanPerSub{ss} = mean(hueScore_raw{ss},2);
end

%% Check repeatability - within observer.
axisHue = [0 450];
if (CHECKREPEATABILITY)
    figure; hold on;

    % Make a loop for all subjects.
    for ss = 1:nSubjects
        % Get subject name.
        subjectName = targetSubjectsNames{ss};

        % Get one subject data.
        hueScore_oneSubTemp = hueScore_raw{ss};

        % Calculate the correlation coefficient between two repeatitions.
        % Here, we will only use the data with valid segmentation data.
        r_matrix = corrcoef(hueScore_oneSubTemp(:,1),hueScore_oneSubTemp(:,2));
        r_withinSubjects(ss) = r_matrix(1,2);

        % Plot it here.
        nColumns = 5;
        subplot(ceil(nSubjects/nColumns),nColumns,ss); hold on;
        plot(hueScore_oneSubTemp(:,1),hueScore_oneSubTemp(:,2),'k.');
        plot(axisHue,axisHue,'k-');
        axis square;
        xlabel('Hue score');
        ylabel('Hue score');
        xlim(axisHue);
        ylim(axisHue);

        if (SUBJECTANON)
            title(sprintf('Subject %d',ss));
        else
            title(subjectName);
        end
        subtitle(sprintf('(r=%.3f)',r_withinSubjects(ss)));
    end

    % Display the mean repeatability in the figure.
    r_mean_withinSubjects = mean(r_withinSubjects);
    sgtitle(sprintf('Repeatability test (within subject) \n Mean correlation r = (%.3f)',r_mean_withinSubjects));
end

%% Check reproducibiliy - across observer.
if (CHECKREPRODUCIBILITY)
    figure; hold on;
    % Calculate the mean results across all subjects. We will compare each
    % subject's data with the mean.
    %
    % First, put all subjects data into one matrix. The size of the matrix
    % depends on the number of test images, the number of repetitions, and the
    % number of subjects. For example, 31 images were used with 2 repetitions
    % and 10 subjects, the matrix will have the size of 31 x 20 (2 rep x 10
    % subs).
    hueScoreAllSub = horzcat(hueScore_meanPerSub{:});

    % Make an average per each test image across all subjects and repetitions.
    % WE NEED TO THINK ABOUT HOW TO MANAGE THE DATA WITHIN THE RANGE BLUE-RED.
    % hueScoreMeanAllSub = mean(hueScoreAllSub,2);

    % Convert hue quadrature (0–400) to radians (0–2π).
    angles = hueScoreAllSub / 400 * 2 * pi;

    % Compute mean angle using circular statistics
    mean_sin = mean(sin(angles),2);
    mean_cos = mean(cos(angles),2);
    mean_angle = atan2(mean_sin, mean_cos);

    % Convert mean angle back to hue quadrature scale.
    hueScore_mean = mod(mean_angle, 2*pi) / (2*pi) * 400;

    % Get standard deviation and standard error.
    n = size(hueScoreAllSub,2);
    hueScore_std = std(hueScoreAllSub');
    hueScore_stdError = hueScore_std/sqrt(n);

    % Make a loop for all subjects.
    for ss = 1:nSubjects
        % Get subject name.
        subjectName = targetSubjectsNames{ss};

        % Get one subject data.
        hueScore_oneSubTemp = hueScore_meanPerSub{ss};

        % Calculate the correlation coefficient between one subject data and mean.
        r_matrix = corrcoef(hueScore_oneSubTemp,hueScore_mean);
        r_acrossSubjects(ss) = r_matrix(1,2);

        % Plot it here.
        subplot(ceil(nSubjects/5),nColumns,ss); hold on;
        plot(hueScore_mean,hueScore_oneSubTemp(:,1),'r.');
        plot(axisHue,axisHue,'k-');
        axis square;
        xlabel('Hue score (mean)');
        ylabel('Hue score (individual)');
        xlim(axisHue);
        ylim(axisHue);

        if (SUBJECTANON)
            title(sprintf('Subject %d',ss));
        else
            title(subjectName);
        end
        subtitle(sprintf('(r=%.3f)',r_acrossSubjects(ss)));
    end

    % Display the mean subject reproducibility in the figure.
    r_mean_acrossSubjects = mean(r_acrossSubjects);
    sgtitle(sprintf('Reproducibility test (across subjects) \n Mean corrleation r = (%.3f)',r_mean_acrossSubjects));
end

%% Calculate CAM16 values from here.
%
% Here we make a loop to calculate CAM16 values for all images available.
for ii = 1:nTestImagesToCompare
    numImage = ii;
    image = imread(fullfile(imageFiledir,validImageOptions{numImage}));

    % Read out segmentation data.
    segFilename = validSegmentationOptions{numImage};
    fid = fopen(fullfile(segmentationFiledir,segFilename),"r");
    segmentData = textscan(fid, '%f %s %f %f %f %f %f', 'Delimiter', ',', 'HeaderLines', 1);
    fclose(fid);

    %% Estimate the illumination within an image.
    %
    % We will define the white point within the scene using a simple so-called
    % white patch method. It basically searches the brightest pixel (R+G+B)
    % within the scene and treat it as a white point.
    whitePointCalculationMethod = 'whitepatch';
    percentPixelCutoff = 0.9;
    percentPixelBright = 0.05;
    mean_dRGB_image_bright = CalImageWhitePoint(image,...
        'percentPixelCutoff',percentPixelCutoff,...
        'percentPixelBright',percentPixelBright,...
        'calculationMethod',whitePointCalculationMethod,'verbose',PLOTIMAGEWHITEPOINT);

    % Calculate the XYZ values of the white point. We will use this as
    % a white point for CIECAM02 calculations.
    XYZ_white = RGBToXYZ(mean_dRGB_image_bright,M_RGBToXYZ,gamma_display);

    %% Estimate the dominant color of the segmented object.
    %
    % Here, we will use the DCD (Dominant Color Descriptor) method.
    % Detailed explanation is given in the description inside the function.
    nClusters = 3;
    nReplicates = 5;
    clusterSpace = 'ab';
    XYZ_targetObject = GetImageDominantColor(image,segmentData,M_RGBToXYZ,gamma_display,XYZ_white,...
        'nClusters',nClusters,'nReplicates',nReplicates,...
        'clusterSpace',clusterSpace,'verbose',PLOTOBJECTDOMINANTCOLOR);

    %% Actual calculations of CAM16 happens here.
    %
    % Set adapting luminance (LA) value. We set it as 20% luminance of the
    % white point, which is not uncommon.
    LA = XYZ_white(2)*0.2;

    % Calculate CAM16 values here and we extract Hue quadrature (H).
    JCH_targetObject(:,ii) = XYZToJCH(XYZ_targetObject,XYZ_white,LA);

    % Show progress.
    fprintf('Calculating CAM16 values - Image (%d/%d) \n', ii, nTestImagesToCompare);
end

% Extract the CAM16 Hue quadrature values
CAM16_H = JCH_targetObject(3,:);

%% Comparison between experiment results vs. CAM16 estimations.
%
% THIS PART WILL BE ADDED LATER ON
%
% Match the scale between CAM16 H values and the experimental results. As H
% has a circular scale, some values might be off-scale. For example, if we
% have a pair of the values, 32 and 385, we will convert them to 432
% (32+400) and 385. It's preferred to add 400 to match the scale to avoid
% any negative values.
deltaHue = CAM16_H'-hueScore_mean;
idxWeired = find(abs(deltaHue)>100);
for ww = 1:length(idxWeired)
    idxWeiredTemp = idxWeired(ww);

    CAM16_H_temp = CAM16_H(idxWeiredTemp);
    hueScore_temp = hueScore_mean(idxWeiredTemp);

    if CAM16_H_temp <  hueScore_temp
        CAM16_H_temp = CAM16_H_temp + 400;
    else
        hueScore_temp = hueScore_temp + 400;
    end

    CAM16_H(idxWeiredTemp) = CAM16_H_temp;
    hueScore_mean(idxWeiredTemp) = hueScore_temp;
end

% Plot it.
figure; hold on;

% Error bar.
ERRORBAR = 'stderror';
switch ERRORBAR
    case 'stderror'
        hueScore_errorbar_plot = hueScore_stdError;
    case 'std'
        hueScore_errorbar_plot = hueScore_std;
end
errorbar(hueScore_mean, CAM16_H, ...
    [], [], hueScore_errorbar_plot, hueScore_errorbar_plot,...
    'LineStyle','none','Color','k');

% Mean comparison.
f_data = plot(hueScore_mean,CAM16_H,'o',...
    'markeredgecolor','k','markerfacecolor','g');

% Calculate delta hue.
delta_hue_mean = mean(abs(CAM16_H'-hueScore_mean));

% 45-deg line.
plot(axisHue,axisHue,'k-');

% Figure stuff.
xlabel('Hue Score');
ylabel('CAM16 H');
xlim(axisHue);
ylim(axisHue);
axis square;
grid on;
legend(f_data,'Images','location','southeast');
title('CAM16 vs. Mean results');
subtitle(sprintf('nSubjects = (%d) / nTestImages = (%d) / Mean delta H = (%.2f)',nSubjects,nTestImagesToCompare,delta_hue_mean));

%% Plot the individual results compared with CAM16.
figure;
sgtitle(sprintf('CAM16 vs. Inidividual results \n nTestImages = (%d)',nTestImagesToCompare));
for ss = 1:nSubjects
    % Get the subject name.
    subjectName = targetSubjectsNames{ss};

    % Make a separate plot per subject.
    subplot(ceil(nSubjects/nColumns),nColumns,ss); hold on;
    plot(hueScore_meanPerSub{ss},CAM16_H,'o',...
        'markeredgecolor','k','markerfacecolor','g','markersize',4);
    plot(axisHue,axisHue,'k-');

    xlabel('Hue Score');
    ylabel('CAM16 H');
    xlim(axisHue);
    ylim(axisHue);
    axis square;
    grid on;
    if (SUBJECTANON)
        title(sprintf('Subject %d',ss));
    else
        title(subjectName);
    end
end
