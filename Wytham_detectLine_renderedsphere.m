clearvars;close all;clc % clean up

% Make sure that all files are on Matlab path
for Angle = -10:0.5:0
    load(['Angle',erase(num2str(Angle),'.'),'_Line0']);NoLine = sum(real(sRGB),3);
    load(['Angle',erase(num2str(Angle),'.'),'_Line1']);Line = sum(real(sRGB),3);
    
    center = size(Line,1)/2;
    binaryLine = Line < 0.3;
    
    for row = 1:size(binaryLine,1)
        for col = 1:size(binaryLine,2)
            d = sqrt((row-center)^2+(col-center)^2);
            if d > center*0.98
                binaryLine(row,col) = 0;
            end
        end
    end
    
    imagesc(binaryLine)
    pause(1)
    clear LinePos
    
    for col = 1:size(binaryLine,2)
        LinePos(col) = median(find(binaryLine(:,col)));
    end
    
    imsize = size(binaryLine,1);
    
    save(fullfile('Wytham_SphereRendering',['RenderedSphere_Line_Angle',erase(num2str(Angle),'.')]),'LinePos','imsize')    
end