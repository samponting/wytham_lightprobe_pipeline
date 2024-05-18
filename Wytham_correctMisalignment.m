function HSI_out = Wytham_correctMisalignment(HSI,angle)
    
    load LUT_AllAngle_512
    LUT_AllAngle = LUT;
    
    AngleList = -10:0.5:0.5;
    
    Id = find(AngleList==angle);
    
    LUT = imresize(LUT_AllAngle(:,:,:,Id),[size(HSI,1),size(HSI,2)]);
    LUT = max(LUT,0);
    LUT = round(LUT/size(LUT_AllAngle,1)*size(HSI,1));
    LUT(LUT==0) = 1;
    LUT = min(LUT,size(HSI,1));
     
    % Make compensated image
    HSI_out = zeros(size(HSI));
    for r = 1:size(LUT,1)
        for c = 1:size(LUT,2)
            row  = LUT(r,c,1);col  = LUT(r,c,2);
            if row && col
                HSI_out(r,c,:) = HSI(row,col,:);
            end
        end
    end
end