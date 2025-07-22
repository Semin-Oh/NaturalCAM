% NCAM_DataAnalysis.
%
% This is routine to analyze the hue data for Natual CAM project. You need
% to run 'NCAM_UpdateFilename' to get the most recent test images and
% corresponding segmentation data to analyze the data.
%
% See also:
%    NCAM_RunExperiment, NCAM_UpdateFilename.

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
%    07/18/25    smo     - Made it to work for all color appearances.

%% NOTE
% There are three images in Hue data where the dominant color was chosen
% wrong. That should be fixed for the analysis.

%% Initialize.
clear; close all;

%% Choose which date to analyze.
while 1
    inputMessageExpMode = 'Which data to analyze? [1:hue, 2:lightness, 3:colorfulness]: ';
    ansExpMode = input(inputMessageExpMode);
    ansOptions = [1 2 3];

    if ismember(ansExpMode, ansOptions)
        break
    end

    disp('Type either 1 or 2!');
end
expModeOptions = {'hue','lightness','colorfulness'};
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
CHECKREPEATABILITY = false;
CHECKREPRODUCIBILITY = true;
PLOTIMAGEWHITEPOINT = false;
PLOTOBJECTDOMINANTCOLOR = true;

% Figure stuff.
%
% Axis labels.
switch expMode
    case 'hue'
        strAxesData = 'Hue score';
        strAxesCAM16 = 'CAM16 H';
        axisLim = [0 450];
    case 'lightness'
        strAxesData = 'Brightness';
        strAxesCAM16 = 'CAM16 J';
        axisLim = [0 100];
    case 'colorfulness'
        strAxesData = 'Colorfulness';
        strAxesCAM16 = 'CAM16 C';
        axisLim = [0 130];
end

% Number of subplots in column for individual results.
nColumnsSubplot = 5;

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
% exclImageNameOnly = {'kite1','orange1','orange2','orange3',...
%     'person1','person3','person4','surfboard1'};
% exclImageNameOnly = {'person1','person3','person4'};
exclImageNameOnly = {};

% Here, we make a loop to find the test image names that was used in the
% experiment, and also having the valid segmentation data.
nTestImagesSegment = length(segmentationOptions);
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
        switch expMode
            case 'hue'
                rawDataOneSubject = rawData.data.hueScore;
            case 'lightness'
                rawDataOneSubject = rawData.data.lightness;
            case 'colorfulness'
                rawDataOneSubject = rawData.data.colorfulness;
        end
        rawDataOneSubject_temp =  rawDataOneSubject(:,rr);
        idxOrderSortedTemp = idxOrder_sorted(:,rr);
        rawDataOneSubjectSorted_temp(:,rr) = rawDataOneSubject_temp(idxOrderSortedTemp);
    end
    % We will save out the results with only valid segmentation data.
    rawDataAllSubjectsCell{ss} = rawDataOneSubjectSorted_temp(idxTestImages,:);

    % Calculate the mean of the repeatitions within subject.
    rawDataAllSubjectsMeanRepeats{ss} = mean(rawDataAllSubjectsCell{ss},2);
end

% Put all subjects data into one matrix. The size of the matrix
% depends on the number of test images, the number of repetitions, and the
% number of subjects. For example, 31 images were used with 2 repetitions
% and 10 subjects, the matrix will have the size of 31 x 20 (2 rep x 10
% subs).
rawDataAllSubjectsMat = horzcat(rawDataAllSubjectsMeanRepeats{:});

%% Check repeatability - within observer.
if (CHECKREPEATABILITY)
    figure; hold on;

    % Make a loop for all subjects.
    for ss = 1:nSubjects
        % Get subject name.
        subjectName = targetSubjectsNames{ss};

        % Get one subject data.
        rawDataOneSubject_temp = rawDataAllSubjectsCell{ss};

        % Calculate the correlation coefficient between two repeatitions.
        % Here, we will only use the data with valid segmentation data.
        r_matrix = corrcoef(rawDataOneSubject_temp(:,1),rawDataOneSubject_temp(:,2));
        r_withinSubjects(ss) = r_matrix(1,2);

        % Plot it here.
        subplot(ceil(nSubjects/nColumnsSubplot),nColumnsSubplot,ss); hold on;
        plot(rawDataOneSubject_temp(:,1),rawDataOneSubject_temp(:,2),'k.');
        plot(axisLim,axisLim,'k-');
        axis square;
        xlabel(strAxesData);
        ylabel(strAxesData);
        xlim(axisLim);
        ylim(axisLim);

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
    switch expMode
        case 'hue'
            % Make an average per each test image across all subjects and repetitions.
            % WE NEED TO THINK ABOUT HOW TO MANAGE THE DATA WITHIN THE RANGE BLUE-RED.
            % hueScoreMeanAllSub = mean(hueScoreAllSub,2);
            %
            % Convert hue quadrature (0–400) to radians (0–2π).
            angles = rawDataAllSubjectsMat / 400 * 2 * pi;

            % Compute mean angle using circular statistics
            mean_sin = mean(sin(angles),2);
            mean_cos = mean(cos(angles),2);
            mean_angle = atan2(mean_sin, mean_cos);

            % Convert mean angle back to hue quadrature scale.
            meanDataAllSubjects = mod(mean_angle, 2*pi) / (2*pi) * 400;
        case {'lightness','colorfulness'}
            meanDataAllSubjects = mean(rawDataAllSubjectsMat,2);
    end
    % meanDataAllSubjects = mean(rawDataAllSubjectsMat,2);

    % Make a loop for all subjects.
    for ss = 1:nSubjects
        % Get subject name.
        subjectName = targetSubjectsNames{ss};

        % Get one subject data.
        rawDataOneSubject_temp = rawDataAllSubjectsMeanRepeats{ss};

        % Calculate the correlation coefficient between one subject data and mean.
        r_matrix = corrcoef(rawDataOneSubject_temp,meanDataAllSubjects);
        r_acrossSubjects(ss) = r_matrix(1,2);

        % Plot it here.
        subplot(ceil(nSubjects/5),nColumnsSubplot,ss); hold on;
        plot(meanDataAllSubjects,rawDataOneSubject_temp(:,1),'r.');
        plot(axisLim,axisLim,'k-');
        axis square;
        xlabel(append(strAxesData,' (mean)'));
        ylabel(append(strAxesData,' (individual)'));
        xlim(axisLim);
        ylim(axisLim);

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

    % Choose which cluster to choose.
    if ii == 25
        numCluster = 2;
    elseif ii == 27
        numCluster = 2;
    elseif ii == 28
        numCluster = 3;
    else
        numCluster = 1;
    end

    % Calculation happens here.
    XYZ_targetObject = GetImageDominantColor(image,segmentData,M_RGBToXYZ,gamma_display,XYZ_white,...
        'nClusters',nClusters,'numCluster',numCluster,'nReplicates',nReplicates,...
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
CAM16_J = JCH_targetObject(1,:);
CAM16_C = JCH_targetObject(2,:);
CAM16_H = JCH_targetObject(3,:);

% Set it differently per experiment mode.
switch expMode
    case 'hue'
        CAM16_values = CAM16_H;
    case 'lightness'
        CAM16_values = CAM16_J;
    case 'colorfulness'
        CAM16_values = CAM16_C;
end
%% Comparison between experiment results vs. CAM16 estimations.
switch expMode
    case 'hue'
        % Match the scale between CAM16 H values and the experimental results. As H
        % has a circular scale, some values might be off-scale. For example, if we
        % have a pair of the values, 32 and 385, we will convert them to 432
        % (32+400) and 385. It's preferred to add 400 to match the scale to avoid
        % any negative values.
        rawDataAllSubjectsCleanedMat = rawDataAllSubjectsMat;
        for ss = 1:nSubjects
            rawDataOneSubjectMat = rawDataAllSubjectsMat(:,ss);
            deltaHue = CAM16_values'-rawDataOneSubjectMat;

            % We set the criteria of the weird values that has over 100 of
            % difference in Hue quadrature (H).
            deltaHue_weird = 300;
            idxWeired = find(abs(deltaHue)>deltaHue_weird);

            % We will update the weird value one by one in the loop.
            for ww = 1:length(idxWeired)
                % Find the index of the weird values (where the value is
                % different over 100, which does not make sense).
                idxWeiredTemp = idxWeired(ww);
                CAM16_values_temp = CAM16_values(idxWeiredTemp);
                rawData_temp = rawDataOneSubjectMat(idxWeiredTemp);

                % We will update the values of the subjects' evaluation
                % while keeping the same of the CAM16 values.
                if rawData_temp < CAM16_values_temp
                    rawData_temp = rawData_temp + 400;
                else
                    rawData_temp = rawData_temp - 400;
                end

                % Update the value here and save it in an updated array.
                rawDataAllSubjectsCleanedMat(idxWeiredTemp) = rawData_temp;
            end
        end

        % We will just pass the raw data for colorfulness and lightness.
    case {'lightness','colorfulness'}
        rawDataAllSubjectsCleanedMat = rawDataAllSubjectsMat;
end

% Calculate the mean of all subjects here.
% IT HAPPENS ABOVE WHEN CHECKING THE REPRODUCIBILITY.
% meanDataAllSubjects = mean(rawDataAllSubjectsCleanedMat,2);

% Plot it.
figure; hold on;

% Error bar.
ERRORBAR = 'stderror';

n = size(rawDataAllSubjectsMat,2);
stdAllSubjects = std(rawDataAllSubjectsMat');
stdErrorAllSubjects = stdAllSubjects/sqrt(n);

switch ERRORBAR
    case 'stderror'
        hueScore_errorbar_plot = stdErrorAllSubjects;
    case 'std'
        hueScore_errorbar_plot = stdAllSubjects;
end
errorbar(meanDataAllSubjects, CAM16_values, ...
    [], [], hueScore_errorbar_plot, hueScore_errorbar_plot,...
    'LineStyle','none','Color','k');

% Mean comparison.
f_data = plot(meanDataAllSubjects,CAM16_values,'o',...
    'markeredgecolor','k','markerfacecolor','g','markersize',8);

% Calculate delta hue.
mean_delta_CAM16 = mean(abs(CAM16_values'-meanDataAllSubjects));

% Correlation.
r_meanHue = corr(meanDataAllSubjects,CAM16_values');

% 45-deg line.
plot(axisLim,axisLim,'k-');

% Figure stuff.
xlabel(strAxesData,'fontsize',15);
ylabel(strAxesCAM16,'fontsize',15);
xlim(axisLim);
ylim(axisLim);
axis square;
grid on;
legend(f_data,'Images','location','southeast');
title('CAM16 vs. Mean results');
subtitle(sprintf('nSubjects = (%d) / nTestImages = (%d) / Mean delta = (%.2f)',nSubjects,nTestImagesToCompare,mean_delta_CAM16));

%% Plot the individual results compared with CAM16.
figure;
sgtitle(sprintf('CAM16 vs. Inidividual results \n nTestImages = (%d)',nTestImagesToCompare));
for ss = 1:nSubjects
    % Get the subject name.
    subjectName = targetSubjectsNames{ss};

    % Make a separate plot per subject.
    subplot(ceil(nSubjects/nColumnsSubplot),nColumnsSubplot,ss); hold on;
    plot(rawDataAllSubjectsCleanedMat(:,ss),CAM16_values,'o',...
        'markeredgecolor','k','markerfacecolor','g','markersize',4);
    plot(axisLim,axisLim,'k-');

    xlabel(strAxesData);
    ylabel(strAxesCAM16);
    xlim(axisLim);
    ylim(axisLim);
    axis square;
    grid on;
    if (SUBJECTANON)
        title(sprintf('Subject %d',ss));
    else
        title(subjectName);
    end
end
