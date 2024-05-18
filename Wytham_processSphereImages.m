clearvars;close all;clc % clean up

% set here the repository base
repo_base_path = '/home/takuma/Documents/MATLAB/GitHub/hyperspectral_environments';

load wls_HSI
load Wytham_T_xyz1931.mat
load specularReflectance_chromeball
load LUT_AllAngle_512
load cameraMask

save_path_sRGB = fullfile(repo_base_path,'matlab','post_process_takuma','Wytham_Dataset_matFile_Processed','sRGB_Files');
save_path_matFile = fullfile(repo_base_path,'matlab','post_process_takuma','Wytham_Dataset_matFile_Processed');
mkdir(save_path_sRGB)
mkdir(save_path_matFile)

DateList = {'2021 April 22nd - 1B','2021 April 22nd - 1C','2021 April 27th - 1B','2021 April 27th - 1C',...
    '2021 May 07th - 1B','2021 May 07th - 1C','2021 May 14th - 1B','2021 May 14th - 1C',...
    '2021 June 2nd - 1B','2021 June 2nd - 1C','2021 June 3rd - 1B','2021 June 3rd - 1C','2021 June 15th - 1B','2021 June 15th - 1C',...
    '2021 October 17th - 1C','2021 October 26th - 1B','2021 October 26th - 1C',...
    '2021 November 2nd - 1B','2021 November 2nd - 1C','2021 November 9th - 1B','2021 November 9th - 1B'};

sphere_radius_cm = 3.81;
distance_camera_sphere_cm = 27.5;

cd(fullfile(repo_base_path,'matlab','post_process_takuma'))

matfiles = dir(fullfile(repo_base_path,'matlab','post_process_takuma','Wytham_Dataset_matFile'));
matfilenames = regexpi({matfiles.name}, '.*mat$', 'match', 'once'); % cell array of matches
matfilenames = matfilenames(~cellfun('isempty',matfilenames)); % get rid of empty cells

disp(['Number of files that will be processed:',num2str(length(matfilenames))])

% Find ids to get wavelengths between 400 - 720 nm
cnt = 1;
for w = 400:10:720
    [~,Id(cnt)] = min(abs(wls-w));
    cnt = cnt + 1;
end

for n = 1:length(SpecularReflectance)
    specular_wl = SpecularReflectance(n,1);
    [~,wlsId(n)] = min(abs(wls-specular_wl));
end

[t,wlsId_Extracted] = unique(wlsId);

SpecularReflectance_selected = SpecularReflectance(wlsId_Extracted,:);

cnt = 0;

% process for lal imaages
for DateN = 1:length(DateList)
    matfilenames_selected = matfilenames(contains(matfilenames,DateList{DateN}));
    
    % determine the minimum image size across all angles
    minSize = 10000; % initializion
    for ImageN = 1:length(matfilenames_selected)
        load(matfilenames_selected{ImageN});
        if minSize > size(HSI,1)
            minSize = size(HSI,1);
        end
    end

    % divided by 2 because we process ground and sky images in parallel
    for ImageN = 1:length(matfilenames_selected)/2        
        filename.ground = matfilenames_selected{ImageN};
        filename.sky = matfilenames_selected{ImageN+6};

        disp(['Processing ',filename.ground,' and ',filename.sky,'...'])
        
        load(filename.ground);HSI_ground = HSI;saturatedPixels_ground = ~saturatedPixels;inttime.ground = int_time;
        load(filename.sky);HSI_sky = HSI;saturatedPixels_sky = ~saturatedPixels;inttime.sky = int_time;
        
        % Correction of specular highlight (applied only to 400 nm to 720 nm, every 10 nm steps)
        HSI_ground(:,:,2:2+109) = HSI_ground(:,:,2:2+109)./permute(repmat(SpecularReflectance_selected(:,2),1,size(HSI_ground,1),size(HSI_ground,2)),[2 3 1]);
        HSI_sky(:,:,2:2+109) = HSI_sky(:,:,2:2+109)./permute(repmat(SpecularReflectance_selected(:,2),1,size(HSI_sky,1),size(HSI_sky,2)),[2 3 1]);
        
        % Correction of saturated pixels for sky image
        HSI_sky = HSI_sky.*repmat(saturatedPixels_sky,1,1,size(HSI_sky,3));
        HSI_sky(HSI_sky==0) = nan;
        
        %% Correction of camera misalignment 
        % Find angle_misalignment and correct the misalignment (curretnly based on blender method that is not perfect. This may needs to be updated.)
        [matchedSphere_sRGB.ground,matchedAngle.ground] = Wytham_getMisalignmentAngle(filename.ground,size(HSI_ground,1));
        [matchedSphere_sRGB.sky,matchedAngle.sky] = Wytham_getMisalignmentAngle(filename.sky,size(HSI_sky,1));
        HSI_ground_aligned = Wytham_correctMisalignment(HSI_ground,matchedAngle.ground);
        HSI_sky_aligned = Wytham_correctMisalignment(HSI_sky,matchedAngle.sky);

        % Convert hyperspectral images to sRGB gamma-corrected image 
        sRGB_ground_original = Wytham_HSIToSRGBGammaCorrected(HSI_ground(:,:,Id),(400:10:720)')/255;
        sRGB_ground_aligned = Wytham_HSIToSRGBGammaCorrected(HSI_ground_aligned(:,:,Id),(400:10:720)')/255;
        sRGB_sky_original = Wytham_HSIToSRGBGammaCorrected(HSI_sky(:,:,Id),(400:10:720)')/255;
        sRGB_sky_aligned = Wytham_HSIToSRGBGammaCorrected(HSI_sky_aligned(:,:,Id),(400:10:720)')/255;
        
        % Equate size and show images
        sRGB_ground_original_resized = imresize(sRGB_ground_original,[minSize minSize]);
        sRGB_ground_aligned_resized = imresize(sRGB_ground_aligned,[minSize minSize]);
        sRGB_sky_original_resized = imresize(sRGB_sky_original,[minSize minSize]);
        sRGB_sky_aligned_resized = imresize(sRGB_sky_aligned,[minSize minSize]);        
        subplot(1,2,1);imshow([[sRGB_ground_original_resized,sRGB_ground_aligned_resized];[sRGB_sky_original_resized,sRGB_sky_aligned_resized]])

        % Correct the image size to the smaller one
        min_size = min(size(HSI_ground_aligned,1),size(HSI_sky_aligned,1));    
        HSI_ground_aligned = imresize(HSI_ground_aligned,min_size/size(HSI_ground_aligned,1));
        HSI_sky_aligned = imresize(HSI_sky_aligned,min_size/size(HSI_sky_aligned,1));

        % Correct the image size to the smaller one
        HSI_ground_sum = sum(HSI_ground_aligned,3);
        HSI_sky_sum = sum(HSI_sky_aligned,3);

        % Coverted to luminance image
        XYZ_sky = Wytham_HyperspectraltoXYZ_400to720nm(HSI_sky_aligned(:,:,Id));
        Lum = XYZ_sky(:,:,2);
        normalizedLum = Lum/max(Lum(:));

        % Find 'dark pixels' to be filled with ground images
        % Dark pixel is defined by darker than 2.5% of highest luminance in
        % the image (this may need to be updated)
        darkId_sky = find(normalizedLum < 0.025);
        [row_sky,col_sky] = ind2sub(size(HSI_sky_sum),darkId_sky);

        HSI_filled = HSI_sky_aligned;
        
        % Fill in dark pixels in sky images by the corresponding pixels in ground images
        for n  = 1:length(col_sky)
            HSI_filled(row_sky(n),col_sky(n),:) = HSI_ground_aligned(row_sky(n),col_sky(n),:);
        end

        sRGB_sky = Wytham_HSIToSRGBGammaCorrected(HSI_sky(:,:,Id),(400:10:720)')/255;
        sRGB_sky_filled = Wytham_HSIToSRGBGammaCorrected(HSI_filled(:,:,Id),(400:10:720)')/255;

        % Mask camera region
        cameraMask_resized = imresize(cameraMask,[size(HSI_filled,1),size(HSI_filled,2)]);
        HSI_filled = HSI_filled.*repmat(cameraMask_resized,1,1,size(HSI_filled,3));

        % Correction of intensity compression (*this may need to be updated)
        w = Wytham_GetCorrectionofIntensityCompression(size(HSI_filled,1)/2,sphere_radius_cm,distance_camera_sphere_cm);
        HSI_filled = HSI_filled.*repmat(w,1,1,size(HSI_filled,3));

        % Equate size 
        HSI_filled = imresize(HSI_filled,[minSize minSize]);

        % Unwrap to correct the sptial distortion
        HSI_Unwrapped = Wytham_Unwrap(HSI_filled,distance_camera_sphere_cm,sphere_radius_cm*2);
        
        % Fill missing pixels because of saturation
        HSI_Unwrapped = fillmissing(HSI_Unwrapped,'linear',2); % filling in horizontal direction (this may need to be updated)       

        % converting hyperspectral images to sRGB images
        sRGB = Wytham_HyperspectraltosRGB_400to720nm(HSI_Unwrapped(:,:,Id));
        subplot(1,2,2);imshow(sRGB);title('processed and unwrapped');pause(0.01)
        imwrite(sRGB,['./Wytham_Dataset_matFile_Processed/sRGB_Files/Processed_',erase(matfilenames_selected{ImageN},["ground",".mat"]),'.png'])
        
        % save images
        HSI = HSI_Unwrapped;
        save(['./Wytham_Dataset_matFile_Processed/Processed_',erase(matfilenames_selected{ImageN},["ground",".mat"])],'HSI','sRGB','matchedAngle')

        disp('Processed images saved!')
    end
end
