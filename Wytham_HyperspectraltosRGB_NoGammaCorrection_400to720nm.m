function sRGB = Wytham_HyperspectraltosRGB_NoGammaCorrection_400to720nm(HSI)

% Size of Input
imagesize = size(HSI);
% Vectorization of HyperSpectralImage
if length(size(HSI)) == 3
    HSI_reshaped = reshape(HSI,imagesize(1)*imagesize(2),imagesize(3));
elseif length(size(HSI)) < 3
    HSI_reshaped = HSI;
end

% Load color matching function CIExyz1931
load Wytham_T_xyz1931

% Spline xyz to make it 400nm to 720 nm by 10 nm step
T_xyz = SplineCmf(S_xyz1931,T_xyz1931,[400,10,33])';

XYZ_reshaped = HSI_reshaped*T_xyz*683*10; % Spctrum to XYZ
sRGB_reshaped = Wytham_XYZToSRGBPrimary(XYZ_reshaped')'; % XYZ to sRGB linera

% Reshape all chromatic coordinates
if length(size(HSI)) == 3
    sRGB = reshape(sRGB_reshaped,imagesize(1),imagesize(2),3);
elseif length(size(HSI)) < 3
    sRGB = sRGB_reshaped;
end

end
