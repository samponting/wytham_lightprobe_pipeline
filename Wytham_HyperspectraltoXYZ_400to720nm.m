function XYZ = Wytham_HyperspectraltoXYZ_400to720nm(HSI)

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

% Reshape all Chromatic Coordinates
if length(size(HSI)) == 3
    XYZ = reshape(XYZ_reshaped,imagesize(1),imagesize(2),3);
elseif length(size(HSI)) < 3
    XYZ = XYZ_reshaped;
end

XYZ(isnan(XYZ))=0;
end
