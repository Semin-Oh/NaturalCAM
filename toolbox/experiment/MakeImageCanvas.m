function [canvas imageProfile] = MakeImageCanvas(testImage,options)
% Make an image canvas with given input image.
%
% Syntax:
%    [canvas] = MakeImageCanvas(image)
%
% Description:
%    This routine generates an image canvas based on the image that is
%    given as an input. The output canvas contains three images in parallel
%    horizontally where each image is either mixed with stripes or color
%    corrected.
%
%    We wrote this routine to generate test stimuli for Color Assimilation
%    project.
%
% Inputs:
%    image                    - An input image to generate a canvas. This
%                               can be empty ('[]') if you want to generate
%                               canvas without image.
%
% Outputs:
%    canvas                   - Output image with three corrected images.
%                               This image should be ready to present using
%                               psychtoolbox for the project.
%    imageProfile
%
% Optional key/value pairs:
%    testImageSize            - Decide the size of the test images. It
%                               is decided by the ratio of the height of
%                               the canvas. Default to 0.40.
%    addImageRight            - When it sets to true, add a mirrored image
%                               on the right side of the canvas and place
%                               the color corrected image on the center.
%                               Default to false.
%    stripeHeightPixel        - Define the height of each horizontal stripe
%                               on the background of the cavas. It's in
%                               pixel unit and default to 5.
%    whichColorStripes        - Define the color of stripes to place on top
%                               of the image. This will make color
%                               assimilation phenomena. Choose among 'red',
%                               'green', 'blue'. Default to 'red'.
%    intensityStripe          - Decide the intensity of the stripe in
%                               pixel. For now, it is decided on 8-bit
%                               system, so it should be within the range of
%                               0-255. Default to 255, the maximum.
%    position_leftImage_x     - Define the position of the left sided image
%                               on the canvas. This will decide the
%                               positions of all three images on the
%                               canvas. Choose between 0 to 1, where 0.5
%                               means the center of the canvas, 0 is the
%                               left end and 1 is the right end. Default to
%                               0.1
%    sizeCanvas               - Decide the size of the canvas to generate.
%                               It may be matched with the screen size that
%                               you want to present the image. Default to
%                               [1920 1080] as [width height] of the
%                               screen in pixe.
%    colorCorrectMethod       - Decide the color correcting method that
%                               corresponds to the test image with stripes
%                               on. Default to 'mean'.
%    intensityColorCorrect    - Decide the color correction power on
%                               the test image. If it sets to empty, the
%                               amount of color correction would be solely
%                               decided by the ratio of the stripes on the
%                               image with stripes. Default to empty.
%    verbose                  - Control the plot and alarm messages.
%                               Default to false.
%
% See also:
%    MakeImageCanvas_demo.

% History:
%    04/09/24    smo    - Made it as a function.
%    04/16/24    smo    - Added a new color correction method after meeting
%                         with Karl.
%    04/25/24    smo    - Added an option to make a canvas without image so
%                         that we can generate a null canvas with only
%                         stripes.
%    06/19/24    smo    - Added an option to control the intensity of the
%                         color correction after meeting with Karl.
%    07/29/24    smo    - Substituting the part converting from the digital
%                         RGB to the CIE XYZ values with the function.
%    09/23/24    smo    - Now we can either put two or three images on the
%                         canvas.
%    10/01/24    smo    - Added a color correction on the u'v' coordinates.
%    10/14/24    smo    - Added the image profile as a function output. It
%                         contains the color coordinates of the test
%                         images. Also, deleted the old method to color
%                         correct the test images, so-called 'addRGB'.
%    10/15/24    smo    - Added a feature to correct the overall brightness
%                         of an original test image so that we can maintain
%                         the mean luminance as close as possible across
%                         the different levels of the color corrections.
%    10/29/24    smo    - Color correction part has been substituted with
%                         a function.
%    11/05/24    smo    - Now the image is set to the same size before
%                         placing it on the canvas.
%    11/26/24    smo    - We give tolerance when we crop the actual image
%                         content part so that we don't include the
%                         residual pixels on the edge.

%% Set variables.
arguments
    testImage
    options.whichDisplay = 'curvedDisplay'
    options.ratio_RGB_control_originalImage = 0.75
    options.testImageSize = 0.40
    options.addImageRight = false
    options.stripeHeightPixel (1,1) = 5
    options.whichColorStripes = 'red'
    options.intensityStripe (1,1) = 255
    options.position_leftImage_x (1,1) = 0.1
    options.verbose (1,1) = false
    options.sizeCanvas (1,2) = [1920 1080]
    options.colorCorrectMethod = 'uv'
    options.intensityColorCorrect = 0.33
end

% Define the size of the canvas.
canvas_width = options.sizeCanvas(1);
canvas_height = options.sizeCanvas(2);

% Define the index of the color stripes. This index will control when we
% generate a color corrected image.
colorStripeOptions = {'red','green','blue'};
idxColorStripe = find(strcmp(colorStripeOptions, options.whichColorStripes));

%% Choose which diplay to use.
switch options.whichDisplay
    case 'sRGB'
        % Matrix to convert from the linear RGB to XYZ.
        xyY_displayPrimary = [0.6400 0.3000 0.1500; 0.3300 0.6000 0.0600; 0.2126 0.7152 0.0722];
        M_RGB2XYZ = [0.4124 0.3576 0.1805; 0.2126 0.7152 0.0722; 0.0193 0.1192 0.9505];
        gamma = 2.2;

    case 'curvedDisplay'
        % Gamma and the 3x3 matrix are set based on the RGB channel
        % on the centered display. See detailed calibration results
        % in the routine 'CalDisplay.m'. The values from the
        % routine.
        xyY_displayPrimary = [0.6781 0.2740 0.1574; 0.3084 0.6616 0.0648; 17.0886 61.3867 6.1283];
        M_RGB2XYZ = xyYToXYZ(xyY_displayPrimary);
        gamma = 2.2669;
end

% Get white point.
XYZ_white = sum(M_RGB2XYZ,2);

%% Create a canvas to place images on.
%
% Create a blank canvas.
canvas = zeros(canvas_height, canvas_width, 3);

% Process this part only when we have the test image as input.
if ~isempty(testImage)
    % Find the actual image content. This will help to keep the image size
    % similar across different test images.
    testImage = DetectImageContent(testImage);

    % Get the size of original input image.
    [originalImage_height originalImage_width ~] = size(testImage);
    ratioWidthToHeight_original = originalImage_width/originalImage_height;

    % Define the size of the test image. For now, we keep the original
    % height:width ratio. We will round up so that we make sure image size
    % in integer number in pixel.
    testImage_height = ceil(canvas_height * options.testImageSize);
    testImage_width = ceil(testImage_height * ratioWidthToHeight_original);

    % Resize the test image to fit in the canvas.
    testImageRaw = imresize(testImage, [testImage_height, testImage_width]);

    % Find the location where the image content exist. The idea here is to
    % find the background color in the very first pixel of the image
    % (1,1,:) and the pixels with this color be excluded in this index. So,
    % when preparing the raw test images, it is advised to set the
    % background color distinctive from the face and hair colors. Orange
    % color as a background (dRGB = 255, 87, 34) would work pretty well.
    %
    % Therefore, the number of pixels of the image content is the same as
    % the length of either 'idxImageHeight' or 'idxImageWidth'.
    idxImageHeight = [];
    idxImageWidth = [];
    bgSetting = squeeze(testImage(1,1,:));

    % We will give tolerance to detect the image content so that we can not
    % include the residual parts of the edges of the image content.
    bgTolerance = 30;
    bgSettingLow = bgSetting-bgTolerance;
    bgSettingHigh = bgSetting+bgTolerance;

    % Here, we will extract the pixels that does not match with the color
    % of the background, which is the actual image.
    for hh = 1:testImage_height
        for ww = 1:testImage_width
            areAllEqual = (testImageRaw(hh,ww,1)>bgSettingLow(1) && testImageRaw(hh,ww,1)<=bgSettingHigh(1))...
                & (testImageRaw(hh,ww,2)>bgSettingLow(2) && testImageRaw(hh,ww,2)<=bgSettingHigh(2))...
                & (testImageRaw(hh,ww,3)>bgSettingLow(3) && testImageRaw(hh,ww,3)<=bgSettingHigh(3));
            if ~(areAllEqual)
                idxImageHeight(end+1) = hh;
                idxImageWidth(end+1) = ww;
            end
        end
    end

    % Control the brightness of the original image here. If we lower the
    % brightness of the image for a bit, the performance of the color
    % correction increases as we minimizes the number of the pixels
    % distributing outside the display gamut. The ratio_RGB_control should
    % be within 0 and 1.
    testImageRaw = testImageRaw .* options.ratio_RGB_control_originalImage;

    %% Image on the left.
    %
    % Set the position to place the original image. The locations of the
    % following images will be automatically updated based on this. For now, we
    % always put all images at the center of the horizontal axis (set
    % position_testImage_y to 0.5).
    position_testImage_x = options.position_leftImage_x;
    position_testImage_y = 0.5;
    testImage_x = floor((canvas_width - testImage_width) * position_testImage_x) + 1;
    testImage_y = floor((canvas_height - testImage_height) * position_testImage_y) + 1;
end

%% Add stripes on the background.
%
% Generate the background with horizontal stripes
for i = 1 : options.stripeHeightPixel : canvas_height
    if mod(floor(i/options.stripeHeightPixel), 3) == 0
        % Red
        canvas(i:i+options.stripeHeightPixel-1, :, 1) = options.intensityStripe;
    elseif mod(floor(i/options.stripeHeightPixel), 3) == 1
        % Green.
        canvas(i:i+options.stripeHeightPixel-1, :, 2) = options.intensityStripe;
    else
        % Blue.
        canvas(i:i+options.stripeHeightPixel-1, :, 3) = options.intensityStripe;
    end
end

% Place the main image onto the canvas
if ~isempty(testImage)
    for ii = 1:length(idxImageHeight)
        canvas(testImage_y+idxImageHeight(ii)-1, testImage_x+idxImageWidth(ii)-1, :) = testImageRaw(idxImageHeight(ii),idxImageWidth(ii),:);
    end
end

%% We will add the same image with stripes on the right if we want.
%
% Put another image before the next section so that both images could place
% before the lines.
if ~isempty(testImage)
    if (options.addImageRight)
        % Set the image location.
        position_centerImage_x = 1-position_testImage_x;
        position_centerImage_y = 0.5;
        centerImage_x = floor((canvas_width - testImage_width) * position_centerImage_x) + 1;
        centerImage_y = floor((canvas_height - testImage_height) * position_centerImage_y) + 1;

        % Place the main image onto the canvas
        for ii = 1:length(idxImageHeight)
            canvas(centerImage_y+idxImageHeight(ii)-1, centerImage_x+idxImageWidth(ii)-1, :) = testImageRaw(idxImageHeight(ii),idxImageWidth(ii),:);
        end
    end

    %% Draw one color of the stripes on top of the image.
    %
    % This part will simulate the color assimilation phenomena.
    %
    % Add stripe on top of the image here.
    for i = 1 : options.stripeHeightPixel : canvas_height
        switch options.whichColorStripes
            case 'red'
                if mod(floor(i/options.stripeHeightPixel), 3) == 0
                    canvas(i:i+options.stripeHeightPixel-1, :, 1) = options.intensityStripe;
                    canvas(i:i+options.stripeHeightPixel-1, :, 2) = 0;
                    canvas(i:i+options.stripeHeightPixel-1, :, 3) = 0;
                end
            case 'green'
                if mod(floor(i/options.stripeHeightPixel), 3) == 1
                    canvas(i:i+options.stripeHeightPixel-1, :, 1) = 0;
                    canvas(i:i+options.stripeHeightPixel-1, :, 2) = options.intensityStripe;
                    canvas(i:i+options.stripeHeightPixel-1, :, 3) = 0;
                end
            case 'blue'
                if mod(floor(i/options.stripeHeightPixel), 3) == 2
                    canvas(i:i+options.stripeHeightPixel-1, :, 1) = 0;
                    canvas(i:i+options.stripeHeightPixel-1, :, 2) = 0;
                    canvas(i:i+options.stripeHeightPixel-1, :, 3) = options.intensityStripe;
                end
        end
    end

    %% Make color corrected image.
    %
    % Get the cropped part of the test image. This image still has the stripes
    % on the background.
    testImageCrop = canvas(testImage_y:testImage_y+testImage_height-1, testImage_x:testImage_x+testImage_width-1, :);

    % Extract the test image where single stripe on. This image does not have
    % the stripes on the background, only the part where the test image exist.
    % The size of the images are the same.
    testImageStripe = zeros(size(testImageCrop));
    for ii = 1:length(idxImageHeight)
        testImageStripe(idxImageHeight(ii),idxImageWidth(ii),:) = testImageCrop(idxImageHeight(ii), idxImageWidth(ii), :);
    end

    % Extract color information per each channel.
    %
    % Original image.
    for ii = 1:length(idxImageHeight)
        red_testImage(ii)   = testImageRaw(idxImageHeight(ii),idxImageWidth(ii),1);
        green_testImage(ii) = testImageRaw(idxImageHeight(ii),idxImageWidth(ii),2);
        blue_testImage(ii)  = testImageRaw(idxImageHeight(ii),idxImageWidth(ii),3);
    end
    RGB_testImage = [red_testImage; green_testImage; blue_testImage];

    % Image with stripes.
    for ii = 1:length(idxImageHeight)
        red_testImageStripe(ii)   = testImageStripe(idxImageHeight(ii),idxImageWidth(ii),1);
        green_testImageStripe(ii) = testImageStripe(idxImageHeight(ii),idxImageWidth(ii),2);
        blue_testImageStripe(ii)  = testImageStripe(idxImageHeight(ii),idxImageWidth(ii),3);
    end
    RGB_testImageStripe = [red_testImageStripe; green_testImageStripe; blue_testImageStripe];

    % Calculate the proportion of the pixels that are stripes within
    % the image. This should be close to 1/3 (~33%) as we place three
    % different stripes - red, green, and blue - repeatedly.
    switch options.whichColorStripes
        case 'red'
            targetCh_testImageStripe = red_testImageStripe;
        case 'green'
            targetCh_testImageStripe = green_testImageStripe;
        case 'blue'
            targetCh_testImageStripe = blue_testImageStripe;
    end
    ratioStripes = length(find(targetCh_testImageStripe == options.intensityStripe))./length(targetCh_testImageStripe);

    % We color correct the original image. We get the resized original
    % image and correct color in the next step to this image.
    testImageColorCorrect = testImageRaw;

    % Here we choose which method to color correct the image.
    switch options.colorCorrectMethod
        case 'RGB'
            % Color correction happens here. The results of this have the
            % colored background.
            colorCorrectionPerPixelOneChannel = options.intensityColorCorrect .* (options.intensityStripe - testImageRaw(:,:,idxColorStripe));
            testImageColorCorrect(:,:,idxColorStripe) = testImageColorCorrect(:,:,idxColorStripe) + colorCorrectionPerPixelOneChannel;

            % Extract the pixels where the image is. The results of this
            % would have the black background.
            testImageColorCorrect_extract = zeros(size(testImageColorCorrect));
            for ii = 1:length(idxImageHeight)
                testImageColorCorrect_extract(idxImageHeight(ii),idxImageWidth(ii),:) = testImageColorCorrect(idxImageHeight(ii),idxImageWidth(ii),:);
            end
            testImageColorCorrect = testImageColorCorrect_extract;

            % Get color information of the color corrected image for comparison.
            for ii = 1:length(idxImageHeight)
                red_colorCorrectedImage(ii)   = testImageColorCorrect(idxImageHeight(ii),idxImageWidth(ii),1);
                green_colorCorrectedImage(ii) = testImageColorCorrect(idxImageHeight(ii),idxImageWidth(ii),2);
                blue_colorCorrectedImage(ii)  = testImageColorCorrect(idxImageHeight(ii),idxImageWidth(ii),3);
            end
            RGB_colorCorrectedImage = [red_colorCorrectedImage; green_colorCorrectedImage; blue_colorCorrectedImage];

            % The other channels. Commented out for now, we can think about
            % correcting the other channels as well. When we also correct
            % the other channels, it basically gives the same result as the
            % above 'mean' method. It makes the test image a little too
            % saturated by eye. The number 2 and 3 should be updated below
            % to make it work correctly per different target channel.
            %
            % colorCorrectionPerPixelOneChannel = ratioColorCorrect .* resized_testImage(:,:,2);
            % colorCorrected_testImage(:,:,2) = colorCorrected_testImage(:,:,2) - colorCorrectionPerPixelOneChannel;
            %
            % colorCorrectionPerPixelOneChannel = ratioColorCorrect .* resized_testImage(:,:,3);
            % colorCorrected_testImage(:,:,3) = colorCorrected_testImage(:,:,3) - colorCorrectionPerPixelOneChannel;

        case 'uv'
            % Convert the original test image from dRGB to u'v'. We will
            % use only the part where actual images are. Backgrounds are
            % not included.
            XYZ_testImage = RGBToXYZ(RGB_testImage,M_RGB2XYZ,gamma);
            uvY_testImage = XYZTouvY(XYZ_testImage);

            % Color correction happens here on the u'v' coordinates. We will
            % correct the color of each pixel in the image proportinally to the
            % primary on the u'v' coordinates.
            %
            % Get the base array in u'v' of the original test image.
            uvY_colorCorrectedImage_target = uvY_testImage;

            % Get u'v' coordinates of the target primary. We will correct
            % the color based on this anchor.
            uv_displayPrimary = xyTouv(xyY_displayPrimary(1:2,:));
            uv_targetColorStripe = uv_displayPrimary(:,idxColorStripe);

            % Color correction happens here. We correct pixel by pixel
            % proportionally from one to the primary anchor by desired
            % ratio. The intensity of color correction could be customized
            % as it's set as an option. The luminance of each pixel will be
            % the same as the original, only chromaticity will be
            % modulated. The variable 'options.intensityColorCorrect'
            % should be within 0-1 and 1 means all chromaticity becomes the
            % same as the primary anchor.
            uvY_colorCorrectedImage_target(1:2,:) = MakeImageShiftChromaticity(uvY_testImage(1:2,:),uv_targetColorStripe,options.intensityColorCorrect);

            % The mean luminance will be set as the same as the striped
            % image.
            %
            % Get the XYZ values of the striped image.
            XYZ_testImageStripe = RGBToXYZ(RGB_testImageStripe,M_RGB2XYZ,gamma);

            % Calculate the ratio to make the target color corrected image
            % to have the same mean luminance value as the striped image.
            mean_XYZ_testImageStripe = mean(XYZ_testImageStripe,2);
            mean_XYZ_testImage = mean(XYZ_testImage,2);
            ratio_mean_Y = mean_XYZ_testImageStripe(2)/mean_XYZ_testImage(2);

            % Multiply the luminance ratio here.
            uvY_colorCorrectedImage_target(3,:) = uvY_colorCorrectedImage_target(3,:) * ratio_mean_Y;

            % Check if the mean luminance is the same.
            mean_uvY_colorCorrectedImage_target = mean(uvY_colorCorrectedImage_target,2);
            criteriaMeanY = 0.01;
            if (mean_uvY_colorCorrectedImage_target(3) - mean_XYZ_testImageStripe(2)) > criteriaMeanY
                error('Mean luminance value mismatch between striped and color corrected images!');
            end

            % Calculate the digital RGB values from the u'v' coordinates to
            % convert it to the color corrected image.
            XYZ_colorCorrectedImage_target = uvYToXYZ(uvY_colorCorrectedImage_target);
            RGB_colorCorrectedImage = XYZToRGB(XYZ_colorCorrectedImage_target,M_RGB2XYZ,gamma);

            % Now Calculate it back to the u'v'. This process is
            % quantizing so that we know how actual image would distribute
            % on the chromaticity coordinates.
            XYZ_colorCorrectedImage = RGBToXYZ(RGB_colorCorrectedImage,M_RGB2XYZ,gamma);
            uvY_colorCorrectedImage = XYZTouvY(XYZ_colorCorrectedImage);

            % TEMP - MEAN LUMINANCE. THIS IS FOR CHECKING HOW MUCH THE MEAN
            % LUMINANCE CHANGES OVER THE DIFFERENT LEVEL OF COLOR
            % CORRECTIONS.
            mean_uvY_colorCorrectedImage = mean(uvY_colorCorrectedImage,2);
            ratio_Y = mean_uvY_colorCorrectedImage_target(3)/mean_uvY_colorCorrectedImage(3);

            % If luminance is fall off on the color corrected image, throw an error.
            diff_ratio_Y = abs(1-ratio_Y);
            criteria_ratio_Y = 0.05;
            if diff_ratio_Y > criteria_ratio_Y
                fprintf('Luminance ratio = (%.2f) \n',ratio_Y);
                fprintf('Mean luminance of the striped image = (%.2f) cd/m2 \n',mean_uvY_colorCorrectedImage_target(3));
                fprintf('Mean luminance of the color corred image = (%.2f) cd/m2 \n',mean_uvY_colorCorrectedImage(3));

                error('Color corrected image cannot be generated well for this color correction intensity');
            end

            % Get digital RGB values per each channel. We will use it to
            % plot the image profile in the end.
            red_colorCorrectedImage = RGB_colorCorrectedImage(1,:);
            green_colorCorrectedImage = RGB_colorCorrectedImage(2,:);
            blue_colorCorrectedImage = RGB_colorCorrectedImage(3,:);

            % Back to the image. Idea here is getting the original test
            % image as a base array and update the pixels where actual
            % images are.
            testImageColorCorrect = testImageRaw;
            for ii = 1:length(idxImageHeight)
                testImageColorCorrect(idxImageHeight(ii),idxImageWidth(ii),1) = RGB_colorCorrectedImage(1,ii);
                testImageColorCorrect(idxImageHeight(ii),idxImageWidth(ii),2) = RGB_colorCorrectedImage(2,ii);
                testImageColorCorrect(idxImageHeight(ii),idxImageWidth(ii),3) = RGB_colorCorrectedImage(3,ii);
            end
    end

    % Make image with no background for plot.
    for ii = 1:length(idxImageHeight)
        testImageRaw_noBG(idxImageHeight(ii),idxImageWidth(ii),:) = testImageRaw(idxImageHeight(ii), idxImageWidth(ii), :);
        testImageColorCorrect_noBG(idxImageHeight(ii),idxImageWidth(ii),:) = testImageColorCorrect(idxImageHeight(ii), idxImageWidth(ii), :);
    end

    % Display the images if you want.
    if (options.verbose)
        % Make a new figure.
        figure;

        % Original image.
        subplot(1,3,1);
        imshow(uint8(testImageRaw_noBG));
        title('Original');

        % Image with stripes.
        subplot(1,3,2);
        imshow(uint8(testImageStripe));
        title('Stripes-on');

        % Color corrected image.
        subplot(1,3,3);
        imshow(uint8(testImageColorCorrect_noBG));
        title('Color-corrected');
    end

    %% Now add the color corrected image to the canvas.
    %
    % Set the position to place the corrected image. We can choose to place
    % the color corrected image in the middle on the right side of the
    % canvas.
    if (~options.addImageRight)
        position_correctedImage_x = 1-position_testImage_x;
        position_correctedImage_y = 0.5;
        correctedImage_x = floor((canvas_width - testImage_width) * position_correctedImage_x) + 1;
        correctedImage_y = floor((canvas_height - testImage_height) * position_correctedImage_y) + 1;

        % Place the image onto the canvas.
        for ii = 1:length(idxImageHeight)
            canvas(correctedImage_y+idxImageHeight(ii)-1, correctedImage_x+idxImageWidth(ii)-1, :) = ...
                testImageColorCorrect(idxImageHeight(ii),idxImageWidth(ii),:);
        end
    end

    %% Add a striped image on the center if you want.
    %
    % We will place either an original image with stripes or color corrected
    % image at the center to evaluate. Here, we add color corrected image at
    % the center.
    if (options.addImageRight)
        % Set the position to place the corrected image.
        position_centerImage_x = 0.5;
        position_centerImage_y = 0.5;
        centerImage_x = floor((canvas_width - testImage_width) * position_centerImage_x) + 1;
        centerImage_y = floor((canvas_height - testImage_height) * position_centerImage_y) + 1;

        % Place the main image onto the canvas
        for ii = 1:length(idxImageHeight)
            canvas(centerImage_y+idxImageHeight(ii)-1, centerImage_x+idxImageWidth(ii)-1, :) = ...
                testImageColorCorrect(idxImageHeight(ii),idxImageWidth(ii),:);
        end
    end
end

%% Change the class of the canvas to uint8.
canvas = uint8(canvas);

%% Display the final image canvas.
if (options.verbose)
    figure;
    imshow(canvas);
    title('Simulated screen image')
end

%% Calculate the image profiles on the chromaticitiy coordinates.
if ~isempty(testImage)
    % Calculate the CIE coordinates of the original image.
    xyY_testImage = XYZToxyY(XYZ_testImage);
    uvY_testImage = XYZTouvY(XYZ_testImage);

    % Image with stripes.
    XYZ_testImageStripe = RGBToXYZ(RGB_testImageStripe,M_RGB2XYZ,gamma);
    xyY_testImageStripe = XYZToxyY(XYZ_testImageStripe);
    uvY_testImageStripe = XYZTouvY(XYZ_testImageStripe);

    % Color corrected image.
    XYZ_colorCorrectedImage = RGBToXYZ(RGB_colorCorrectedImage,M_RGB2XYZ,gamma);
    xyY_colorCorrectedImage = XYZToxyY(XYZ_colorCorrectedImage);
    uvY_colorCorrectedImage = XYZTouvY(XYZ_colorCorrectedImage);
end

%% Plot the comparison results across images.
if (options.verbose)
    % Compare the digital RGB values across the images in 3-D.
    figure;
    markerColorOptions = {'r','g','b'};
    sgtitle('Image profile comparison');
    subplot(1,4,1);
    scatter3(red_testImage,green_testImage,blue_testImage,'k+'); hold on;
    scatter3(red_testImageStripe,green_testImageStripe,blue_testImageStripe,'k.');
    scatter3(red_colorCorrectedImage,green_colorCorrectedImage,blue_colorCorrectedImage,append(markerColorOptions{idxColorStripe},'.'));
    xlabel('dR','fontsize',13);
    ylabel('dG','fontsize',13);
    zlabel('dB','fontsize',13);
    legend('Original','Stripes','Color-correct','Location','northeast','fontsize',11);
    xlim([0 255]);
    ylim([0 255]);
    zlim([0 255]);
    grid on;
    title('3D (dRGB)','fontsize',11);

    % Comparison in 2-D: dG vs. dR.
    subplot(1,4,2); hold on;
    plot(green_testImage,red_testImage,'k+');
    plot(green_testImageStripe,red_testImageStripe,'k.');
    plot(green_colorCorrectedImage,red_colorCorrectedImage,append(markerColorOptions{idxColorStripe},'.'));
    xlabel('dG','fontsize',13);
    ylabel('dR','fontsize',13);
    legend('Original','Stripes','Color-correct','Location','southeast','fontsize',11);
    xlim([0 255]);
    ylim([0 255]);
    grid on;
    title('2D (dG vs. dR)','fontsize',11);

    % Comparison in 2-D: dG vs. dB.
    subplot(1,4,3); hold on;
    plot(green_testImage,blue_testImage,'k+');
    plot(green_testImageStripe,blue_testImageStripe,'k.');
    plot(green_colorCorrectedImage,blue_colorCorrectedImage,append(markerColorOptions{idxColorStripe},'.'));
    xlabel('dG','fontsize',13);
    ylabel('dB','fontsize',13);
    legend('Original','Stripes','Color-correct','Location','southeast','fontsize',11);
    xlim([0 255]);
    ylim([0 255]);
    grid on;
    title('2D (dG vs. dB)','fontsize',11);

    % Comparison in 2-D: dR vs. dB.
    subplot(1,4,4); hold on;
    plot(red_testImage,blue_testImage,'k+');
    plot(red_testImageStripe,blue_testImageStripe,'k.');
    plot(red_colorCorrectedImage,blue_colorCorrectedImage,append(markerColorOptions{idxColorStripe},'.'));
    xlabel('dR','fontsize',13);
    ylabel('dB','fontsize',13);
    legend('Original','Stripes','Color-correct','Location','southeast','fontsize',11);
    xlim([0 255]);
    ylim([0 255]);
    grid on;
    title('2D (dR vs. dB)','fontsize',11);

    % Plot the color profiles on the u'v' coordinates.
    figure; hold on;
    plot(uvY_testImage(1,:),uvY_testImage(2,:),'k.');
    % plot(uvY_testImageStripe(1,:),uvY_testImageStripe(2,:),'k+');
    plot(uvY_colorCorrectedImage(1,:),uvY_colorCorrectedImage(2,:),'r.');

    % Display gamut.
    plot([uv_displayPrimary(1,:) uv_displayPrimary(1,1)], [uv_displayPrimary(2,:) uv_displayPrimary(2,1)],'k-','LineWidth',1);

    % Plackian locus.
    load T_xyzJuddVos
    T_XYZ = T_xyzJuddVos;
    T_xy = [T_XYZ(1,:)./sum(T_XYZ); T_XYZ(2,:)./sum(T_XYZ)];
    T_uv = xyTouv(T_xy);
    idxFarRightPointuv = 65;
    idxFarBelowPointuv = 3;
    plot([T_uv(1,1:idxFarRightPointuv) T_uv(1,idxFarBelowPointuv)], [T_uv(2,1:idxFarRightPointuv) T_uv(2,idxFarBelowPointuv)], 'k-');

    % Figure stuffs.
    xlim([0 0.7]);
    ylim([0 0.7]);
    xlabel('CIE u-prime','fontsize',13);
    ylabel('CIE v-prime','fontsize',13);
    legend('Original','Color-correct','Display gamut',...
        'Location','southeast','fontsize',11);
    % legend('Original','Stripes','Color-correct','Display gamut',...
    %     'Location','southeast','fontsize',11);
    title('Image profile on CIE uv-prime coordinates');
end

%% Save out image stats. We may want to use this info for data analysis.
%
% Color distributions of the test images on CIE u'v' coordinates.
if ~isempty(testImage)
    imageProfile.uvY_testImageStripe = uvY_testImageStripe;
    imageProfile.uvY_colorCorrectedImage = uvY_colorCorrectedImage;
end
end
