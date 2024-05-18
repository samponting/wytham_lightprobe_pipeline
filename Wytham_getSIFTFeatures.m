function [f, d] = HSLightProbe_getSIFTFeatures(Lum, edgeThresh)
Im = single(squeeze(Lum));
% get features and descriptors
[f, d] = vl_sift(Im, 'EdgeThresh', edgeThresh);
end