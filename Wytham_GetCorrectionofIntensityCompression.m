function w = Wytham_GetCorrectionofIntensityCompression(pixel,sphere_radius_cm,distance_camera_sphere_cm)
% pixel : sphere radius in pixel space

% sphere_radius_cm: sphere radius in cm

% distance_camera_sphere_cm: distance between camera and sphere in cm

imagecenter = [round(pixel) round(pixel)];
for r = 1:pixel*2
    for c = 1:pixel*2
        d = sqrt((r-imagecenter(1))^2+(c-imagecenter(2))^2);
        theta = asin(d/pixel);
        w_pre(r,c) = (sphere_radius_cm/(2*distance_camera_sphere_cm))*(cos(theta));
    end    
end

w = real(w_pre)/max(real(w_pre(:)));
end