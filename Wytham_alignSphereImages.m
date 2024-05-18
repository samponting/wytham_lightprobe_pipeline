clearvars
close all

load('wls_HSI')
load('Wytham_T_xyz1931.mat')
load('SpecularReflectance')
load('LUT_AllAngle_512')
load('cameraMask')
cameraMask = ~cameraMask;
cd('/home/takuma/Documents/MATLAB/GitHub/hyperspectral_environments/matlab/post_process_takuma')

% DatesList = {'2021 April 22nd - 1B','2021 April 22nd - 1C','2021 April 27th - 1B','2021 April 27th - 1C',...
%     '2021 June 2nd - 1B','2021 June 2nd - 1C','2021 June 3rd - 1B','2021 June 3rd - 1C','2021 June 15th - 1B','2021 June 15th - 1C'...
%     '2021 May 07th - 1B','2021 May 07th - 1C','2021 May 14th - 1B','2021 May 14th - 1C'};

DatesList = {'2021 May 07th - 1B'};

sphere_radius_cm = 3.81;
distance_camera_sphere_cm = 27.5;

matfiles = dir('/home/takuma/Documents/MATLAB/GitHub/hyperspectral_environments/matlab/post_process_takuma/Wytham_Dataset_MatFile/');
matfilenames = regexpi({matfiles.name}, '.*mat$', 'match', 'once'); % cell array of matches
matfilenames = matfilenames(~cellfun('isempty',matfilenames)); % get rid of empty cells
matfilenames = matfilenames(~contains(matfilenames,'Feb'));

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
AngleList = -20:20;
for Angle = AngleList
    cnt = cnt + 1;
    load(['RenderedSphere_Line_Angle',num2str(Angle),'.mat'])
    LinePos_renderedSphere(:,cnt) = LinePos;
end

for DateN = 1:length(DatesList)
    matfilenames_selected = matfilenames(contains(matfilenames,DatesList{DateN}));

    MinSize = 10000;
    for ImageN = 1:length(matfilenames_selected)
        load(matfilenames_selected{ImageN});
        if MinSize > size(HSI,1)
            MinSize = size(HSI,1);
        end
    end

    %for ImageN = 1:length(matfilenames_selected)/2
    for ImageN = 1:length(matfilenames_selected)/2

        filename.ground = matfilenames_selected{ImageN};
        filename.sky = matfilenames_selected{ImageN+6};
        
        load(filename.ground);HSI_ground = HSI;saturatedPixels_ground = ~saturatedPixels;inttime.ground = int_time;
        load(filename.sky);HSI_sky = HSI;saturatedPixels_sky = ~saturatedPixels;inttime.sky = int_time;
        
        % Correction of specular highlight
        HSI_ground(:,:,2:2+109) = HSI_ground(:,:,2:2+109)./permute(repmat(SpecularReflectance_selected(:,2),1,size(HSI_ground,1),size(HSI_ground,2)),[2 3 1]);
        HSI_sky(:,:,2:2+109) = HSI_sky(:,:,2:2+109)./permute(repmat(SpecularReflectance_selected(:,2),1,size(HSI_sky,1),size(HSI_sky,2)),[2 3 1]);
        
        % Correction of saturated pixels
        HSI_sky = HSI_sky.*repmat(saturatedPixels_sky,1,1,size(HSI_sky,3));
        HSI_sky(HSI_sky==0) = nan;
        
        imwrite(255*repmat(~saturatedPixels_sky,1,1,3),'mask.png');
        
        %% Correction of camera misalignment 
        % Find angle_misalignment
        %[matcheSphere_sRGB.ground,matchedAngle.ground] = Wytham_getMisalignmentAngle(filename.ground,size(HSI_ground,1));
        %[matcheSphere_sRGB.sky,matchedAngle.sky] = Wytham_getMisalignmentAngle(filename.sky,size(HSI_sky,1));

        matchedAngle.ground = -3;
        matchedAngle.sky = -1;

    end
end
