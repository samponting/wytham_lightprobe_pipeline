function [ newImg ] = Wytham_Merge(Lums,HSI,absoluteTrans,panorama_h,panorama_w,f)
%Lums=im2double(Lums);
height = size(Lums, 1);
width = size(Lums, 2);
nChannels = size(HSI, 3);
nImgs = size(Lums, 3);

mask = ones(height, width);
mask = Wytham_Warp(mask, f);
mask = imcomplement(mask);
mask = bwdist(mask, 'euclidean');

mask = mask ./ max(max(mask));
mask(mask>1)=1;
m=ones([height,width,nChannels],'like',Lums);
for i=1:nChannels
   m(:,:,i)=mask;
end
mask=m;
% image merging

%max_h=0;
%min_h=0;
%max_w=0;
%min_w=0;
max_h=-10^10;max_w=-10^10;
min_h=10^10;min_w=10^10;

for i=1:nImgs
    p_prime=absoluteTrans(:,:,i)*[1;1;1];
    p_prime=p_prime./p_prime(3);
    base_h=floor(p_prime(1));
    base_w=floor(p_prime(2));
    if base_h>max_h
        max_h=base_h;
    end
    if base_h<min_h
        min_h = base_h;
    end
    if base_w>max_w
        max_w=base_w;
    end
    if base_w<min_w
        min_w=base_w;
    end
end

%newImg = zeros([panorama_h+100,panorama_w+100,nChannels], 'like',Lums);
%denominator = zeros([panorama_h+100,panorama_w+100,nChannels], 'like',Lums);
newImg = zeros(panorama_h+1000,panorama_w+1000,nChannels);
denominator = zeros(panorama_h+1000,panorama_w+1000,nChannels);

for i=1:nImgs
    p_prime=absoluteTrans(:,:,i)*[min_h+10;min_w+10;1];
    p_prime=p_prime./p_prime(3);
    base_h=floor(p_prime(1));
    base_w=floor(p_prime(2));
    %if base_h==0
    if base_h<=0
        base_h=1;
    end
    %if base_w==0
    if base_w<=0
        base_w=1;
    end
    
    if base_h+height-1>size(newImg,1)||base_w+width-1>size(newImg,2)
        newImg = zeros(size(newImg));
        disp('Warinig: Stitching didn NOT work!!')
        return;
    else
        newImg(base_h:base_h+height-1,base_w:base_w+width-1,:)=...
            newImg(base_h:base_h+height-1,base_w:base_w+width-1,:)+...
            HSI(:,:,:,i).*mask;
        denominator(base_h:base_h+height-1,base_w:base_w+width-1,:)=...
            denominator(base_h:base_h+height-1,base_w:base_w+width-1,:)+...
            mask;
    end
    
%     newImg(base_h:min(base_h+height-1,size(newImg,1)),base_w:min(base_w+width-1,size(newImg,2)),:)=...
%         newImg(base_h:min(base_h+height-1,size(newImg,1)),base_w:min(base_w+width-1,size(newImg,2)),:)+...
%         HSI(:,:,:,i).*mask;
%     denominator(base_h:min(base_h+height-1,size(newImg,1)),base_w:min(base_w+width-1,size(newImg,2)),:)=...
%         denominator(base_h:min(base_h+height-1,size(newImg,1)),base_w:min(base_w+width-1,size(newImg,2)),:)+...
%         mask;
    %[MB,RGB] = HSLightProbe_MultiSpectralImagetoMBandRGB_400to720(newImg);
end

newImg=newImg./denominator;
end
