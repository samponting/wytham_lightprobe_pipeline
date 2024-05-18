function newHSI = Wytham_Create(Lums,HSI,full360)
if full360
    Lums(:,:,end+1) = Lums(:,:,1);
    HSI(:,:,:,end+1) = HSI(:,:,:,1);
end
nImgs = size(Lums,3);
%Lums = zeros(size(Lums), 'like', Lums);
%f = 9000;
f = 9000;
for i = 1 : nImgs
    cylindricalLums(:,:,i) = HSLightProbe_Warp(Lums(:,:,i), f);
end

translations = HSLightProbe_computeTrans(cylindricalLums);

absoluteTrans = zeros(size(translations));
absoluteTrans(:, :, 1) = translations(:, :, 1);
for i = 2 : nImgs
    absoluteTrans(:, :, i) = absoluteTrans(:, :, i - 1) * translations(:, :, i);
end

% end to end adjustment
width = size(cylindricalLums, 2);
height = size(cylindricalLums, 1);
if full360
    panorama_w = abs(round(absoluteTrans(2, 3, end))) + width;
    % \delta x / \delta y
    driftSlope = absoluteTrans(1, 3, end) / absoluteTrans(2, 3, end);
    
    panorama_h = height;
    % y shift is negative
    if absoluteTrans(2, 3, end) < 0
        absoluteTrans(2, 3, :) = absoluteTrans(2, 3, :) - absoluteTrans(2, 3, end);
        absoluteTrans(1, 3, :) = absoluteTrans(1, 3, :) - absoluteTrans(1, 3, end);
    end
    driftMatrix = [1 -driftSlope driftSlope; 0 1 0; 0 0 1];
    for i = 1 : nImgs
        absoluteTrans(:, :, i) = driftMatrix * absoluteTrans(:, :, i);
    end
else
    maxY = height;
    minY = 1;
    minX = 1;
    maxX=width;
    for i = 2 : nImgs 
        maxY = max(maxY, absoluteTrans(1,3,i)+height);
        maxX = max(maxX, absoluteTrans(2,3,i)+width);
        minY = min(minY, absoluteTrans(1,3,i));
        minX=min(minX,absoluteTrans(2,3,i));
    end
    panorama_h = ceil(maxY)-floor(minY) + 1;
    panorama_w = ceil(maxX)-floor(minX) +1;
    
    absoluteTrans(2, 3, :) = absoluteTrans(2, 3, :) - floor(minX);
    absoluteTrans(1, 3, :) = absoluteTrans(1, 3, :) - floor(minY);
end

newHSI = HSLightProbe_Merge(cylindricalLums,HSI,absoluteTrans,panorama_h,panorama_w,f);
end

