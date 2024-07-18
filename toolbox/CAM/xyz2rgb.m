function RGB = xyz2rgb(XYZ, M, N, result)
rgb2XYZ = [0.5805 0.1687 0.1700; 0.2766 0.6428 0.0814; 0.0099 0.1018 0.9065]; 
XYZ2rgb = inv(rgb2XYZ);

RGB(:,1) = XYZ2rgb(1,1).* XYZ(:,1) + XYZ2rgb(1,2).* XYZ(:,2) + XYZ2rgb(1,3).* XYZ(:,3);
RGB(:,2) = XYZ2rgb(2,1).* XYZ(:,1) + XYZ2rgb(2,2).* XYZ(:,2) + XYZ2rgb(2,3).* XYZ(:,3);
RGB(:,3) = XYZ2rgb(3,1).* XYZ(:,1) + XYZ2rgb(3,2).* XYZ(:,2) + XYZ2rgb(3,3).* XYZ(:,3);

RGB = (((RGB).^(1/2.2)).*255);
RGB = reshape(RGB,M,N,3);
RGB = real(RGB);
RGB = uint8(RGB); % 8bit digital RGB

imwrite(RGB,result);