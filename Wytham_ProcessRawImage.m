% cleaning up workspace and close opended windows
clearvars
close all

% This is a demo code to process raw sphere images 
% Input: Raw image - mirror sphere images
% Output: Processed hyperspectral image
% wavelength range is 400 - 720 nm with 10 nm step

% filenames for sample image files
FileName.sphere = 'sphere_angle';
FileName.mask = 'mask_sphere_angle';

% left edge of the sphere to extract sphere region only
LeftEdgeList = [160 190 190 195];

span = .25; % optimal span for smoothing spectra (25% according to the )

load('SpecularReflectance') % specular reflectance separately measured using an apparatus
load('w_IntensityCompression') % weighting to correct a intenisty compression
load('CircleMask') % circle mask to delete margin outside the sphere

for angle = 1:3

figure('Color','w','Position',[0 0 1000 500])

load([FileName.sphere,num2str(angle)]); % loading raw radiance file
load([FileName.mask,num2str(angle)]); % loading mask to exclude saturated pixels

% show raw image in sRGB format
sRGB = Wytham_HyperspectraltosRGB_400to720nm(absolute);
subplot(2,4,1);imshow(sRGB);title('Raw');pause(0.01)

% Step1. Mask saturated pixels
disp('Step 1: Masking saturated pixels...')
absolute_masked = absolute.*repmat(Mask,1,1,size(absolute,3));
sRGB = Wytham_HyperspectraltosRGB_400to720nm(absolute_masked);
subplot(2,4,2);imshow(sRGB);title('Saturated pixels masked');pause(0.01)

% Step 2 and 3. Correction of specular reflection and intensity compression
disp('Step 2 and 3: Correcting specular reflection and intensity compression...')
HSI_Unprocessed = absolute_masked(:,LeftEdgeList(angle):LeftEdgeList(angle)+1023,:)./SpecularReflectance_Matrix.*repmat(w_IntensityCompression,1,1,33);
sRGB = Wytham_HyperspectraltosRGB_400to720nm(HSI_Unprocessed);
subplot(2,4,3);imshow(sRGB);title('SR and compression corrected');pause(0.01)

% Step 4. Smooth spectral using loess with 25% span (optimized through one-leave-out cross validation) 
disp('Step 4: Smoothing spectrum at all pixels...')
HSI_Smoothed = zeros(size(HSI_Unprocessed));
for row = 1:size(HSI_Unprocessed,1)
    for col = 1:size(HSI_Unprocessed,2)
        HSI_Smoothed(row,col,:) = smooth(HSI_Unprocessed(row,col,:),span,'loess');
    end
end
sRGB = Wytham_HyperspectraltosRGB_400to720nm(HSI_Smoothed);
subplot(2,4,4);imshow(sRGB);title('Smoothed');pause(0.01)

% Step 5. Mask margin outside of sphere
disp('Step 5: Masking margin...')
HSI_Masked = HSI_Smoothed.*repmat(CircleMask,1,1,33);
sRGB = Wytham_HyperspectraltosRGB_400to720nm(HSI_Masked);
subplot(2,4,5);imshow(sRGB);title('Margin masked');pause(0.01)

%HSI_Masked_reshaped = reshape(HSI_Masked,size(HSI_Masked,1)*size(HSI_Masked,2),size(HSI_Masked,3));

% Step 6. Unwrap to correct the sptial distortion
disp('Step 6: Unwrapping the sphere...')
s = 89; % distance between a mirror sphere and a camera in cm
d = 7.62; % diameter of mirror sphere (3 inches = 7.62 cm)
HSI_Unwrapped = Wytham_Unwrap(HSI_Masked.*repmat(CircleMask,1,1,33),s,d);

sRGB = Wytham_HyperspectraltosRGB_400to720nm(HSI_Unwrapped);
subplot(2,4,6);imshow(sRGB);title('Unwrapped');pause(0.01)

% Step 7. Fill in the masked region 
disp('Step 7:Filling in the masked region...')
% The edge of the image should not be used because of low spatial resolution
% I'm cropping each side by 257 pixels
CropPixel = 257;
HSI_Unwrapped_Nan = HSI_Unwrapped(:,CropPixel:end-CropPixel,:);
HSI_Unwrapped_Nan(HSI_Unwrapped_Nan==0) = nan;
HSI_Unwrapped_FilledIn = fillmissing(HSI_Unwrapped_Nan,'linear',2); % filling in horizontal direction
sRGB = Wytham_HyperspectraltosRGB_400to720nm(HSI_Unwrapped_FilledIn);
subplot(2,4,7);imshow(sRGB);title('Filled');pause(0.01)

HSI = HSI_Unwrapped_FilledIn;

save(['scene_angle',num2str(angle),'_processed'],'HSI')

disp('Processed image saved!')
end
