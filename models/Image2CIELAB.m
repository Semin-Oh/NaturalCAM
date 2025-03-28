% Image2CIELAB.
%
% This script reads an image and calculates the CIELAB stats.

% History:
%    07/17/2024   smo   - Started on it.
%    07/17/2024   smo   - Working. For now, we set the display type as
%                         sRGB. We can customize later on in we want.

%% Initialize.
clear; close all;

%% Set variables.
%
% Set the display type. If unknown, set it to 'sRGB'.
displayType = 'sRGB';
switch displayType
    case 'sRGB'
        % We'll draw the color gamut of the display later on.
        xyY_targetDisplay = [0.6400 0.3000 0.1500; 0.3300 0.6000 0.0600; 0.2126 0.7152 0.0722];

        % 3x3 matrix to convert from the linear RGB to CIE XYZ.
        M_RGB2XYZ = [0.4124 0.3576 0.1805; 0.2126 0.7152 0.0722; 0.0193 0.1192 0.9505];

        % Display gamma. We can set it differently according to the
        % channels. Here, we set it as 2.2 for all channels.
        gamma = 2.2;
    otherwise
end

% Set it 'true' if you wanna plot the results.
verbose = true;

%% Load the test image.
%
% Here, we are using the test image as it is, when we do it for Coco
% dataset, we believe the object would have been segmented. Make sure you
% are in the directory where the image is saved.
testimageFilename = 'orange.png';
image = imread(testimageFilename);

% Display the image if you want.
if (verbose)
    figure;
    subplot(2,2,1);
    imshow(image);
    title('Test image');
    sgtitle(sprintf('Target display = (%s)',displayType),'fontsize',12);
end

%% Convert digital RGB to CIE XYZ.
XYZ_testImage = RGBToXYZ(image,M_RGB2XYZ,gamma);
xyY_testImage = XYZToxyY(XYZ_testImage);

%% CIE XYZ to CIELAB.
whitepoint = sum(M_RGB2XYZ,2);
lab = XYZToLab(XYZ_testImage,whitepoint);
lab_chroma(1,:) = sqrt(lab(2,:).^2+lab(3,:).^2);

%% Pick representative color of the test image.
%
% Here, we calculate the some color points that would be possible to
% represent the test image.

% Average.
XYZ_avgXYZ = mean(XYZ_testImage,2);
xyY_avgXYZ = XYZToxyY(XYZ_avgXYZ);
lab_avgXYZ = XYZToLab(XYZ_avgXYZ,whitepoint);
chroma_avgXYZ = sqrt(lab_avgXYZ(2)^2+lab_avgXYZ(3)^2);

lab_avgLAB = mean(lab,2);
chroma_avgLAB = sqrt(lab_avgLAB(2)^2+lab_avgLAB(3)^2);
XYZ_avgLAB = LabToXYZ(lab_avgLAB,whitepoint);
xyY_avgLAB = XYZToxyY(XYZ_avgLAB);

% Highest chroma.
highestChromaVal = max(lab_chroma);
idx_highestChroma = find(lab_chroma==highestChromaVal);
XYZ_highestChroma = XYZ_testImage(:,idx_highestChroma);
lab_highestChroma = lab(:,idx_highestChroma);
chroma_highestChroma = sqrt(lab_highestChroma(2)^2+lab_highestChroma(3)^2);
xyY_highestChroma = XYZToxyY(XYZ_highestChroma);

%% Plot the results.
if (verbose)
    subplot(2,2,2); hold on;
    % Test image.
    plot(xyY_testImage(1,:),xyY_testImage(2,:),'r.');

    % Some points that we picked.
    plot(xyY_avgXYZ(1),xyY_avgXYZ(2),'b.','MarkerSize',12);
    plot(xyY_avgLAB(1),xyY_avgLAB(2),'y.','MarkerSize',12);
    plot(xyY_highestChroma(1),xyY_highestChroma(2),'g.','MarkerSize',12);

    % Display gamut. For now, it's set to sRGB for convenience.
    plot([xyY_targetDisplay(1,:) xyY_targetDisplay(1,1)], [xyY_targetDisplay(2,:) xyY_targetDisplay(2,1)],'k-','LineWidth',1);

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
    legend('Test','Avg XYZ','Avg LAB','Highest C',...
        'Location','northeast','fontsize',7);
    title('CIE xy coordinates');

    % CIELAB results.
    %
    % a*b* plane.
    subplot(2,2,3); hold on;
    plot(lab(2,:),lab(3,:),'r.');
    plot(lab_avgXYZ(2),lab_avgXYZ(3),'b.','MarkerSize',12);
    plot(lab_avgLAB(2),lab_avgLAB(3),'y.','MarkerSize',12);
    plot(lab_highestChroma(2),lab_highestChroma(3),'g.','MarkerSize',12);
    xlim([-100 100]);
    ylim([-100 100]);
    xlabel('CIELAB a*','fontsize',13);
    ylabel('CIELAB b*','fontsize',13);
    xline(0,'k-');
    yline(0,'k-');
    legend('Test','Avg XYZ','Avg LAB','Highest C',...
        'Location','southeast','fontsize',7);
    grid on;
    title('CIELAB a*b*');

    % L*C* plane.
    subplot(2,2,4); hold on;
    plot(lab_chroma,lab(1,:),'r.');
    plot(chroma_avgXYZ,lab_avgXYZ(1),'b.','MarkerSize',12);
    plot(chroma_avgLAB,lab_avgLAB(1),'y.','MarkerSize',12);
    plot(chroma_highestChroma,lab_highestChroma(1),'g.','MarkerSize',12);
    xlim([0 120]);
    ylim([0 100]);
    xlabel('CIELAB C*','fontsize',13);
    ylabel('CIELAB L*','fontsize',13);
    legend('Test','Avg XYZ','Avg LAB','Highest C',...
        'Location','southeast','fontsize',7);
    title('CIELAB L*C*');
    grid on;
end

%% Print out the dRGB of the choices.
RGB_avgXYZ = XYZToRGB(XYZ_avgXYZ,M_RGB2XYZ,gamma);
RGB_avgLAB = XYZToRGB(XYZ_avgLAB,M_RGB2XYZ,gamma);
RGB_highestChroma = XYZToRGB(XYZ_highestChroma,M_RGB2XYZ,gamma);

% Plot it if you want.
if (verbose)
    figure; hold on;
    sgtitle('Representative colors from the test image');
    squareSize = 100;
    nChannels = 3;
    baseSquare = uint8(ones(squareSize,squareSize,nChannels));

    % Define the RGB color for the square.
    image_avgXYZ = baseSquare;
    image_avgXYZ(:,:,1) = RGB_avgXYZ(1);
    image_avgXYZ(:,:,2) = RGB_avgXYZ(2);
    image_avgXYZ(:,:,3) = RGB_avgXYZ(3);

    image_avgLAB = baseSquare;
    image_avgLAB(:,:,1) = RGB_avgLAB(1);
    image_avgLAB(:,:,2) = RGB_avgLAB(2);
    image_avgLAB(:,:,3) = RGB_avgLAB(3);

    image_highestChroma = baseSquare;
    image_highestChroma(:,:,1) = RGB_highestChroma(1);
    image_highestChroma(:,:,2) = RGB_highestChroma(2);
    image_highestChroma(:,:,3) = RGB_highestChroma(3);

    % Display the image here. We will plot everything in one figure.
    subplot(1,3,1);
    imshow(image_avgXYZ);
    title('Average XYZ');

    subplot(1,3,2);
    imshow(image_avgLAB);
    title('Average LAB');

    subplot(1,3,3);
    imshow(image_highestChroma);
    title('Highest chroma');
end
