function [canvas] = MakeImageCanvas(testImage,options)
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
%
% Optional key/value pairs:
%    testImageSize            - Decide the size of the test images. It
%                               is decided by the ratio of the height of
%                               the canvas. Default to 0.40.
%    whichCenterImage         - Decide which image to place at the center
%                               of the canvas. For the experiment, we will
%                               put either the input image with stripes
%                               ('stripes') on or color corrected image
%                               ('color'). Default to 'color'. If you don't
%                               want to have the image at the center,
%                               simply enter anything other than 'stripes'
%                               and 'color'. For example, if you set it as
%                               'none', there will be no centered image
%                               appeared.
%   stripeHeightPixel         - Define the height of each horizontal stripe
%                               on the background of the cavas. It's in
%                               pixel unit and default to 5.
%   whichColorStripes         - Define the color of stripes to place on top
%                               of the image. This will make color
%                               assimilation phenomena. Choose among 'red',
%                               'green', 'blue'. Default to 'red'.
%   intensityStripe           - Decide the intensity of the stripe in
%                               pixel. For now, it is decided on 8-bit
%                               system, so it should be within the range of
%                               0-255. Default to 255, the maximum.
%   position_leftImage_x      - Define the position of the left sided image
%                               on the canvas. This will decide the
%                               positions of all three images on the
%                               canvas. Choose between 0 to 1, where 0.5
%                               means the center of the canvas, 0 is the
%                               left end and 1 is the right end. Default to
%                               0.1
%   sizeCanvas                - Decide the size of the canvas to generate.
%                               It may be matched with the screen size that
%                               you want to present the image. Default to
%                               [1920 1080] as [width height] of the
%                               screen in pixe.
%   colorCorrectMethod        - Decide the color correcting method that
%                               corresponds to the test image with stripes
%                               on. Default to 'mean'.
%   nChannelsColorCorrect     - The number of channels to correct when
%                               generating color corrected image. You can
%                               set this value to 1 if you want to correct
%                               only the targeting channel, otherwise it
%                               will correct all three channels. Default to
%                               1.
%   intensityColorCorrect     - Decide the color correction power on
%                               the test image. If it sets to empty, the
%                               amount of color correction would be solely
%                               decided by the ratio of the stripes on the
%                               image with stripes. Default to empty.
%   verbose                   - Control the plot and alarm messages.
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

%% Set variables.
arguments
    testImage
    options.testImageSize = 0.40
    options.whichCenterImage = 'color'
    options.stripeHeightPixel (1,1) = 5
    options.whichColorStripes = 'red'
    options.intensityStripe (1,1) = 255
    options.position_leftImage_x (1,1) = 0.1
    options.verbose (1,1) = false
    options.sizeCanvas (1,2) = [1920 1080]
    options.colorCorrectMethod = 'add'
    options.nChannelsColorCorrect (1,1) = 1
    options.intensityColorCorrect = []
end

% Define the size of the canvas.
canvas_width = options.sizeCanvas(1);
canvas_height = options.sizeCanvas(2);

% Define the index of the color stripes. This index will control when we
% generate a color corrected image.
colorStripeOptions = {'red','green','blue'};
idxColorStripe = find(strcmp(colorStripeOptions, options.whichColorStripes));

%% Create a canvas to place images on.
%
% Create a blank canvas.
canvas = zeros(canvas_height, canvas_width, 3);

% Get the size of original input image.
if ~isempty(testImage)
    [originalImage_height originalImage_width ~] = size(testImage);
    ratioWidthToHeight_original = originalImage_width/originalImage_height;

    % Define the size of the test image. For now, we keep the original
    % height:width ratio. We will round up so that we make sure image size
    % in integer number in pixel.
    testImage_height = ceil(canvas_height * options.testImageSize);
    testImage_width = ceil(testImage_height * ratioWidthToHeight_original);

    % Resize the test image to fit in the canvas.
    resized_testImage = imresize(testImage, [testImage_height, testImage_width]);

    % Find the location where the image content exist. The idea here is to
    % treat the black (0, 0, 0) part as a background and it will be excluded in
    % this index. Therefore, the number of pixels of the image content is the
    % same as the length of either 'idxImageHeight' or 'idxImageWidth'.
    idxImageHeight = [];
    idxImageWidth = [];
    bgSetting = 0;
    for hh = 1:testImage_height
        for ww = 1:testImage_width
            summation = resized_testImage(hh,ww,1)+resized_testImage(hh,ww,2)+resized_testImage(hh,ww,3);
            if ~(summation == bgSetting)
                idxImageHeight(end+1) = hh;
                idxImageWidth(end+1) = ww;
            end
        end
    end

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
        canvas(testImage_y+idxImageHeight(ii)-1, testImage_x+idxImageWidth(ii)-1, :) = resized_testImage(idxImageHeight(ii),idxImageWidth(ii),:);
    end
end

%% We will add the same image with stripes at the center if we want.
%
% Put another image before the next section so that both images could place
% before the lines.
if ~isempty(testImage)
    if strcmp(options.whichCenterImage, 'stripes')
        % Set the image location.
        position_centerImage_x = 0.5;
        position_centerImage_y = 0.5;
        centerImage_x = floor((canvas_width - testImage_width) * position_centerImage_x) + 1;
        centerImage_y = floor((canvas_height - testImage_height) * position_centerImage_y) + 1;

        % Place the main image onto the canvas
        for ii = 1:length(idxImageHeight)
            canvas(centerImage_y+idxImageHeight(ii)-1, centerImage_x+idxImageWidth(ii)-1, :) = resized_testImage(idxImageHeight(ii),idxImageWidth(ii),:);
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
    testImageOneStripe = zeros(size(testImageCrop));
    for ii = 1:length(idxImageHeight)
        testImageOneStripe(idxImageHeight(ii),idxImageWidth(ii),:) = testImageCrop(idxImageHeight(ii), idxImageWidth(ii), :);
    end

    % Extract color information per each channel.
    %
    % Original image.
    for ii = 1:length(idxImageHeight)
        red_testImage(ii)   = resized_testImage(idxImageHeight(ii),idxImageWidth(ii),1);
        green_testImage(ii) = resized_testImage(idxImageHeight(ii),idxImageWidth(ii),2);
        blue_testImage(ii)  = resized_testImage(idxImageHeight(ii),idxImageWidth(ii),3);
    end

    % Image with stripes.
    for ii = 1:length(idxImageHeight)
        red_testImageOneStripe(ii)   = testImageOneStripe(idxImageHeight(ii),idxImageWidth(ii),1);
        green_testImageOneStripe(ii) = testImageOneStripe(idxImageHeight(ii),idxImageWidth(ii),2);
        blue_testImageOneStripe(ii)  = testImageOneStripe(idxImageHeight(ii),idxImageWidth(ii),3);
    end

    % We color correct the original image. We get the resized original
    % image and correct color in the next step to this image.
    colorCorrected_testImage = resized_testImage;

    % Here we choose which method to color correct the image
    switch options.colorCorrectMethod
        % For this method, get the color correction coefficient per each channel.
        % Here, we simply match the mean R, G, B values independently.
        case 'mean'
            coeffColorCorrect_red   = mean(red_testImageOneStripe)/mean(red_testImage);
            coeffColorCorrect_green = mean(green_testImageOneStripe)/mean(green_testImage);
            coeffColorCorrect_blue  = mean(blue_testImageOneStripe)/mean(blue_testImage);

            % Here, we can either correct one target channel or all channels.
            %
            % For example, when we generate red corrected image, we can either only
            % correct the red channel or all three channels. Still thinking about
            % what's more logical way to do.
            if options.nChannelsColorCorrect == 1
                % Correct only the targeting channel, while the others remain the same.
                switch options.whichColorStripes
                    case 'red'
                        colorCorrected_testImage(:,:,1) = colorCorrected_testImage(:,:,1).*coeffColorCorrect_red;
                    case 'green'
                        colorCorrected_testImage(:,:,2) = colorCorrected_testImage(:,:,2).*coeffColorCorrect_green;
                    case 'blue'
                        colorCorrected_testImage(:,:,3) = colorCorrected_testImage(:,:,3).*coeffColorCorrect_blue;
                end
            else
                % Correct all three channels.
                colorCorrected_testImage(:,:,1) = colorCorrected_testImage(:,:,1).*coeffColorCorrect_red;
                colorCorrected_testImage(:,:,2) = colorCorrected_testImage(:,:,2).*coeffColorCorrect_green;
                colorCorrected_testImage(:,:,3) = colorCorrected_testImage(:,:,3).*coeffColorCorrect_blue;
            end

        case 'add'
            % Calculate the proportion of the pixels that are stripes within
            % the image. This should be close to 1/3 (~33%) as we place three
            % different stripes - red, green, and blue - repeatedly.
            switch options.whichColorStripes
                case 'red'
                    targetCh_testImageOneStripe = red_testImageOneStripe;
                case 'green'
                    targetCh_testImageOneStripe = green_testImageOneStripe;
                case 'blue'
                    targetCh_testImageOneStripe = blue_testImageOneStripe;
            end

            % Find the number of the intensity of the stripes within the image.
            % 'ratioStripes' should be close to 1/3 (~33%).
            ratioStripes = length(find(targetCh_testImageOneStripe == options.intensityStripe))./length(targetCh_testImageOneStripe);

            % Color correction happens here. Here we only correct one
            % targeting channel. The final scale ('ratioColorCorrect')
            % should be within the range 0-1.
            if ~isempty(options.intensityColorCorrect)
                ratioColorCorrect = options.intensityColorCorrect;
            else
                ratioColorCorrect = ratioStripes;
            end

            % Check if the scaling factor is within the range 0-1.
            maxRatioColorCorrect = 1;
            minRatioColorCorrect = 0;
            if ratioColorCorrect > maxRatioColorCorrect
                ratioColorCorrect = maxRatioColorCorrect;
            elseif ratioColorCorrect < minRatioColorCorrect
                ratioColorCorrect = minRatioColorCorrect;
            end

            % Color correction happens here.
            %
            % Target channel.
            colorCorrectionPerPixelOneChannel = ratioColorCorrect .* (options.intensityStripe - resized_testImage(:,:,idxColorStripe));
            colorCorrected_testImage(:,:,idxColorStripe) = colorCorrected_testImage(:,:,idxColorStripe) + colorCorrectionPerPixelOneChannel;

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
    end

    % Remove the background of the color corrected image.
    colorCorrected_testImage_temp = zeros(size(colorCorrected_testImage));
    for ii = 1:length(idxImageHeight)
        colorCorrected_testImage_temp(idxImageHeight(ii),idxImageWidth(ii),:) = colorCorrected_testImage(idxImageHeight(ii),idxImageWidth(ii),:);
    end
    colorCorrected_testImage = colorCorrected_testImage_temp;

    % Get color information of the color corrected image for comparison.
    for ii = 1:length(idxImageHeight)
        red_colorCorrectedImage(ii)   = colorCorrected_testImage(idxImageHeight(ii),idxImageWidth(ii),1);
        green_colorCorrectedImage(ii) = colorCorrected_testImage(idxImageHeight(ii),idxImageWidth(ii),2);
        blue_colorCorrectedImage(ii)  = colorCorrected_testImage(idxImageHeight(ii),idxImageWidth(ii),3);
    end

    % Display the images if you want.
    if (options.verbose)
        % Make a new figure.
        figure;

        % Original image.
        subplot(1,3,1);
        imshow(uint8(resized_testImage));
        title('Original');

        % Image with stripes.
        subplot(1,3,2);
        imshow(uint8(testImageOneStripe));
        title('From the canvas');

        % Color corrected image.
        subplot(1,3,3);
        imshow(uint8(colorCorrected_testImage));
        title('Color correction');
    end

    %% Now add the color corrected image to the canvas.
    %
    % Set the position to place the corrected image.
    position_correctedImage_x = 1-position_testImage_x;
    position_correctedImage_y = 0.5;
    correctedImage_x = floor((canvas_width - testImage_width) * position_correctedImage_x) + 1;
    correctedImage_y = floor((canvas_height - testImage_height) * position_correctedImage_y) + 1;

    % Place the image onto the canvas.
    for ii = 1:length(idxImageHeight)
        canvas(correctedImage_y+idxImageHeight(ii)-1, correctedImage_x+idxImageWidth(ii)-1, :) = ...
            colorCorrected_testImage(idxImageHeight(ii),idxImageWidth(ii),:);
    end

    %% Fianlly, add a test image at the center.
    %
    % We will place either an original image with stripes or color corrected
    % image at the center to evaluate. Here, we add color corrected image at
    % the center.
    if strcmp(options.whichCenterImage,'color')

        % Set the position to place the corrected image.
        position_centerImage_x = 0.5;
        position_centerImage_y = 0.5;
        centerImage_x = floor((canvas_width - testImage_width) * position_centerImage_x) + 1;
        centerImage_y = floor((canvas_height - testImage_height) * position_centerImage_y) + 1;

        % Place the main image onto the canvas
        for ii = 1:length(idxImageHeight)
            canvas(centerImage_y+idxImageHeight(ii)-1, centerImage_x+idxImageWidth(ii)-1, :) = ...
                colorCorrected_testImage(idxImageHeight(ii),idxImageWidth(ii),:);
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

%% Check how color information is changed.
%
if ~isempty(testImage)
    % Get the mean RGB values of the original image.
    meanRed_testImage = mean(red_testImage);
    meanGreen_testImage = mean(green_testImage);
    meanBlue_testImage = mean(blue_testImage);
    meanRGB_testImage = [meanRed_testImage; meanGreen_testImage; meanBlue_testImage];

    % Image with stripes.
    meanRed_testImageOneStripe = mean(red_testImageOneStripe);
    meanGreen_testImageOneStripe = mean(green_testImageOneStripe);
    meanBlue_testImageOneStripe = mean(blue_testImageOneStripe);
    meanRGB_testImageOneStripe = [meanRed_testImageOneStripe; meanGreen_testImageOneStripe; meanBlue_testImageOneStripe];

    % Color corrected image.
    meanRed_colorCorrectedImage = mean(red_colorCorrectedImage);
    meanGreen_colorCorrectedImage = mean(green_colorCorrectedImage);
    meanBlue_colorCorrectedImage = mean(blue_colorCorrectedImage);
    meanRGB_colorCorrectedImage = [meanRed_colorCorrectedImage; meanGreen_colorCorrectedImage; meanBlue_colorCorrectedImage];

    % Plot the comparison results across images.
    if (options.verbose)
        % Compare the digital RGB values across the images in 3-D.
        figure;
        markerColorOptions = {'r','g','b'};
        sgtitle('Image profile comparison');
        subplot(1,4,1);
        scatter3(red_testImage,green_testImage,blue_testImage,'k+'); hold on;
        scatter3(red_testImageOneStripe,green_testImageOneStripe,blue_testImageOneStripe,'k.');
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
        plot(green_testImageOneStripe,red_testImageOneStripe,'k.');
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
        plot(green_testImageOneStripe,blue_testImageOneStripe,'k.');
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
        plot(red_testImageOneStripe,blue_testImageOneStripe,'k.');
        plot(red_colorCorrectedImage,blue_colorCorrectedImage,append(markerColorOptions{idxColorStripe},'.'));
        xlabel('dR','fontsize',13);
        ylabel('dB','fontsize',13);
        legend('Original','Stripes','Color-correct','Location','southeast','fontsize',11);
        xlim([0 255]);
        ylim([0 255]);
        grid on;
        title('2D (dR vs. dB)','fontsize',11);

        % Here we will compare the image profile on the CIE system.
        %
        % For now, we assume the display has the sRGB color gamut, which
        % will be replaced by real measurement data.
        %
        % We will use the gamma and luminance values per each channel from
        % the calibration data though.
        %
        % Calibration data. This is based on 10-bit and we will interpolate
        % it to use for 8-bit display. This values are read from the file
        % 'Calibration_Periphery_ExtendedWindow_CenterMonitor_1_20_23'.
        inputRGB10bit = [2	4	8	16	32	64	128	197	266	335	404	473	507	508	509	510	511	512	513	514	515	516	517	542	610	679	748	817	886	955	1024];
        inputRGB_norm = inputRGB10bit./inputRGB10bit(end);

        output10bit_R = [0.188900000000000	0.189500000000000	0.194400000000000	0.201000000000000	0.223600000000000	0.313600000000000	0.668400000000000	1.35600000000000	2.44800000000000	4.04100000000000	6.08700000000000	8.52400000000000	9.86000000000000	9.88900000000000	9.92800000000000	9.97800000000000	10.0200000000000	10.0280000000000	10.0680000000000	10.0730000000000	10.1050000000000	10.1820000000000	10.2410000000000	11.3800000000000	14.8500000000000	19.0140000000000	23.6500000000000	28.8100000000000	34.3500000000000	40.6200000000000	47.4700000000000];
        output10bit_G = [0.193300000000000	0.198500000000000	0.202400000000000	0.231800000000000	0.326400000000000	0.685300000000000	2.30300000000000	5.31800000000000	10.0600000000000	17.0900000000000	26.3000000000000	37.5300000000000	43.2300000000000	43.4400000000000	43.5600000000000	43.8600000000000	44.0200000000000	43.9500000000000	44	44.1800000000000	44.3600000000000	44.5500000000000	44.7600000000000	49.8900000000000	65.6400000000000	85.0700000000000	106.740000000000	130.320000000000	155.770000000000	183.270000000000	214.560000000000];
        output10bit_B = [0.188500000000000	0.188700000000000	0.189100000000000	0.190400000000000	0.202500000000000	0.248500000000000	0.445400000000000	0.747700000000000	1.17800000000000	1.73500000000000	2.51100000000000	3.44000000000000	3.98600000000000	3.99900000000000	4.02200000000000	4.03100000000000	4.05300000000000	4.05500000000000	4.06700000000000	4.08500000000000	4.09800000000000	4.11600000000000	4.12800000000000	4.52400000000000	5.69000000000000	7.11600000000000	8.86900000000000	10.9150000000000	13.2500000000000	15.9010000000000	19.1100000000000];
        output10bit_RGB = [0.196600000000000	0.201600000000000	0.213700000000000	0.245600000000000	0.373900000000000	0.925800000000000	3.19500000000000	7.74300000000000	15.1400000000000	26.1400000000000	40.0900000000000	57.6300000000000	67.9200000000000	68.0800000000000	68.3000000000000	68.7400000000000	69.0100000000000	69.0700000000000	69.1200000000000	69.4100000000000	69.6400000000000	70.0600000000000	70.2600000000000	78.2100000000000	103.190000000000	131.560000000000	164.060000000000	200.110000000000	240.040000000000	285.200000000000	332.900000000000];

        % Calculate display gamma. All values should be close to 2.2 for
        % the curved display.
        gamma_R = CalculateGamma(inputRGB10bit,output10bit_R);
        gamma_G = CalculateGamma(inputRGB10bit,output10bit_G);
        gamma_B = CalculateGamma(inputRGB10bit,output10bit_B);
        gamma_RGB = CalculateGamma(inputRGB10bit,output10bit_RGB);

        % Matrix to convert from the linear RGB to XYZ.
        xyY_sRGB = [0.6400 0.3000 0.1500; 0.3300 0.6000 0.0600; 0.2126 0.7152 0.0722];
        M_RGB2XYZ_sRGB = [0.4124 0.3576 0.1805; 0.2126 0.7152 0.0722; 0.0193 0.1192 0.9505];

        % Original test image.
        RGB_testImage = [red_testImage; green_testImage; blue_testImage];
        XYZ_testImage = RGBToXYZ(RGB_testImage,M_RGB2XYZ_sRGB,gamma_RGB);
        xyY_testImage = XYZToxyY(XYZ_testImage);

        % Test image with stripes.
        RGB_testImageOneStripe = [red_testImageOneStripe; green_testImageOneStripe; blue_testImageOneStripe];
        XYZ_testImageOneStripe = RGBToXYZ(RGB_testImageOneStripe,M_RGB2XYZ_sRGB,gamma_RGB);
        xyY_testImageOneStripe = XYZToxyY(XYZ_testImageOneStripe);

        % Color corrected image.
        RGB_colorCorrectedImage =  [red_colorCorrectedImage; green_colorCorrectedImage; blue_colorCorrectedImage];
        XYZ_colorCorrectedImage = RGBToXYZ(RGB_colorCorrectedImage,M_RGB2XYZ_sRGB,gamma_RGB);
        xyY_colorCorrectedImage = XYZToxyY(XYZ_colorCorrectedImage);

        % Plot it.
        figure; hold on;
        plot(xyY_testImage(1,:),xyY_testImage(2,:),'k+');
        plot(xyY_testImageOneStripe(1,:),xyY_testImageOneStripe(2,:),'k.');
        plot(xyY_colorCorrectedImage(1,:),xyY_colorCorrectedImage(2,:),'r.');

        % Display gamut. For now, it's set to sRGB for convenience.
        plot([xyY_sRGB(1,:) xyY_sRGB(1,1)], [xyY_sRGB(2,:) xyY_sRGB(2,1)],'k-','LineWidth',1);

        % Plackian locus.
        load T_xyzJuddVos
        T_XYZ = T_xyzJuddVos;
        T_xy = [T_XYZ(1,:)./sum(T_XYZ); T_XYZ(2,:)./sum(T_XYZ)];
        plot([T_xy(1,:) T_xy(1,1)], [T_xy(2,:) T_xy(2,1)], 'k-');

        % Figure stuffs.
        xlim([0 1]);
        ylim([0 1]);
        xlabel('CIE x','fontsize',13);
        ylabel('CIE y','fontsize',13);
        legend('Original','Stripes','Color-correct','Display gamut',...
            'Location','southeast','fontsize',11);
        title('Image profile on CIE xy coordinates');
    end
end
