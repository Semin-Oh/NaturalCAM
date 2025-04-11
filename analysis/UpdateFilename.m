% UpdateFilename.
%
% This routine updates the file name to match between the test images and
% their corresponding segmentation files.

% History:
%    04/11/25    smo    - Simple routine to match the file name.

%% Initialize.
clear; close all;

%% Get the image and segmentation folders.
%
% Image file dir.
filedir_image_org = '/Users/semin/Dropbox (Personal)/JLU/2) Projects/NaturalCAM/images/segmentation/images_original';
filedir_image_label = '/Users/semin/Dropbox (Personal)/JLU/2) Projects/NaturalCAM/images/segmentation/images_labeled';

% Segmentation file dir.
filedir_seg_org = '/Users/semin/Dropbox (Personal)/JLU/2) Projects/NaturalCAM/images/segmentation/segmentation_original';
filedir_seg_label = '/Users/semin/Dropbox (Personal)/JLU/2) Projects/NaturalCAM/images/segmentation/segmentation_labeled';

%% Find the matching image file name. We will search it based on the file
% size which is unique to each image.
%
% Get the avaialble image file names.
imageFileList = dir(filedir_image_label);
imageNameOptions = {imageFileList.name};
imageNameOptions = imageNameOptions(~startsWith(imageNameOptions,'.'));

% Get an available original coded file names.
list = dir(filedir_image_org);
imageCodeOptions = {list.name};
imageCodeOptions = imageCodeOptions(~startsWith(imageCodeOptions,'.'));

% Get all available segmentation file names.
list = dir(filedir_seg_org);
segCodeOptions = {list.name};
segCodeOptions = segCodeOptions(~startsWith(segCodeOptions,'.'));

% Find the CoCo object label from the file name per each image.
for ii = 1:length(segCodeOptions)
    segCodeTemp = segCodeOptions{ii};

    % Get a label from the name.
    tokens = regexp(segCodeTemp, 'image_\d+_(.*?)_pixels', 'tokens');
    segObjectLabels{ii} = tokens{1}{1};
end

% Find the matching image name based on the image size.
for ii = 1:length(imageCodeOptions)
    % Read out 
    imageCodenameTemp = imageCodeOptions{ii};
    imageInfoOrgCode = imfinfo(fullfile(filedir_image_org,imageCodenameTemp));
        
    % Get the object labels for segmentation data.
    segCodeImageLabelTemp = segObjectLabels{ii};

    ll = 1;
    while true
        imageNameTemp = imageNameOptions{ll};
        imageInfoLabel = imfinfo(fullfile(filedir_image_label,imageNameTemp));

        % Check the size of the image and save the name that matches the
        % size.
        %
        % Update: there are the same file size for different images. Here
        % we additionally check it the object label is correct.
        if imageInfoOrgCode.Width == imageInfoLabel.Width && imageInfoOrgCode.Height == imageInfoLabel.Height

            % Check if the name matches the object label.
            if contains(imageNameTemp,segCodeImageLabelTemp)
                imageNameMatchOptions{ii} = imageNameTemp;
                break;
            else
                ll = ll+1;
                fprintf('progress - %d \n',ll);
            end
        else
            ll = ll+1;
            fprintf('progress - %d \n',ll);
        end
    end
end

% Update the segment file names.
for ii = 1:length(segCodeOptions)
    segCodeTemp = segCodeOptions{ii};
    imageNameMatchTemp = imageNameMatchOptions{ii};

    % Set the names old and new.
    oldname = fullfile(filedir_seg_org,segCodeTemp);
    newname = fullfile(filedir_seg_label,imageNameMatchTemp);

    % Update the file name. We will keep the original so that we can use
    % the same image with different labels.
    copyfile(oldname,newname);
end
