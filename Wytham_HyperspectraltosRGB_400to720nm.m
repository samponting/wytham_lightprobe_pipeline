function [sRGB,scale] = Wytham_HyperspectraltosRGB_400to720nm(HSI)

% Size of Input
imagesize = size(HSI);
% Vectorization of HyperSpectralImage
if length(size(HSI)) == 3
    HSI_reshaped = reshape(HSI,imagesize(1)*imagesize(2),imagesize(3));
elseif length(size(HSI)) < 3
    HSI_reshaped = HSI;
end

% Load Color Matching Function
load('Wytham_T_xyz1931');

% Spline xyz to make it 400nm to 720 nm by 10 nm step
T_xyz = SplineCmf(S_xyz1931,T_xyz1931,[400,10,33])';

XYZ_reshaped = HSI_reshaped*T_xyz*683*10; % Spctrum to XYZ
sRGB_reshaped = Wytham_XYZToSRGBPrimary(XYZ_reshaped')'; % XYZ to sRGB linera
scale = max(max(sRGB_reshaped));

sRGB_reshaped = max((sRGB_reshaped/max(max(sRGB_reshaped))),0);

% Non-linear correction separately for dark colours(<0.003138) and bright
% colours
dark = 0.0031308;
Dark_R = find(sRGB_reshaped(:,1)<=dark);Bright_R = find(sRGB_reshaped(:,1)>dark);
Dark_G = find(sRGB_reshaped(:,2)<=dark);Bright_G = find(sRGB_reshaped(:,2)>dark);
Dark_B = find(sRGB_reshaped(:,3)<=dark);Bright_B = find(sRGB_reshaped(:,3)>dark);

sRGB_reshaped(Dark_R,1) = sRGB_reshaped(Dark_R,1)*12.92;
sRGB_reshaped(Dark_G,2) = sRGB_reshaped(Dark_G,2)*12.92;
sRGB_reshaped(Dark_B,3) = sRGB_reshaped(Dark_B,3)*12.92;

sRGB_reshaped(Bright_R,1) = 1.055*sRGB_reshaped(Bright_R,1).^(1/2.4)-0.055;
sRGB_reshaped(Bright_G,2) = 1.055*sRGB_reshaped(Bright_G,2).^(1/2.4)-0.055;
sRGB_reshaped(Bright_B,3) = 1.055*sRGB_reshaped(Bright_B,3).^(1/2.4)-0.055;

% Reshape all Chromatic Coordinates
if length(size(HSI)) == 3
    sRGB = reshape(sRGB_reshaped,imagesize(1),imagesize(2),3);
elseif length(size(HSI)) < 3
    sRGB = sRGB_reshaped;
end

sRGB(isnan(sRGB))=0;
end
