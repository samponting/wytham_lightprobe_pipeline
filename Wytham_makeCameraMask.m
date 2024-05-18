clearvars
close all

load('wls')
load('Wytham_T_xyz1931.mat')
load('SpecularReflectance')

cd('/home/takuma/Documents/MATLAB/GitHub/hyperspectral_environments/matlab/post_process_takuma')

Dates = {'2021 February 12 - 1B','2021 February 12 - 1C','2021 June 2nd - 1B','2021 June 2nd - 1C',...
    '2021 June 2nd - 1B','2021 June 2nd - 1C','2021 June 3rd - 1B','2021 June 3rd - 1C',...
    '2021 May 07th - 1B','2021 May 07th - 1C','2021 May 14th - 1B','2021 May 14th - 1C'};

sphere_radius_cm = 3.81;
distance_camera_sphere_cm = 27.5;

matfiles = dir('/home/takuma/Documents/MATLAB/GitHub/hyperspectral_environments/matlab/post_process_takuma/Wytham_Dataset_MatFile/');
matfilenames = regexpi({matfiles.name}, '.*mat$', 'match', 'once'); % cell array of matches
matfilenames = matfilenames(~cellfun('isempty',matfilenames)); % get rid of empty cells

% Find ids to get wavelengths between 400 - 720 nm
cnt = 1;
for w = 400:10:720
    [~,Id(cnt)] = min(abs(wls-w));
    cnt = cnt + 1;
end

matfilenames = matfilenames(~contains(matfilenames,'Feb'));
%matfilenames = matfilenames(contains(matfilenames,'June 3rd - 1C'));

for ImageN = 1:length(matfilenames)
    ImageN
    load(matfilenames{ImageN});

    AllImage(ImageN).ImageSC = sum(HSI,3);
    ImageSize(ImageN) = size(HSI,1); 
end

for ImageN = 1:length(matfilenames)
    ImageSC(:,:,:,ImageN) = imresize(AllImage(ImageN).ImageSC,[min(ImageSize) min(ImageSize)]);
    ImageSize(ImageN) = size(ImageSC,1); 
end
ImageSC_sum = sum(ImageSC,4);
imagesc(ImageSC_sum);colormap('gray')

mask1 = 1- Wytham_customgauss([size(ImageSC_sum,1),size(ImageSC_sum,2)],8,15, 0, 0, 2, [0 0]);
mask2 = 1- Wytham_customgauss([size(ImageSC_sum,1),size(ImageSC_sum,2)],25,10, 0, 0, 3, [30 0]);
mask3 = 1- Wytham_customgauss([size(ImageSC_sum,1),size(ImageSC_sum,2)],8,30, 0, 0, 2, [55 0]);
cameraMask = mask1+mask2+mask3;
if min(cameraMask(:)) < 0
    cameraMask = cameraMask+abs(min(cameraMask(:)));
end
cameraMask = cameraMask/max(cameraMask(:));
figure(1);imagesc(cameraMask);axis equal;colormap('gray');colorbar
figure(2);imagesc([ImageSC_sum,cameraMask,ImageSC_sum.*cameraMask]);axis equal;colormap('gray')

%roi = drawpolygon;
%cameraMask = poly2mask(roi.Position(:,1),roi.Position(:,2),size(ImageSC_sum,1),size(ImageSC_sum,2));

save('cameraMask_gauss','cameraMask')



