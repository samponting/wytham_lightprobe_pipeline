function Iout = Wytham_ShiftImage(I,Offset)

% Function to shift image horizontally

width = size(I,2);

Iout = zeros(size(I));

if Offset ~= 0
for w = 1:width
    if Offset ~= 0
        w_shifted = w - Offset;
        if w_shifted <= 0
            w_shifted = w_shifted + width;
        elseif w_shifted > width
            w_shifted = w_shifted - width;
            if w_shifted > width
                w_shifted = w_shifted - width;
            end
        end
    end
    Iout(:,w_shifted,:) = I(:,w,:);    
end
else
    Iout = I;
end
end