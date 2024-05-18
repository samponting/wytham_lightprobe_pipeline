function [matcheSphere_sRGB,matchedAngle] = Wytham_getMisalignmentAngle(filename,imsize_measured)
    AngleList = -10:0.5:0;
    cnt = 0;
    clear LinePos_renderedSphere
    for Angle = AngleList
        cnt = cnt + 1;
        load(['RenderedSphere_Line_Angle',erase(num2str(Angle),'.')])
        LinePos_renderedSphere(:,cnt) = LinePos;
    end
    
    load(['Equator_',filename]);
    LinePos_measured = LinePosition;
    
    LinePos_renderedSphere = LinePos_renderedSphere/size(LinePos_renderedSphere,1)*imsize_measured;
    
    Id = round(LinePos_measured(:,1)/imsize_measured*size(LinePos_renderedSphere,1));    
    Id(Id<1) = 1;
    Id(Id>size(LinePos_renderedSphere,1)) = size(LinePos_renderedSphere,1);
    Pos = LinePos_renderedSphere(floor(Id),:);
    Pos(isnan(Pos)) = round(imsize_measured/2);
    
    for n = 1:size(Pos,2)
        coeff(n) = corr2(Pos(:,n),LinePos_measured(:,2));
    end
    [~,maxId] = max(coeff);
    
    matchedAngle = AngleList(maxId);
    load(['Angle',erase(num2str(matchedAngle),'.'),'_Line1']);matcheSphere_sRGB = real(sRGB);
end