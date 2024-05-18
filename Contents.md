Description image processing pipelines

Image processing progress sheet
https://docs.google.com/spreadsheets/d/1Dfk-yL6khwGE9yLNEAJXdQ2hirSSSgbPYUeCk9CBd5o/edit#gid=0

Make sure to install all dependencies below on your system.
(i) Psychotoolbox3
(ii) exrwritechannels (https://github.com/skycaptain/openexr-matlab/blob/master/exrwritechannels.m) to write openexr image.
(iii) vlfeat (https://www.vlfeat.org/download.html) for stitching images based on SIFT

Before starting the image processing, download all raw data files from our shared One drive folder (My files -> Projects -> Wytham Woods Spectral Environment Project -> 03_data -> 001_hyperspectral_light_field -> upload).
Name the folder something like "Wytham_Dataset" and put all folders there.

Main codes
(1) Wytham_saveSphereImages.m
This is a function to save raw SPECIM files, crop the region of the sphere, apply the spectral calibration to image and save the sphere images and mask for saturated pixels.

# TM 16th Dec 2021: We still need to detect lines for spheres measured in October and November 2021
(2) Wytham_detectLine_measuredsphere.m
This code is to find a equator line from a measured sphere by manual click.

(3) Wytham_processSphereImages.m
This code applies various process to sphere images including correction of specular reflectance, removal of saturated pixels, correction of camera misalignment, promotion to high dynamic range images, masking imaging system, correction of intensity compression and unwrapping.

# TM 16th Dec 2021: We need to improve this code to remove tripods from unwrapped 
(4) Wytham_fillinTripod.m
To remove a sphere from the processed unwrapped images genenrated from (2).

(5) Wytham_stitchProcessedImages.m
This stitches unwrapped images where tripods are filled in.

Other codes (this is under construction)
(1) Wytham_detectLine_renderedsphere.m
This code detects a equator line from a rendered sphere, and stores y-coordinates of the equator line from 0 degree to -10 degree with every -0.5 step.
No need to run this code because all outputs from this code is already uploaded to git, a folder 'Wytham_renderedSphereAndEquators'