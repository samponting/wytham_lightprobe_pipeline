function srgb_out = Wytham_HSIToSRGBGammaCorrected(HSI,wls)

size_HSI = size(HSI);
if length(size_HSI) == 3
    HSI = reshape(HSI,size(HSI,1)*size(HSI,2),size(HSI,3));
end

load('Wytham_T_xyz1931')
T_xyz1931_Splined = SplineCmf(S_xyz1931,T_xyz1931,wls);
XYZ = 683*T_xyz1931_Splined*HSI'*10;

% Define the transformation matrix.  Now matching what's at w3.org.  The
% old matrix is commented out in the second line.
M = [3.2410 -1.5374 -0.4986 ; -0.9692 1.8760 0.0416 ; 0.0556 -0.2040 1.0570];

% Do the transform
if (~isempty(XYZ))
    rgb = M*XYZ;
else
    rgb = [];
end

rgb = max(rgb/max(rgb(:)),0);

srgb = SRGBGammaCorrect(rgb,1)';

if length(size_HSI) == 3
    srgb_out = reshape(srgb,size_HSI(1),size_HSI(2),3);
end