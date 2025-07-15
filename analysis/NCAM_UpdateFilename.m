% NCAM_UpdateFilename.
%
% This routine updates the file name to match between the test images and
% their corresponding segmentation files.

% History:
%    04/11/25    smo    - Simple routine to match the file name.
%    04/13/25    smo    - This routine is running, but it is not working as
%                         planned. We will not use it for now, but we may
%                         use it later on after elaborate it.
%    07/15/25    smo    - Now find the corresponding image name based on
%                         the comparison of the image itself. It works
%                         well.

%% Initialize.
clear; close all;

%% Set directories where the segmentation files are.
whichComputer = 'office';

% Set it based on which computer you are using.
switch whichComputer
    % Semin's office mac.
    case 'office'
        filedir_image_org = '/Users/semin/Dropbox (Personal)/JLU/2) Projects/NaturalCAM/images/segmentation/images_original';
        filedir_image_label = '/Users/semin/Dropbox (Personal)/JLU/2) Projects/NaturalCAM/images/segmentation/images_labeled';
        filedir_seg_org = '/Users/semin/Dropbox (Personal)/JLU/2) Projects/NaturalCAM/images/segmentation/segmentation_original';
        filedir_seg_label = '/Users/semin/Dropbox (Personal)/JLU/2) Projects/NaturalCAM/images/segmentation/segmentation_labeled';

        % Semin's personal laptop.
    case 'personal'
        filedir_image_org = '/Users/ohsem/Dropbox (Personal)/JLU/2) Projects/NaturalCAM/images/segmentation/images_original';
        filedir_image_label = '/Users/ohsem/Dropbox (Personal)/JLU/2) Projects/NaturalCAM/images/segmentation/images_labeled';
        filedir_seg_org = '/Users/ohsem/Dropbox (Personal)/JLU/2) Projects/NaturalCAM/images/segmentation/segmentation_original';
        filedir_seg_label = '/Users/ohsem/Dropbox (Personal)/JLU/2) Projects/NaturalCAM/images/segmentation/segmentation_labeled';
end

%% Get the image names and CoCo code names.
%
% Get the avaialble image file names.
filedir_imageNames = '/Users/semin/Dropbox (Personal)/JLU/2) Projects/NaturalCAM/images';
filename_imageNames = 'imageNames.mat';
imageNamesData = load(fullfile(filedir_imageNames,filename_imageNames));
imageNameOptions = imageNamesData.imageNames;
imageNameOptions = strrep(imageNameOptions, '.png', '.jpg');

% Get an available original coded file names. This comes in an ascending
% order.
list = dir(filedir_image_org);
imageCodeOptions = {list.name};
imageCodeOptions = imageCodeOptions(~startsWith(imageCodeOptions,'.'));

%% Here, we find the corresponding image name per each image code.
%
% We did experiment by naming each image like apple1, carrot1, etc. We will
% link each name to the original code from the CoCo image dataset (e.g.
% 000000018150.jpg). The strategy here is to compare the image one-to-one
% and find the equal image.
nImageNames = length(imageNameOptions);
for ii = 1:nImageNames
    % Read an image with labeled (e.g. apple1, carrot1, etc.).
    imageNameTemp = imageNameOptions{ii};
    image_labeled = imread(fullfile(filedir_image_label,imageNameTemp));

    % Read an image with original code of CoCo dataset (e.g.
    % 000000018150.jpg);
    cc = 1;
    while true
        imageCodeTemp = imageCodeOptions{cc};
        image_coded = imread(fullfile(filedir_image_org,imageCodeTemp));

        % Check if the image has the same size.
        if isequal(image_labeled,image_coded)
            % Save out the name.
            imageCodeOptionsMatched{ii} = imageCodeTemp;
            fprintf('Identical image found! (%s) - (%d/%d) \n',imageNameTemp,ii,nImageNames);
            break;
        end

        % Keep going until it finds the indentical image.
        cc = cc + 1;
    end
end

% Get only numbers of the image codes. Again, it's sorted in the same order
% as the labeled image names.
nImageCodes = length(imageCodeOptionsMatched);
for ii = 1:nImageCodes
    imageCodeTemp = imageCodeOptionsMatched{ii};
    tokens = regexp(imageCodeTemp, '(.*?).jpg', 'tokens');
    imageCodeNumberOnly{ii} = regexprep(tokens{1}{1},'^0+','');
end

%% Find the CoCo object label per each image.
%
% Get all available segmentation file names.
list = dir(filedir_seg_org);
segCodeOptions = {list.name};
segCodeOptions = segCodeOptions(~startsWith(segCodeOptions,'.'));

% Available label can be more than one. This is for sanity check for
% further search.
nSegmentsData = length(segCodeOptions);
for ii = 1:nSegmentsData
    segCodeTemp = segCodeOptions{ii};

    % Get a label from the name.
    tokens = regexp(segCodeTemp, 'image_(.*?)_(.*?)_pixels', 'tokens');
    % tokens = regexp(segCodeTemp,'\d+','match');

    % Save code.
    segObjectCodes{ii} = tokens{1}{1};

    % Save label name.
    segObjectLabels{ii} = tokens{1}{2};
end

%% Find the matching image name.
for ss = 1:nSegmentsData
    % Get the index in the sorted code names.
    segObjectCodeTemp = segObjectCodes{ss};
    idx = find(strcmp(imageCodeNumberOnly,segObjectCodeTemp));

    % Check if the names matches the label.
    segObjectLabelTemp = segObjectLabels{ss};
    imageNameTemp = imageNameOptions(idx);

    % Make a loop for the same image to find the right label.
    nIndex = length(idx);
    for xx = 1:nIndex
        imageNameTempOne = imageNameTemp{xx};
        if contains(imageNameTempOne,segObjectLabelTemp)
            imageNameMatchOptions{ss} = imageNameTempOne;
        end
    end
end

%% Update the segment file names.
for ii = 1:length(imageNameMatchOptions)
    segCodeTemp = segCodeOptions{ii};
    imageNameMatchTemp = imageNameMatchOptions{ii};
    [path imageNameOnly ext] = fileparts(imageNameMatchTemp);

    % Set the names old and new.
    newExt = '.csv';
    oldname = fullfile(filedir_seg_org,segCodeTemp);
    newname = fullfile(filedir_seg_label,append(imageNameOnly,newExt));

    % Update the file name. We will keep the original so that we can use
    % the same image with different labels.
    copyfile(oldname,newname);
end
disp('Files with updated names are successfully generated!')
