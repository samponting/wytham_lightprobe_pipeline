% This code load raw SPECIM files, crop the region of the sphere from the image, apply the spectral calibration to image and save the sphere images and mask for saturated pixels in mat files.
% code takes a while
clearvars;close all;clc % clean up

% set path to the root of the dataset (adjust to your path)
repo_base_path = '/home/takuma/Documents/MATLAB/GitHub/hyperspectral_environments/';
cd(fullfile(repo_base_path,'matlab','post_process_takuma'))

% Find ids to get wavelengths between 400 - 720 nm
load wls_HSI

cnt = 0;
for w = 400:10:720
    cnt = cnt + 1;
    [~,Id(cnt)] = min(abs(wls-w));
end

dataset_path = fullfile(repo_base_path,'matlab','post_process_takuma','Wytham_Dataset');
save_path_matFile = fullfile(repo_base_path,'matlab','post_process_takuma','Wytham_Dataset_matFile');
save_path_sRGB = fullfile(save_path_matFile,'sRGB Files');
mkdir(save_path_matFile);
mkdir(save_path_sRGB);

% As of 10th Dec 2021, there are 20 following data folders (make sure to download all from the shared one drive folder)
DateList = {'2021 April 22nd - 1B','2021 April 22nd - 1C','2021 April 27th - 1B','2021 April 27th - 1C',...
    '2021 May 07th - 1B','2021 May 07th - 1C','2021 May 14th - 1B','2021 May 14th - 1C',...
    '2021 June 2nd - 1B','2021 June 2nd - 1C','2021 June 3rd - 1B','2021 June 3rd - 1C','2021 June 15th - 1B','2021 June 15th - 1C',...
    '2021 October 17th - 1C','2021 October 26th - 1B','2021 October 26th - 1C',...
    '2021 November 2nd - 1B','2021 November 2nd - 1C','2021 November 9th - 1B','2021 November 9th - 1C'};

% grab the calibration for the camera that translates from Digital Number
% (DN) to radiance.
HSI_cal = read_specim_cal_file(fullfile(repo_base_path,'data','specim_calibration','Radiometric_1x1.cal'));
        
for N = 1:length(DateList)
    temp = dir(fullfile(dataset_path,DateList{N}));
    folderpath(N).foldername = temp(3:end); % datafile starts from index 3 (this may differ depending on the system you are on. So please check.)
    folderpath(N).fileNum = length(folderpath(N).foldername);
end

% 
sensitivity = 0.97;

% TM : These gain values were determined by try and error 
gain(1).list = [1 1 1 1 1 1 1 1 1 3 1.2 1.2]; %2021 April 22nd - 1B
gain(2).list = [0.03 1 1 1 2 1 1 1 1 1 2.3 2]; %2021 April 22nd - 1C
gain(3).list = [1.5 2 1 1 1 1 0.6 1 1 2 3 4]; %2021 April 27th - 1B
gain(4).list = [1 2 1 1 1 1 2 3 2 1 1 1];  %2021 April 27th - 1C
gain(5).list = [1 1 1 1 1 1 1 1 1 1 1 1]; %2021 May 07th - 1B        
gain(6).list = [1 1 1 1 1 1 1 1 1 5 5 5]; %2021 May 07th - 1C        
gain(7).list = [1 1 1 1 1 1 1 1 5 5 5 5]; %2021 May 14th - 1B
gain(8).list = [1 1 1 1 1 1 1 1 1 1 5 5]; %2021 May 14th - 1C
gain(9).list = [1 1 1 1 1 1 1 5 5 5 5 5]; %2021 June 2nd - 1B        
gain(10).list = [5 5 5 1 1 3 5 1 1 1 1 5]; %2021 June 2nd - 1C
gain(11).list = [1.5 1 1 1 1 1 1 3 3 5 5 5]; %2021 June 3rd - 1B
gain(12).list = [1 1 1 1 3 3 3 3 3 5 10 5]; %2021 June 3rd - 1C
gain(13).list = [1 1 1 1 1 1 1 1 1 1 1 1]; %2021 June 15th - 1B
gain(14).list = [1 1 1 1 1 1 1 3 3 3 3 3]; %2021 June 15th - 1C
gain(15).list = [5 9.5 9 7.8 7 7 7 6 6 7 7 6]; %2021 October 17th - 1C
gain(16).list = [1 5 2 1 1 1 1 1 1 5 5 3]; %2021 October 26th - 1B
gain(17).list = [1 9 11 6 6 9 10 6 5 5 9 5]; %2021 October 26th - 1C
gain(18).list = [1 9 11 1 1 1 5 2 1 5 1 1]; %2021 November 2nd - 1B
gain(19).list = [1 9 11 1 1 9 5 2 1 5 1 1]; %2021 November 2nd - 1C
gain(20).list = [1 5 3 1 1 5 3 2 2 5 5 2]; %2021 November 9th - 1B
gain(21).list = [1 5 3 1 1 5 3 2 2 5 2 2]; %2021 November 9th - 1C

maxVal = 4095; % max value in 12 bits

% Set number and type (ground indicates longer exposure time) 
% data order for data collected in April, May and June 2021
data_order1 = {'ground','ground','ground','ground','ground','ground','sky','sky','sky','sky','sky','sky'};

% data order for data collected in October and November 2021
data_order2 = {'ground','sky','sky','ground','ground','sky','sky','ground','ground','sky','sky','ground'}; % 2021 October 17th - 1C

%for DayN = 1:length(DateList)
for DayN = 21
    disp(['Saving data on ',DateList{DayN},'...'])
    ground_cnt = 0;
    sky_cnt = 0;
    
    if contains(DateList{DayN},'April')||contains(DateList{DayN},'May')||contains(DateList{DayN},'June')
        data_order = data_order1;
    elseif contains(DateList{DayN},'October')||contains(DateList{DayN},'November')
        data_order = data_order2;
    end
    
    for folderN = 1:folderpath(DayN).fileNum
        disp(['image ',num2str(folderN)])
        
        % grab files from a single capture - raw image, dark reference, and
        % metadata
        [HSI_raw, HSI_dr, metafile] = read_specim_dir(fullfile(dataset_path,'/',DateList{DayN},'/',folderpath(DayN).foldername(folderN).name,'/capture'));
        
        % grab the integration time from the metadata - important to calc radiance
        int_time = parse_metafile(metafile);

        [HSI_sphere, pixel_diameter, HSI_sphere_dr, HSI_sphere_cal] = Wytham_extract_sphere(HSI_raw, HSI_dr, HSI_cal,gain(DayN).list(folderN),sensitivity);
        %figure;imagesc(HSI_sphere(:,:,100))
        
        HSI_sphere = imrotate(HSI_sphere,-90);

        % detect saturated pixels
        HSI_max = max(HSI_sphere,[],3);
        saturatedId = find(HSI_max==maxVal);
        saturatedPixels = HSI_max==maxVal;
        
        HSI = calibrate_image(HSI_sphere, HSI_sphere_dr, HSI_sphere_cal, int_time);
        
        if strcmp(data_order{folderN},'ground')
            ground_cnt = ground_cnt + 1;
            filename = [DateList{DayN},'_ground',num2str(ground_cnt)];
        elseif strcmp(data_order{folderN},'sky')
            sky_cnt = sky_cnt + 1;
            filename = [DateList{DayN},'_sky',num2str(sky_cnt)];
        end
        
        save(fullfile(save_path_matFile,filename),'HSI','saturatedPixels','int_time')
        
        % save sRGB files to visually check the data
        sRGB = Wytham_HyperspectraltosRGB_400to720nm(HSI(:,:,Id));
        sRGB = max(sRGB,0);
        imwrite(sRGB,fullfile(save_path_sRGB,[filename,'.png']))
    end
    disp('Done.')
end
close all