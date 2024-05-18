function [imsphere, pixel_diameter, imsphere_dr, imsphere_cal] = Wytham_extract_sphere(HSI_raw, HSI_dr, HSI_cal, gain, sensitivity)

close all
% HSI_dr and HSI_cal are optional.  If passed in, they too will be masked,
% cropped, and returned.  This is useful if you want to DR correct and
% calibrate the sphere-extracted image

% turn the hyperspectral image into an RGB
    imrgb(:,:,1) = HSI_raw(:,:,70);
    imrgb(:,:,2) = HSI_raw(:,:,53);
    imrgb(:,:,3) = HSI_raw(:,:,19);
    imrgb = double(imrgb);
    
% Find round objects - from https://uk.mathworks.com/help/images/identifying-round-objects.html
    % convert RGB to b&w
        %gain = 5000;  % set high gain (i.e. make it darker) to bring out the perimeter of the sphere.  Set gain=600 for just looking.                
        imggrey = rgb2gray(imrgb/max(imrgb(:))*gain);
        imgbw = imbinarize(imggrey);
        imshow(imgbw)
        
    % remove small objects <1000 pixels
        imgbw = bwareaopen(imgbw,2000);
        imgbw = bwareaopen(imcomplement(imgbw),2000);
        % imshow(imgbw);
        % hold on

    % find circles in the image, hopefully just the sphere.  See https://uk.mathworks.com/help/images/detect-and-measure-circular-objects-in-an-image.html
        %[centers, radii, metric] = imfindcircles(imgbw, [50,200], 'Sensitivity',sensitivity,'Method','twostage');
        [centers, radii, metric] = imfindcircles(imgbw, [115,200], 'Sensitivity',sensitivity,'Method','twostage');

        % viscircles(centers,radii);
        
        % TODO - quality check of circle here, loop back and change sensitivity with a dialog until we get it right.
        first_center = centers(1,:);
        centerX = first_center(1,1);
        centerY = first_center(1,2);
        
% turn the circle into a mask - see https://matlab.fandom.com/wiki/FAQ#How_do_I_create_a_circle.3F
    circ = drawcircle('Center', first_center, 'Radius', radii(1));
    spheremask = createMask(circ, imgbw);
    
    % h = imshow(spheremask);
    % set(h, 'AlphaData', 0.5);
    % hold off
    
    % mask greyscale image
        imgmasked = imggrey;
        imgmasked(~spheremask) = 0;
        %imshow(imgmasked);
    % mask hyperspectral image
        maskedraw = maskout(HSI_raw, spheremask);
        
% Crop image to edges of ball
    ymin = min(find(any(spheremask, 1)));
    ymax = max(find(any(spheremask, 1)));
    xmin = min(find(any(spheremask, 2)));
    xmax = max(find(any(spheremask, 2)));
    maskedraw = maskedraw(xmin:xmax, ymin:ymax, :); 
    % band34 = squeeze(maskedraw(:,:,34));
    % imagesc(band34);

imsphere = maskedraw;
pixel_diameter = ymax - ymin + 1;

% if a dark reference image was passed in, mask it too
if exist('HSI_dr','var')
    maskeddr = maskout(HSI_dr, spheremask);
    maskeddr = maskeddr(xmin:xmax, ymin:ymax, :); 
    imsphere_dr = maskeddr;
end

% if a calibration image was passed in, mask it too
if exist('HSI_cal','var')
    maskedcal = maskout(HSI_cal, spheremask);
    maskedcal = maskedcal(xmin:xmax, ymin:ymax, :); 
    imsphere_cal = maskedcal;
end

end