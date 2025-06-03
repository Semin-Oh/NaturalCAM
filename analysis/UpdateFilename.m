% UpdateFilename.
%
% This routine updates the file name to match between the test images and
% their corresponding segmentation files.

% History:
%    04/11/25    smo    - Simple routine to match the file name.
%    04/13/25    smo    - This routine is running, but it is not working as
%                         planned. We will not use it for now, but we may
%                         use it later on after elaborate it.

%% Initialize.
clear; close all;

%% Get the image and segmentation folders.
%
% Image file dir.
%
% Office mac.
filedir_image_org = '/Users/semin/Dropbox (Personal)/JLU/2) Projects/NaturalCAM/images/segmentation/images_original';
filedir_image_label = '/Users/semin/Dropbox (Personal)/JLU/2) Projects/NaturalCAM/images/segmentation/images_labeled';

% Semin's laptop.
% filedir_image_org = '/Users/ohsem/Dropbox (Personal)/JLU/2) Projects/NaturalCAM/images/segmentation/images_original';
% filedir_image_label = '/Users/ohsem/Dropbox (Personal)/JLU/2) Projects/NaturalCAM/images/segmentation/images_labeled';

% Segmentation file dir.
%
% Office mac.
filedir_seg_org = '/Users/semin/Dropbox (Personal)/JLU/2) Projects/NaturalCAM/images/segmentation/segmentation_original';
filedir_seg_label = '/Users/semin/Dropbox (Personal)/JLU/2) Projects/NaturalCAM/images/segmentation/segmentation_labeled';

% Semin's laptop.
% filedir_seg_org = '/Users/ohsem/Dropbox (Personal)/JLU/2) Projects/NaturalCAM/images/segmentation/segmentation_original';
% filedir_seg_label = '/Users/ohsem/Dropbox (Personal)/JLU/2) Projects/NaturalCAM/images/segmentation/segmentation_labeled';

%% Get the image names and CoCo code names.
%
% Get the avaialble image file names.
imageFileList = dir(filedir_image_label);
imageNameOptions = {imageFileList.name};
imageNameOptions = imageNameOptions(~startsWith(imageNameOptions,'.'));

% Get an available original coded file names. This comes in an ascending
% order.
list = dir(filedir_image_org);
imageCodeOptions = {list.name};
imageCodeOptions = imageCodeOptions(~startsWith(imageCodeOptions,'.'));

% Get only numbers of the image codes.
for ii = 1:length(imageCodeOptions)
    imageCodeTemp = imageCodeOptions{ii};
    tokens = regexp(imageCodeTemp, '(.*?).jpg', 'tokens');
    imageCodeNumberOnly{ii} = regexprep(tokens{1}{1},'^0+','');
end

% Get all available segmentation file names.
list = dir(filedir_seg_org);
segCodeOptions = {list.name};
segCodeOptions = segCodeOptions(~startsWith(segCodeOptions,'.'));

%% Find the CoCo object label per each image.
%
% Available label can be more than one. This is for sanity check for
% further search.
for ii = 1:length(segCodeOptions)
    segCodeTemp = segCodeOptions{ii};

    % Get a label from the name.
    tokens = regexp(segCodeTemp, 'image_(.*?)_(.*?)_pixels', 'tokens');
    
    % Save code.
    segObjectCodes{ii} = tokens{1}{1};
    % Save label name.
    segObjectLabels{ii} = tokens{1}{2};
end

%% Find the matching image name based on the image size.
nCodeOptions = length(imageCodeOptions);
for ii = 1:nCodeOptions
    % Get the image code name and get the image info.
    imageCodenameTemp = imageCodeOptions{ii};
    imageInfoOrgCode = imfinfo(fullfile(filedir_image_org,imageCodenameTemp));

    % Get the object labels for segmentation data. This will be used for a
    % sanity check.
    ttt = 1;
    while true
        if contains(imageCodenameTemp,segObjectCodes{ttt})
           idxLabel = ttt;
            break;
        end
        ttt = ttt+1;
    end
    segCodeImageLabelTemp = segObjectLabels{idxLabel};

    ll = 1;
    while true
        % Read out custom-labeled image one by one to check if each has the
        % identical size with the image above.
        imageNameTemp = imageNameOptions{ll};
        imageInfoLabel = imfinfo(fullfile(filedir_image_label,imageNameTemp));

        % Check if the size of the image matches.
        if (imageInfoOrgCode.Width == imageInfoLabel.Width...
                && imageInfoOrgCode.Height == imageInfoLabel.Height)
            disp('Image size matched!');

            % If the image size matches, check if the name has a corresponding object label.
            if contains(imageNameTemp,segCodeImageLabelTemp)
                imageNameMatchOptions{ii} = imageNameTemp;
                break;
            end
        end

        % Show progress.
        fprintf('In process (%d/%d) finding a matching image name - (%s) - %d \n',ii,nCodeOptions,imageNameTemp,ll);
        
        % Keep counting.
        ll = ll+1;
    end
end

% Update the segment file names.
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
