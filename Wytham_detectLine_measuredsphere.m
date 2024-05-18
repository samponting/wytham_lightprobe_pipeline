clearvars;close all;clc % clean up

load wls_HSI

repo_base_path = '/home/takuma/Documents/MATLAB/GitHub/hyperspectral_environments/';
matfiles = dir(fullfile(repo_base_path,'matlab','post_process_takuma','Wytham_Dataset_matFile'));
matfilenames = regexpi({matfiles.name}, '.*mat$', 'match', 'once'); % cell array of matches
matfilenames = matfilenames(~cellfun('isempty',matfilenames)); % get rid of empty cells

save_path_matFile = fullfile(repo_base_path,'matlab','post_process_takuma','equatorCoordinates_measuredSphere');
mkdir(save_path_matFile)

% DateList = {'2021 April 22nd - 1B','2021 April 22nd - 1C','2021 April 27th - 1B','2021 April 27th - 1C',...
%     '2021 May 07th - 1B','2021 May 07th - 1C','2021 May 14th - 1B','2021 May 14th - 1C',...
%     '2021 June 2nd - 1B','2021 June 2nd - 1C','2021 June 3rd - 1B','2021 June 3rd - 1C','2021 June 15th - 1B','2021 June 15th - 1C',...
%     '2021 October 17th - 1C','2021 October 26th - 1B','2021 October 26th - 1C',...
%     '2021 November 2nd - 1B','2021 November 2nd - 1C','2021 November 9th - 1B','2021 November 9th - 1C'};

% We still need to process these images (14th Dec 2021)
DateList = {'2021 October 17th - 1C','2021 October 26th - 1B','2021 October 26th - 1C',...
    '2021 November 2nd - 1B','2021 November 2nd - 1C','2021 November 9th - 1B','2021 November 9th - 1C'};

cnt = 1;
for w = 400:10:720
    [~,Id(cnt)] = min(abs(wls-w));
    cnt = cnt + 1;
end

for DateN = 1:length(DateList)
    matfilenames_selected = matfilenames(contains(matfilenames,DateList{DateN}));
    
    %for ImageN = 1:length(matfilenames_selected)
    for ImageN = 1
        clf
        matfilenames_selected{ImageN}
        load(matfilenames_selected{ImageN})

        sRGB = Wytham_HSIToSRGBGammaCorrected(HSI(:,:,Id),(400:10:720)')/255;    
        gray = rgb2gray(sRGB);
        gain = prctile(gray(:),80); % normalized by 80th tile value because some images have high dynamic range.
        imshow(gray/gain,'InitialMagnification',300)
        imsize = size(sRGB);
        roi = drawpolyline;
        equatorCoordinates = roi.Position;
        save(fullfile(save_path_matFile,['Equator_',matfilenames_selected{ImageN}]),'equatorCoordinates','imsize')
    end
end