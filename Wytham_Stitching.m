clearvars
close all

%% Note
% To run this code, you first need to set-up VLFeat in MATLAB following the instruction from
% the this link:% https://www.vlfeat.org/sandbox/install-matlab.html

% Steps are (i) download VLFeat 0.9.21 binary package. (ii) Unfreeze and copy
% the folder to your matlab path.
% Then (iii) do "run('VLFEATROOT/toolbox/vl_setup')"

% Also you may want to run this code multiple times until you get
% satisfactory outcome. There is a random component in the stiching
% algorithm (SIFT) and everytime you run the code, the outcome is different.

% replace this line to wherever you put your VLFeat 0.9.21 binary package
run([pwd,'/vlfeat-0.9.21/toolbox/vl_setup'])

%% Stiching

% Specify angles you want to use for stiching
% only 2 images are used
UsedAngles = [2 4];

HSI_tripoderased = zeros(1024,1549,33,4);
Y_tripoderased = zeros(1024,1549,4);
% load hyperspectral images without tripod
for angle = 1:4
    load(['scene_angle',num2str(angle),'_tripoderased'])
    HSI_tripoderased(:,:,:,angle) = HSI;
    
    % We will perform stiching based on luminance channel
    XYZ = Wytham_HyperspectraltoXYZ_400to720nm(HSI);
    Y_tripoderased(:,:,angle) = XYZ(:,:,2);
end

% We make 360 degrees panorama image so full360 is set to TRUE
full360 = 1;

% Stiching images
HSI_panorama = Wytham_StitchImage_Sift(HSI_tripoderased(:,:,:,UsedAngles),Y_tripoderased(:,:,UsedAngles),full360);
HSI_panorama(isnan(HSI_panorama))=0;
sRGB_panorama = Wytham_HyperspectraltosRGB_400to720nm(HSI_panorama);
figure(1);imshow(sRGB_panorama.^(1/2.2))

% Crop the image to generate the final form
lightprobe = HSLightProbe_ShiftImage(HSI_panorama(25:25+1011,644:644+2023,:),1050);
lightprobe(isnan(lightprobe))=0;
sRGB_lightprobe = Wytham_HyperspectraltosRGB_400to720nm(lightprobe);
figure(2);imshow(sRGB_lightprobe.^(1/2.2))

% Save sRGB image and Hyperspectral lightprobe
imwrite(power(sRGB_lightprobe,1/2.2),'lightprobe.png')
save('lightprobe','lightprobe')
