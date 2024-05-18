clearvars;close all % clear up

load wls_HSI

% set here the repository base
repo_base_path = '/home/takuma/Documents/MATLAB/GitHub/hyperspectral_environments';

% Find ids to get wavelengths between 400 - 720 nm
cnt = 1;
for w = 400:10:720
    [~,Id(cnt)] = min(abs(wls-w));
    cnt = cnt + 1;
end

matfiles = dir(fullfile(repo_base_path,'matlab','post_process_takuma','Wytham_Dataset_matFile_Processed'));
matfilenames = regexpi({matfiles.name}, '.*mat$', 'match', 'once'); % cell array of matches
matfilenames = matfilenames(contains(matfilenames,'TripodErased')); 
matfilenames = matfilenames(~cellfun('isempty',matfilenames)); % get rid of empty cells

% DateList = {'2021 April 22nd - 1B','2021 April 22nd - 1C','2021 April 27th - 1B','2021 April 27th - 1C',...
%     '2021 May 07th - 1B','2021 May 07th - 1C','2021 May 14th - 1B','2021 May 14th - 1C',...
%     '2021 June 2nd - 1B','2021 June 2nd - 1C','2021 June 3rd - 1B','2021 June 3rd - 1C','2021 June 15th - 1B','2021 June 15th - 1C',...
%     '2021 October 17th - 1C','2021 October 26th - 1B','2021 October 26th - 1C',...
%     '2021 November 2nd - 1B','2021 November 2nd - 1C','2021 November 9th - 1B','2021 November 9th - 1C'};
DateList = {'2021 June 2nd - 1C'};

for DateN = 1:length(DateList)
    close all
    clear HSI_allAngles Lum_allAngles sRGB_allAngles    

    matfilenames_selected = matfilenames(contains(matfilenames,DateList{DateN}));

    for ImageN = 1:length(matfilenames_selected)
        load(['./Wytham_Dataset_matFile_Processed/',matfilenames_selected{ImageN}])
        HSI_allAngles(:,:,:,ImageN) = HSI;
        XYZ = Wytham_HyperspectraltoXYZ_400to720nm(HSI(:,:,Id));
        Lum_allAngles(:,:,ImageN) = XYZ(:,:,2)/max(max(XYZ(:,:,2)));
        sRGB_allAngles(:,:,:,ImageN) = sRGB;  
    end
end

sRGB_allAngles_reshaped = reshape(sRGB_allAngles,[size(sRGB_allAngles,1) size(sRGB_allAngles,2) size(sRGB_allAngles,3) 2 3]);

imshow(reshape(permute(sRGB_allAngles_reshaped,[1 4 2 5 3]),[size(sRGB_allAngles,1)*2,size(sRGB_allAngles,2)*3,3]));

%% Stitching
% replace this line to the folder you put your VLFeat 0.9.21 binary package
run(fullfile('vlfeat-0.9.21','toolbox','vl_setup'))

% We make 360 degrees panorama image so full360 is set to TRUE
full360 = 1;

% Stiching images
%Lum_allAngles = Lum_allAngles/max(Lum_allAngles(:));
HSI_panorama = Wytham_StitchImage_Sift(HSI_allAngles(:,:,:,[1 4 6]),Lum_allAngles(:,:,[1 4 6]),full360);
HSI_panorama(isnan(HSI_panorama))=0;
sRGB_panorama = Wytham_HyperspectraltosRGB_400to720nm(HSI_panorama(:,:,Id));
figure(1);imshow(sRGB_panorama)

% Crop the image to generate the final form
height = size(HSI_allAngles,1);
width = height*2;

%for n = -5:5
    %lightprobe = Wytham_ShiftImage(HSI_panorama(8:8+height,n:n+width,:),300);
    lightprobe = Wytham_ShiftImage(HSI_panorama(20:20+height,172:658,:),100);

    lightprobe(isnan(lightprobe))=0;
    sRGB_lightprobe = Wytham_HyperspectraltosRGB_400to720nm(lightprobe(:,:,Id));
    imshow(sRGB_lightprobe);
    pause(1)
%end

% Save sRGB image and hyperspectral lightprobe
sRGB_lightprobe = imresize(sRGB_lightprobe,[size(sRGB_lightprobe,1) size(sRGB_lightprobe,1)*2]);
imshow(sRGB_lightprobe)
lightprobe = imresize(lightprobe,[size(lightprobe,1) size(lightprobe,1)*2]);

mkdir Wytham_lightprobe
imwrite(sRGB_lightprobe,['./Wytham_lightprobe/',erase(matfilenames_selected{1},'TripodErased_'),'.png'])
save(['./Wytham_lightprobe/',erase(matfilenames_selected{1},'TripodErased_')],'lightprobe')

% Make wavelength bin
cnt = 1;ww = 10;
for w = 400:10:720
    channels(cnt) = {[num2str(w-5),'.00-',num2str(w-5+ww),'.00nm']};
    cnt = cnt + 1;
end

lightprobe_sampled = lightprobe(:,:,Id);
Wytham_MatrixtoHyperspectralEXR(['./Wytham_lightprobe/',erase(matfilenames_selected{1},{'.mat','TripodErased_'}),'.exr'],lightprobe_sampled,channels)