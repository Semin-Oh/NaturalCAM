function [mean_dRGB_image_bright] = CalImageWhitePoint(image,options)
% Define the white point within the scene.
%
% Syntax:
%    [XYZw] = CalImageWhitePoint(image)
%
% Description:
%     This routine searches a white point within the scene. We will use a
%     simple method, so-called 'White patch method'. It basically searches
%     the brightest pixel (R+G+B) within the scene and treat it as a white
%     point.
%
%     Reference: H. R. V., Drew, M. S., Finlayson, G. D., & Rey, P. A. T.
%     (2012, January). The role of bright pixels in illumination
%     estimation. In Color and Imaging Conference (Vol. 2012, No. 1, pp.
%     41-46). Society for Imaging Science and Technology.
%
% See also:
%    Image2CIECAM02.m, NCAM_DataAnalysis.m.

% History:
%    04/03/25    smo       - Made it as a function.

%% Set variables.
arguments
    image
    options.calculationMethod = 'whitepatch'
    options.maxRGB (1,1) = 255
    options.percentPixelCutoff (1,1) = 0.9
    options.percentPixelBright (1,1) = 0.05
    options.verbose (1,1) = true
end

%% Calculation happens here.
switch options.calculationMethod
    case 'whitepatch'
        % First, cut off the extreme pixels. We will remove pixels which exceed
        % 90% of the dynamic range.
        %
        % Rearrange the image in 2-D for calculation.
        [row column nChannels] = size(image);
        dRGB_image = reshape(permute(image,[3,1,2]),[nChannels row*column]);

        % Set the boundary to cut off the pixels. Here we will cut off the
        % pixel exceeds the 90% of the dynamic range.
        dRGB_cutoff = uint8(options.maxRGB * options.percentPixelCutoff);

        % Find the index of the array where the pixel exceeds the criteria.
        idxCutoff_R = find(dRGB_image(1,:)>dRGB_cutoff);
        idxCutoff_G = find(dRGB_image(2,:)>dRGB_cutoff);
        idxCutoff_B = find(dRGB_image(3,:)>dRGB_cutoff);
        idxCutoff = unique([idxCutoff_R idxCutoff_G idxCutoff_B]);

        % Cutting off happens here.
        dRGB_image_cutoff = dRGB_image;
        dRGB_image_cutoff(:,idxCutoff) = [];

        % Get the cut off dummy pixels here. We may want to see what pixels
        % were cut off.
        dRGB_image_cutoff_dummy = dRGB_image;
        dRGB_image_cutoff_dummy = dRGB_image_cutoff_dummy(:,idxCutoff);

        % Now we will take the bright pixels within the pixels after
        % cutting off.
        %
        % We can use different statistical estimator, but use 5% for mean,
        % and 3% for median. These numbers are based on the referred paper.
        %
        % Here, we use the mean with 5% brightnest pixels, which makes the
        % lowest mean angular errors.
        sumRGB_image = sum(dRGB_image_cutoff);
        [sumRGB_image_sorted I] = sort(sumRGB_image,'descend');

        % Sort the dRGB in the same order.
        dRGB_image_cutoff_sorted = dRGB_image_cutoff(:,I);

        % Get the mean of the bright pixels. We will print out the mean
        % dRGB values of the bright pixels.
        nPixels = length(sumRGB_image_sorted);
        idxPecentBrightest = ceil(options.percentPixelBright * nPixels);
        dRGB_image_bright = dRGB_image_cutoff_sorted(:,1:idxPecentBrightest);
        mean_dRGB_image_bright = round(mean(dRGB_image_bright,2));

        % Set the estimated white point as a mean of bright pixels.
        dRGB_estimatedWhitePoint = mean_dRGB_image_bright;

        % Plot it how we did.
        if (options.verbose)
            % Calculate the rg coordinates.
            rg_image = RGBTorg(dRGB_image);
            rg_image_cutoff_dummy = RGBTorg(dRGB_image_cutoff_dummy);
            rg_image_bright = RGBTorg(dRGB_image_bright);
            rg_image_white = RGBTorg(dRGB_estimatedWhitePoint);

            % This is only when your monitor setting has the D65 as a white
            % point.
            rg_white_d65 = RGBTorg([255;255;255]);

            % Make a figure here.
            figure; hold on;
            sgtitle('Estimation of illumination in image');

            % Image.
            nSubplots = 4;
            subplot(1,nSubplots,1);
            imshow(image);
            title('Test image');

            % Image profile.
            subplot(1,nSubplots,2:nSubplots); hold on;
            plot(rg_image(1,:),rg_image(2,:),'k.');
            plot(rg_image_cutoff_dummy(1,:),rg_image_cutoff_dummy(2,:),'.','color',[0.5 0.5 0.5]);
            plot(rg_image_bright(1,:),rg_image_bright(2,:),'g.');
            plot(rg_image_white(1),rg_image_white(2),'ro', ...
                'markersize',5,'markerfacecolor','r','markeredgecolor','k');
            plot(rg_white_d65(1),rg_white_d65(2),'bo',...
                'markersize',3,'markerfacecolor','b','markeredgecolor','k');
            xlabel('r');
            ylabel('g');
            xlim([0 1]);
            ylim([0 1]);
            axis square;
            title('Image profile');
            legend('original','cut-off','bright','white point','d65');

            % % Image of the estimated white point.
            % subplot(1,nSubplots,3);
            % pixelImageSize = 100;
            % imageSize = [pixelImageSize, pixelImageSize];
            % image_estimatedWhitePoint = repmat(reshape(dRGB_estimatedWhitePoint/255, 1, 1, 3), imageSize);
            % imshow(image_estimatedWhitePoint);
            % title(sprintf('White point, dRGB=(%d,%d,%d)',...
            %     dRGB_estimatedWhitePoint(1),dRGB_estimatedWhitePoint(2),dRGB_estimatedWhitePoint(3)));

            % Gray world assumption white point. It seems not really
            % working well for the images that we used.
            %
            % subplot(1,nSubplots,4);
            % dRGB_estimatedWhitePoint_grayWorld = mean(dRGB_image,2);
            % image_estimatedWhitePoint_grayWorld = repmat(reshape(dRGB_estimatedWhitePoint_grayWorld/255, 1, 1, 3), imageSize);
            % imshow(image_estimatedWhitePoint_grayWorld);
            % title(sprintf('White point (Gray world), dRGB=(%d,%d,%d)',...
            %     image_estimatedWhitePoint_grayWorld(1),image_estimatedWhitePoint_grayWorld(2),image_estimatedWhitePoint_grayWorld(3)));
        end
    otherwise
end
end
