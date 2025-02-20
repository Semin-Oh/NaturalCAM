%% PTBSimpleCheck.
%    Sanity check if PTB screen commands work as expected.

% History:
%    02/20/24    smo    - Wrote it.

[window windowRect] = OpenPlainScreen([0.5 0.5 0.5]);
GetJSResp;
pause(0.5);

image1 = uint8(ones(100,100,3))*0;
image2 = uint8(ones(300,300,3))*200;
imageSize = size(image1);

[imageTexture imageWindowRect rng] = MakeImageTexture(image2,window,windowRect);
FlipImageTexture(imageTexture,window,imageWindowRect);
GetJSResp;
pause(0.5);

[imageTexture imageWindowRect rng] = MakeImageTexture(image1,window,windowRect);
FlipImageTexture(imageTexture,window,imageWindowRect);
GetJSResp;
pause(0.5);

CloseScreen;
