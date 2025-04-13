% NCAM_ImageAnalysis.
%
% This routine tests out some color stuff on the images. This will be
% eventually added to the data analysis routine.
%
% See also:
%    NCAM_DataAnalysis.m.

% History:
%    04/11/25    smo       - Started on it.

%% Initialize.
clear; close all;

%% Set variables.
%
% Set which image to explore.
numImage = 10;

% Set directory.
sysInfo = GetComputerInfo();
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
imageFiledir = fullfile(baseFiledir,projectName,'images','segmentation','images_labeled');
segmentationFiledir = fullfile(baseFiledir,projectName,'images','segmentation','segmentation_labeled');

% Get available image names.
imageFileList = dir(imageFiledir);
imageNameList = {imageFileList.name};
imageNameOptions = imageNameList(~startsWith(imageNameList,'.'));

% Get available segmentation names.
segFileList = dir(segmentationFiledir);
segNameList = {segFileList.name};
segNameOptions = segNameList(~startsWith(segNameList,'.'));

% Display parameters.
displayType = 'EIZO';
switch displayType
    case 'EIZO'
        M_RGBToXYZ =  [62.1997 22.8684 19.2310;...
            28.5133 78.5446 6.9256;...
            0.0739 6.3714 99.5962];
        gamma_display = 2.1904;

        XYZ_white = sum(M_RGBToXYZ,2);
end

%% Check out the image segmentations.
imageFilename = imageNameOptions{numImage};
image = imread(fullfile(imageFiledir,imageFilename));

% Display which image is being analyzed.
[path imageName ext] = fileparts(imageFilename);
fprintf('Current image - (%s) \n',imageName);

% Read out segmentation data.
segFilename = segNameOptions{numImage};
fid = fopen(fullfile(segmentationFiledir,segFilename),"r");
segmentData = textscan(fid, '%f %s %f %f %f %f %f', 'Delimiter', ',', 'HeaderLines', 1);
fclose(fid);

% Get dominant color.
XYZ_dominantColor = GetImageDominantColor(image,segmentData,M_RGBToXYZ,gamma_display,XYZ_white);
