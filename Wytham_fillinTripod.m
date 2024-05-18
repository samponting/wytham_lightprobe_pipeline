clearvars;close all % clear up

% wavelength range for hyperspectral image (SPECIM)
load wls_HSI

% set here the repository base
repo_base_path = '/home/takuma/Documents/MATLAB/GitHub/hyperspectral_environments';

sphere_radius_cm = 3.81;
distance_camera_sphere_cm = 27.5;

% Find ids to get wavelengths between 400 - 720 nm
cnt = 1;
for w = 400:10:720
    [~,Id(cnt)] = min(abs(wls-w));
    cnt = cnt + 1;
end

matfiles = dir(fullfile(repo_base_path,'matlab','post_process_takuma','Wytham_Dataset_matFile_Processed'));
matfilenames = regexpi({matfiles.name}, '.*mat$', 'match', 'once'); % cell array of matches
matfilenames = matfilenames(contains(matfilenames,'Processed'));
matfilenames = matfilenames(~cellfun('isempty',matfilenames)); % get rid of empty cells

% make directory to save a sRGB files
mkdir(fullfile('Wytham_Dataset_matFile_Processed','sRGB_Files'))

% DateList = {'2021 April 22nd - 1B','2021 April 22nd - 1C','2021 April 27th - 1B','2021 April 27th - 1C',...
%     '2021 May 07th - 1B','2021 May 07th - 1C','2021 May 14th - 1B','2021 May 14th - 1C',...
%     '2021 June 2nd - 1B','2021 June 2nd - 1C','2021 June 3rd - 1B','2021 June 3rd - 1C','2021 June 15th - 1B','2021 June 15th - 1C',...
%     '2021 October 17th - 1C','2021 October 26th - 1B','2021 October 26th - 1C',...
%     '2021 November 2nd - 1B','2021 November 2nd - 1C','2021 November 9th - 1B','2021 November 9th - 1C'};
DateList = {'2021 June 2nd - 1C'};

% Go through all dates and process images
for DateN = 1:length(DateList)
    close all % closing all figures
    load cameraMask
    clear HSI_allAngles Lum_allAngles sRGB_allAngles
    
    matfilenames_selected = matfilenames(contains(matfilenames,DateList{DateN}));

    for ImageN = 1:length(matfilenames_selected)
        load(fullfile('Wytham_Dataset_matFile_Processed',matfilenames{ImageN}))
        imageSize(ImageN) = size(HSI,1);
    end   
    
    edge = 60; % this is to cut the edge of the images where angular compression is severe
    for ImageN = 1:length(matfilenames_selected)
        load(fullfile('Wytham_Dataset_matFile_Processed',matfilenames_selected{ImageN}))

        HSI_allAngles(:,:,:,ImageN) = HSI(:,edge:end-edge,:);
        XYZ = Wytham_HyperspectraltoXYZ_400to720nm(HSI(:,edge:end-edge,Id));
        Lum_allAngles(:,:,ImageN) = XYZ(:,:,2)/max(max(XYZ(:,:,2)));
        sRGB_allAngles(:,:,:,ImageN) = sRGB(:,edge:end-edge,:);    
    end
    
    % adjust the size of the mask to the size of hyperspectral images
    cameraMask = imresize(cameraMask,[size(HSI_allAngles,1) size(HSI_allAngles,1)]);
    
    % unwrapp the mask to match the coordinate to hyperspectral images
    mask = Wytham_Unwrap(cameraMask,distance_camera_sphere_cm,sphere_radius_cm*2);
    mask = mask(:,edge:end-edge); % crop the edge

    center = round(size(mask,2)/2); % center of the mask
    
    sRGB_allAngles_reshaped = reshape(sRGB_allAngles,[size(sRGB_allAngles,1) size(sRGB_allAngles,2) size(sRGB_allAngles,3) 2 3]);
    imshow(reshape(permute(sRGB_allAngles_reshaped,[1 4 2 5 3]),[size(sRGB_allAngles,1)*2,size(sRGB_allAngles,2)*3,3]));
    
    % Adding first angle to the end of the images. First angle is used to fill the final angle.
    Lum_allAngles(:,:,end+1) = Lum_allAngles(:,:,1);
    sRGB_allAngles(:,:,:,end+1) = sRGB_allAngles(:,:,:,1);
    HSI_allAngles(:,:,:,end+1) = HSI_allAngles(:,:,:,1);
    
    % this defines the size of patch (in pixels) that is used to find the
    % matching point between two images
    patchwidth = 25;
    
    % We will not use upper edge to crop out the patch (30 pixels below the upper edge)
    upperedge = 30;

    for ImageN = 1:length(matfilenames_selected)
        
        % image of angle that is filled
        I = HSI_allAngles(upperedge:round(size(Lum_allAngles,1)/2.2),:,:,ImageN);
        center = round(size(I,2)/2);
        
        % image of angle + 1 that filles the angle 1
        I_next = HSI_allAngles(upperedge:round(size(Lum_allAngles,1)/2.2),:,:,ImageN+1);
        
        % crop out the color patch from to find the match between two images
        patch = I(:,center-patchwidth:center+patchwidth);

        % Calculate cross-correlation by shifting the image horizontally
        for col = 1+patchwidth:size(I_next,2)-patchwidth
            patch_next = I_next(:,col-patchwidth:col+patchwidth);
            coeff(col) = corr2(patch(:),patch_next(:));
        end
        
        % find the maximum correaltion and plot the trend
        [~,coeffId] = max(coeff);
        plot(coeff)
        
        % find how much we need to shift the 
        Shift = coeffId + patchwidth;

        sRGB = sRGB_allAngles(:,:,:,ImageN);
        sRGB_next = sRGB_allAngles(:,:,:,ImageN+1);
        sRGB_next_shifted = Wytham_ShiftImage(sRGB_next,-Shift);  
        figure;imshow(sRGB.*mask+sRGB_next_shifted.*~mask)
        figure;imshow(sRGB+sRGB_next_shifted.*~mask)

        HSI1 = HSI_allAngles(:,:,:,ImageN);
        HSI_next = HSI_allAngles(:,:,:,ImageN+1);
        
        % fill in the masked region
        HSI = HSI1.*repmat(mask,1,1,size(I,3)) + Wytham_ShiftImage(HSI_next,-Shift).*repmat(~mask,1,1,size(I,3));
            
        sRGB_next_shifted = Wytham_ShiftImage(sRGB_next,-Shift);  
        
        sRGB_out = sRGB.*mask+sRGB_next_shifted.*~mask;
        imshow(sRGB_out)
        
        imwrite(sRGB_out,fullfile('Wytham_Dataset_matFile_Processed','sRGB_Files',['TripodErased',erase(matfilenames_selected{ImageN},'Processed'),'.png']))
        save(fullfile('Wytham_Dataset_matFile_Processed',['TripodErased',erase(matfilenames_selected{ImageN},'Processed')]),'HSI','sRGB')
    end
end