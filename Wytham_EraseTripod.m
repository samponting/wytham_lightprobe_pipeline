clearvars
close all

% file name
FileName = 'scene_angle';

% parameters to generate gaussian mask to erase tripod for 4 angles
% order is [vertical centre position, sigmax, sigmay]
% unit is pixel
maskp = {[200,80,150],[200,80,180],[200,120,180],[200,80,180]};

% amount in pixel to shift filling image to match the image position
% between target image and fill image
ShiftList = [490,550,480,533];

AngleOrder = [1 2 3 4 1];

% allocate memory for images with tripod
HSI_tripod = zeros(1024,1549,33);
sRGB_tripod = zeros(1024,1549,3);

% load images from all angles
for angle = 1:4
    load([FileName,num2str(angle),'_processed']);
    HSI_tripod(:,:,:,angle) = HSI;
    sRGB_tripod(:,:,:,angle) = Wytham_HyperspectraltosRGB_400to720nm(HSI);
end

% allocate memory for images without tripod
HSI_tripoderased = zeros(size(HSI_tripod));
sRGB_tripoderased = zeros(size(sRGB_tripod));

for angle = 1:4
    
    % get parameter to generate mask to delete the tripod
    p = maskp{angle};
    centery = p(1);sigmax = p(2);sigmay = p(3);
    mask = 1-Wytham_customgauss([size(HSI_tripod,1),size(HSI_tripod,2)],sigmay,sigmax, 0, 0, 1, [centery 0]);
    
    HSITarget = HSI_tripod(:,:,:,AngleOrder(angle)); % Get target image we want to delete the tripod
    HSIFill = HSI_tripod(:,:,:,AngleOrder(angle+1)); % Get fill image to be used to fill the deleted tripod region
    
    % Mask the tripod and fill in the blank using a neighbouring angle
    HSI_tripoderased(:,:,:,angle) = repmat(mask.^2,1,1,size(HSITarget,3)).*HSITarget+...
        (1-repmat(mask.^2,1,1,size(HSITarget,3))).*Wytham_ShiftImage(HSIFill,ShiftList(angle));
    
    % Convert hyperspectral image to sRGB
    sRGB_tripoderased(:,:,:,angle) = Wytham_HyperspectraltosRGB_400to720nm(HSI_tripoderased(:,:,:,angle));
end

% show images to check if the tripod was deleted properly
imshow(vertcat([sRGB_tripod(:,:,:,1),sRGB_tripod(:,:,:,2),sRGB_tripod(:,:,:,3),sRGB_tripod(:,:,:,4)],...
    [sRGB_tripoderased(:,:,:,1),sRGB_tripoderased(:,:,:,2),sRGB_tripoderased(:,:,:,3),sRGB_tripoderased(:,:,:,4)]))

% save hyperspectral images without tripod
for angle = 1:4
    HSI = HSI_tripoderased(:,:,:,angle);
    save(['scene_angle',num2str(angle),'_tripoderased'],'HSI')
end
