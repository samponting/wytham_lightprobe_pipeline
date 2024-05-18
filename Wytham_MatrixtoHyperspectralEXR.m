function Wytham_MatrixtoHyperspectralEXR(filename,img,channels)

for c=1:length(channels)
    cellimg{c} = img(:,:,c);
end

exrwritechannels(filename, 'none', 'single', channels, cellimg);