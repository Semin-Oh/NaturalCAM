function RGB_result = xyz2rgb(XYZ, M, N, result)


rgb2XYZ = [0.5805 0.1687 0.1700; 0.2766 0.6428 0.0814; 0.0099 0.1018 0.9065]; % Custom mode
% rgb2XYZ = [0.4124 0.3576 0.1805;0.2126 0.7152 0.0722; 0.0193 0.1192 0.9505]; %sRGB gamut
XYZ2rgb = inv(rgb2XYZ);


RGB_result(:,1) = XYZ2rgb(1,1).* XYZ(:,1) + XYZ2rgb(1,2).* XYZ(:,2) + XYZ2rgb(1,3).* XYZ(:,3);
RGB_result(:,2) = XYZ2rgb(2,1).* XYZ(:,1) + XYZ2rgb(2,2).* XYZ(:,2) + XYZ2rgb(2,3).* XYZ(:,3);
RGB_result(:,3) = XYZ2rgb(3,1).* XYZ(:,1) + XYZ2rgb(3,2).* XYZ(:,2) + XYZ2rgb(3,3).* XYZ(:,3);


RGB_result = ((((RGB_result)./100).^(1/2.2)).*255);
RGB_result = reshape(RGB_result,M,N,3);
RGB_result = real(RGB_result);
RGB_result = uint8(RGB_result); % 8bit digital RGB

imwrite(RGB_result,result);