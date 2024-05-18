clearvars
close all

% hdr = hdrread('Color.hdr');
% rng(1);
% hdr_v = reshape(hdr,size(hdr,1)*size(hdr,2),size(hdr,3));
% hdr_v_shuffled = hdr_v(randperm(length(hdr_v)),:); 
% hdr_shuffled = reshape(hdr_v_shuffled,size(hdr,1),size(hdr,2),size(hdr,3));
% hdrwrite(hdr_shuffled,'Color_shuffled.hdr');

cd('/home/takuma/Documents/MATLAB/GitHub/hyperspectral_environments/matlab/post_process_takuma')
%for Angle = -20:1:20

imagesize = 1024;

% edge to crop the image
r1 = 255;r2 = 771;
c1 = 256;c2 = 769;

%% Loading ground-truth image
scale= 1;
temp = load('./Wytham_SphereRendering/Angle0_Line1.mat');
GT_sRGB_Line = imresize(temp.sRGB,scale);

temp = load('./Wytham_SphereRendering/Angle0_Line0.mat');
GT_sRGB_NoLine = imresize(temp.sRGB,scale);

temp = load('./Wytham_SphereRendering/Angle0_Line0.mat');
GT_mask = double(imbinarize(sum(temp.sRGB,3)));
GT_mask = imresize(GT_mask,scale);
GT_mask(GT_mask<0.5) = NaN;

GT_sRGB_Line = GT_sRGB_Line.*repmat(GT_mask,1,1,3);
GT_sRGB_NoLine = GT_sRGB_NoLine.*repmat(GT_mask,1,1,3);

% M = sum(GT_sRGB,3);
% GT_sRGB = GT_sRGB./M;
% GT_sRGB(isnan(GT_sRGB))=0;

AngleList = -10:0.5:-0.5;
cnt = 0; 

% Initialise Look-Up-Table
LUT = zeros(size(GT_sRGB_Line,1),size(GT_sRGB_Line,2),2,length(AngleList));

%% Find Look Up Table
for Angle = AngleList
%for Angle = -10
    Angle
    cnt = cnt + 1;
    
    % Load a sphere image with a equator line
    temp = load(['./Wytham_SphereRendering/Angle',erase(num2str(Angle),'.'),'_Line1']);
    sphereLine = temp.sRGB;
    
    % Load a sphere image withuot a equator line
    temp = load(['./Wytham_SphereRendering/Angle',erase(num2str(Angle),'.'),'_Line0']);
    sphereNoLine = temp.sRGB;

    I_Incorrect_NoLine = imresize(sphereNoLine,scale);
    I_Incorrect_NoLine = I_Incorrect_NoLine.*repmat(GT_mask,1,1,3);

    I_Incorrect_Line = imresize(sphereLine,scale);
    I_Incorrect_Line = I_Incorrect_Line.*repmat(GT_mask,1,1,3);
    
    %M = sum(I_Incorrect,3);
    %M(isnan(M))=1;
    %I_Incorrect = I_Incorrect./M;
    %I_Incorrect(isnan(I_Incorrect))=0;

    % Find a map from incorrect angle to correct angle in vectorization
    
    criterion = 10^(-1.8);
    GT_sRGB_v = reshape(GT_sRGB_Line,size(GT_sRGB_Line,1)*size(GT_sRGB_Line,2),3);
    Incorrect_v = reshape(I_Incorrect_Line,size(I_Incorrect_Line,1)*size(I_Incorrect_Line,2),3);
    
    Id_blackexcluded = find(sum(Incorrect_v,2) > 0.2);
    Incorrect_v_blackexcluded = Incorrect_v(Id_blackexcluded,:);
    %Incorrect_v = max(Incorrect_v,0);
    for n = 1:size(GT_sRGB_v,1)
        if mod(n,100000) == 0
            n;
        end
        
        rgb = [GT_sRGB_v(n,1),GT_sRGB_v(n,2),GT_sRGB_v(n,3)]';

        logicid(n,1) = 0;
        
        if sum(rgb) > 0 || sum(isnan(rgb))==0 
            %rgb_v = repmat(rgb,1,size(GT_sRGB_v,1))';
            
            %M = sqrt(rgb(1)-Incorrect_v(:,1)).^2+(rgb(2)-Incorrect_v(:,2)).^2+(rgb(3)-Incorrect_v(:,3)).^2;
            
            M = sqrt((rgb(1)-Incorrect_v_blackexcluded(:,1)).^2+(rgb(2)-Incorrect_v_blackexcluded(:,2)).^2+(rgb(3)-Incorrect_v_blackexcluded(:,3)).^2)/sqrt(3);
            
            %[sortedM,Id] = sort(M);
            
            %Id_blackExcluded = Id(sum(Incorrect_v(Id,:),2) > 0.1);
            %[~,Id_blackExcluded_sorted] = sort(Id(Id_blackExcluded));
            %Id_blackExcluded = Id(find(sortedM > 0.1));
            
            [min_val,idx] = min(M);
            
            %sortedM(Id_blackExcluded_sorted(1))
            list = 1:length(Incorrect_v);
            if min_val < criterion*2
                [row(n,1),col(n,1)] = ind2sub([size(GT_sRGB_NoLine,1),size(GT_sRGB_NoLine,2)],Id_blackexcluded(idx));
                [Pos_row(n,1),Pos_col(n,1)] = ind2sub([size(GT_sRGB_NoLine,1),size(GT_sRGB_NoLine,2)],n);
                logicid(n,1) = 1;
            end
 
        end
    end
    logicid = logical(logicid);
    
    for id = find(logicid)'
        LUT(Pos_row(id),Pos_col(id),:,cnt) = [row(id) col(id)];
    end
   
    % Get line coordinate
    Id_zero = find(sum(GT_sRGB_Line,3) < 0.2);
    
    [Id_zero_r,Id_zero_c] = ind2sub([size(GT_sRGB_Line,1),size(GT_sRGB_Line,2)],Id_zero);
    
    for N = 1:size(Id_zero,1)
        r = Id_zero_r(N);
        c = Id_zero_c(N);
        
        rgb = [GT_sRGB_Line(r,c,1),GT_sRGB_Line(r,c,2),GT_sRGB_Line(r,c,3)]';
        rgb = max(rgb,0);
        
        M = sqrt((rgb(1)-I_Incorrect_Line(:,c,1)).^2+(rgb(2)-I_Incorrect_Line(:,c,2)).^2+(rgb(3)-I_Incorrect_Line(:,c,3)).^2);

        [~,Id_r] = min(M);
        %LUT(r,c,:,cnt) = [Id_r,c];
        LUT(r,c,:,cnt) = [Id_r,c];
    end
    
%     criterion = 10^(-1.8);
%     I_Incorrect = max(I_Incorrect,0);
%     for r = 1:size(GT_sRGB,1)
%         for c = 1:size(GT_sRGB,1)
%         
%             rgb = [GT_sRGB(r,c,1),GT_sRGB(r,c,2),GT_sRGB(r,c,3)]';
% 
%             if sum(rgb)
% 
%                 %M = sqrt(rgb(1)-Incorrect_v(:,1)).^2+(rgb(2)-Incorrect_v(:,2)).^2+(rgb(3)-Incorrect_v(:,3)).^2;
%                 
%                 M = sqrt((rgb(1)-I_Incorrect(:,:,1)).^2+(rgb(2)-I_Incorrect(:,:,2)).^2+(rgb(3)-I_Incorrect(:,:,3)).^2);
%                 [min_val,idx] = min(M(:));
%                 
%                 
%                 
%                 if min_val < criterion
%                     [row(n,1),col(n,1)] = ind2sub([size(GT_sRGB,1),size(GT_sRGB,2)],idx);
%                     [Pos_row(n,1),Pos_col(n,1)] = ind2sub([size(GT_sRGB,1),size(GT_sRGB,2)],n);
%                     logicid(n,1) = 1;
%                 end
% 
%             end
%         end
%     end
%     logicid = logical(logicid);
%     
%     for id = find(logicid)'
%         LUT(Pos_row(id),Pos_col(id),:,cnt) = [row(id) col(id)];
%     end

    %% Evaluation of LUT
    temp = load(['./Wytham_SphereRendering/Angle',erase(num2str(Angle),'.'),'_Line1']);
    I_Incorrect = imresize(temp.sRGB,scale);
    
    % Make compensated image
    I_corrected = ones(size(GT_sRGB_Line));
    for r = 1:size(GT_sRGB_Line,1)
        for c = 1:size(GT_sRGB_Line,2)
            row  = LUT(r,c,1,cnt);col  = LUT(r,c,2,cnt);
            if row && col
                I_corrected(r,c,:) = I_Incorrect(row,col,:);
            end
        end
    end

    I_corrected_masked = I_corrected.*repmat(GT_mask,1,1,3);

    temp = I_corrected_masked;
    for r = 1:size(I_corrected_masked,1)
        for c = 1:size(I_corrected_masked,2)
            if sum(I_corrected_masked(r,c,:)) == 3
                temp(r,c,:) = NaN;
            end
        end
    end
    
%     [I_corrected_masked_filled,TF] = fillmissing(temp,'nearest');
%     
%     
%     center = round(size(I_corrected_masked,1)/2);
%     
%     for r = 1:size(I_corrected_masked,1)
%         for c = 1:size(I_corrected_masked,2)
%             if Angle < 0
%                 if r < size(I_corrected_masked,1)*1/3 && isnan(temp(r,c)) && sqrt((r-center).^2+(c-center)^2) > center*0.8 && r
%                     I_corrected_masked_filled(r,c,:) = [1 1 1];
%                 end
%             elseif Angle > 0
%                 if r > size(I_corrected_masked,1)*2/3 && isnan(temp(r,c)) && sqrt((r-center).^2+(c-center)^2) > center*0.8 && r
%                     I_corrected_masked_filled(r,c,:) = [1 1 1];
%                 end
%             end
%         end
%     end
    
    I = [I_Incorrect,I_corrected_masked,GT_sRGB_Line];
    figure;imshow((I/max(I(:))).^(1/2.4))
    %close all
end

save('LUT_AllAngle_512','LUT','AngleList')    
% 
% temp = load('./Wytham_SphereRendering/Angle0_Line0.mat');
% GT_sRGB = real(temp.sRGB);
% cnt = 0;
% for Angle = AngleList
%     cnt = cnt + 1;
%     GT_mask = imbinarize(sum(GT_sRGB,3));
% 
%     % Load a sphere image with a equator line
%     temp = load(['./Wytham_SphereRendering/Angle',erase(num2str(Angle),'.'),'_Line1']);
%     I_Incorrect = real(temp.sRGB);
%     
%     % Make compensated image
%     I_corrected = ones(size(GT_sRGB));
%     for r = 1:size(GT_sRGB,1)
%         for c = 1:size(GT_sRGB,2)
%             row  = LUT(r,c,1,cnt);col  = LUT(r,c,2,cnt);
%             if row && col
%                 I_corrected(r,c,:) = I_Incorrect(row,col,:);
%             end
%         end
%     end
% 
%     I_corrected_masked = I_corrected.*repmat(GT_mask,1,1,3);
% 
%     temp = I_corrected_masked;
%     for r = 1:size(I_corrected_masked,1)
%         for c = 1:size(I_corrected_masked,2)
%             if sum(I_corrected_masked(r,c,:)) == 3
%                 temp(r,c,:) = NaN;
%             end
%         end
%     end
%     
%     [I_corrected_masked_filled,TF] = fillmissing(temp,'nearest');
%     
%     center = round(size(I_corrected_masked,1)/2);
%     
%     for r = 1:size(I_corrected_masked,1)
%         for c = 1:size(I_corrected_masked,2)
%             if Angle < 0
%                 if r < size(I_corrected_masked,1)*1/3 && isnan(temp(r,c)) && sqrt((r-center).^2+(c-center)^2) > center*0.8 && r
%                     I_corrected_masked_filled(r,c,:) = [1 1 1];
%                 end
%             elseif Angle > 0
%                 if r > size(I_corrected_masked,1)*2/3 && isnan(temp(r,c)) && sqrt((r-center).^2+(c-center)^2) > center*0.8 && r
%                     I_corrected_masked_filled(r,c,:) = [1 1 1];
%                 end
%             end
%         end
%     end
%     
%     I = [I_Incorrect,I_corrected_masked,I_corrected_masked_filled,GT_sRGB];
%     figure;imshow(I/max(I(:)))
% end