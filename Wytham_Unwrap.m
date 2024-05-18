function HSIOut_filled = Wytham_Unwrap(HSIIn,s,d)

% This code was written based on the python code in the link below
% https://github.com/elerac/ProbePanorma-Converter

% Horizontal FOV should be defined in radian
% Reference: https://wiki.panotools.org/ChristmasBallPanoTutor
HFOV = 2*pi - asin(d/(2*s));

width_probe = size(HSIIn,2);
height_probe = size(HSIIn,1);

width_panorama = round(width_probe*2*(HFOV/(2*pi)));
height_panorama = height_probe;

HSIOut = zeros(height_panorama,width_panorama,size(HSIIn,3));

% Lost horizontal FOV in pixel
lostFOV_pixel = width_probe*2 - width_panorama;

if mod(lostFOV_pixel,2)
    % if lostFOV_pixel is odd, we add ceil(loss/2) to left edge and floor (lostFOV_pixel/2) to right edge
    % to make the aspect ratio of final output 2:1.
    leftedge = ceil(lostFOV_pixel/2);
    rightedge = floor(lostFOV_pixel/2);
else
    leftedge = lostFOV_pixel/2;
    rightedge = lostFOV_pixel/2;  
end

% Converting 
for col = 1:height_panorama
    for row = 1:width_panorama
        u = row/(width_panorama-1)*2; %0~2
        v = col/(height_panorama-1); %0~1
        theta = pi * (u-1);
        phi = pi * v;
        
        Dx = sin(phi) * sin(theta);
        Dy = cos(phi);
        Dz = -sin(phi) * cos(theta);
        
        D = [Dx, Dy, Dz]; %Light source vector
        V = [0, 0, -1]; %Line of sight vector
        n = (D+V)/norm(D+V); %Normal vector
        s = n(1); %-1~1
        t = -n(2); %-1~1
        x = round((s+1)*0.5*(width_probe-1)+1);
        y = round((t+1)*0.5*(height_probe-1)+1);
        %T(col,row,:) = [x,y];
        HSIOut(col,row,:) = HSIIn(y,x,:);
    end
end

HSIOut_filled = zeros(height_probe,width_probe*2,size(HSIIn,3));
HSIOut_filled(:,leftedge+1:end-rightedge,:) = HSIOut;
end