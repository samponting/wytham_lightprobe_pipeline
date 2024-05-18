function [ T ] = Wytham_computeTrans(Lums)
Thresh = 10;
confidence = 0.99;
inlierRatio = 0.3;
epsilon = 1.5;

nImgs = size(Lums,3);

T = zeros(3, 3, nImgs);
T(:, :, 1) = eye(3);
[f2, d2] = Wytham_getSIFTFeatures(Lums(:, :, 1), Thresh);
for i = 2 : nImgs
    f1 = f2;
    d1 = d2;
    [f2, d2] = Wytham_getSIFTFeatures(Lums(:, :, i), Thresh);
    [matches, ~] = Wytham_getMatches(f1, d1, f2, d2);
    [T(:, :, i),~] = Wytham_RANSAC(confidence, inlierRatio, 1, matches, epsilon);
end
end

