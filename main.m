clc
clear
close all
warning('off', 'all')

%% Load Reference Image, Detect Features

% Read Reference Image
compassCard = imread('compassCard.png');
compassCardGray = rgb2gray(compassCard);

% Detect and extract SURF features
referencePts = detectSURFFeatures(compassCardGray);
referenceFeatures = extractFeatures(compassCardGray, referencePts);

% Display SURF features for reference image
figure Name 'Image Recognition'
subplot(2,1,1);
imshow(compassCard);
hold on; 
plot(referencePts.selectStrongest(50));
title('Reference Image with Detected Features (Superimposed)');
legend('Point Detectors', 'Feature Descriptors', 'location', 'southwest');


%% Initialize Camera and Replacement Videos

% Initialize Camera Video
cam = vision.VideoFileReader('E:\AR (Similarity).mp4', 'VideoOutputDataType', 'uint8');
                          
% Initialize Replacement Video
video = vision.VideoFileReader('Compass Cloud Mobile Ticketing.mp4', 'VideoOutputDataType', 'uint8');

                            
%% Detect and Extract SURF Features from Camera Frame

% Obtain Camera Frame
cameraFrame = step(cam);
cameraFrameGray = rgb2gray(cameraFrame);

% Detect and Extract Features
cameraPts = detectSURFFeatures(cameraFrameGray);
cameraFeatures = extractFeatures(cameraFrameGray, cameraPts);

% Display Camera Frame along with Detected Features
subplot(2,1,2);
imshow(cameraFrame);
hold on; 
plot(cameraPts.selectStrongest(50));
title('Camera Frame with Detected Features (Superimposed)');
legend('Point Detectors', 'Feature Descriptors');


%% Try to match reference image and camera frame features

% Match Extracted Features
indexPairs = matchFeatures(cameraFeatures, referenceFeatures);

% Store the SURF points that were matched
matchedCameraPts    =    cameraPts(indexPairs(:,1));
matchedReferencePts = referencePts(indexPairs(:,2));

% Display Matched Features in juxtaposition
figure Name 'Matched Points'
subplot(2,1,1);
showMatchedFeatures(cameraFrame, compassCard, matchedCameraPts, matchedReferencePts, 'Montage');
title('Matched Points between Reference Image and Camera Frame');
legend('Matched Points 1', 'Matched Points 2');


%% Geometric Transformation

% Get Geometric Transformation between Reference Image and Camera Frame
[referenceTransform, inlierReferencePts, inlierCameraPts] ...
    = estimateGeometricTransform(matchedReferencePts, matchedCameraPts, 'Similarity');

% Plot inliers of estimated geometric transform
subplot(2,1,2);
showMatchedFeatures(cameraFrame, compassCard, inlierCameraPts, inlierReferencePts , 'Montage');
title ('Inlier Matched Points between Reference Image and Camera Frame');
legend('Inlier Matched Points 1', 'Inlier Matched Points 2');


%% Resize Video

% Capture Frame from Video
videoFrame = step(video);

% Get replacement and reference dimensions
refDims = size(compassCardGray);
vidDims = size(videoFrame(:,:,1));

% Scale Video Frame to Reference Frame
scaleImage = imresize(videoFrame, refDims);

% Display Scaled Video Frame and Reference Frame in juxtaposition
figure Name 'Resized Video'
imshowpair(compassCard, scaleImage, 'Montage');
title('Video frame scaled to fit the dimensions of the Card');


%% Transform Image to fit in Scaled Image

% Apply Geometric Transformation to Video Frame
outputView = imref2d(size(cameraFrame));
videoFrameTransformed = imwarp(scaleImage, referenceTransform, 'OutputView', outputView);

% Display Warped Image and Camera Frame in juxtaposition
figure Name 'Scaled Video Frame'
imshowpair(cameraFrame, videoFrameTransformed, 'Montage');
title('Geometric Transform applied to Video Frame to position in the Camera Frame');


%% Insert transformed replacement video frame into Camera Frame

% Create object that allows us to blend two Frames
alphaBlender = vision.AlphaBlender('Operation', 'Binary Mask', 'MaskSource', 'Input Port');

% Create mask from Warped Image
mask = videoFrameTransformed(:,:,1)| ...
       videoFrameTransformed(:,:,2)| ...
       videoFrameTransformed(:,:,3) > 0;

% Superimpose Warped Video on Camera Frame
outputFrame = step(alphaBlender, cameraFrame, videoFrameTransformed, mask);

% Display the Composite Image
figure Name 'Composite Image'
imshow(outputFrame);
title('Composite Image - Video frame Superimposed on the card in the Camera Frame');


%% Initialize Point Tracker

% Create a Point Tracker that allows us to track Reference object
pointTracker = vision.PointTracker('MaxBidirectionalError', 2);
initialize(pointTracker, inlierCameraPts.Location, cameraFrame);

% Place Tracking Markers on Reference object
trackingMarkers = insertMarker(cameraFrame, inlierCameraPts.Location, 'Size', 15, 'Color', 'Blue');

% Display Tracked Points in Consecutive Frames in juxtaposition
figure Name 'Object Tracking'
imshow(trackingMarkers);
title('Image with Tracking Markers (Superimposed)')
legend('Tracking Markers')


%% Estimate Geometric Transformation between two frames

% Store previous frame for visual comparison
prevCameraFrame = cameraFrame;

% Get next Camera frame
cameraFrame = step(cam);

% Find newly tracked points
[trackedPoints, isValid] = step (pointTracker, cameraFrame);

% Use reliably tracked locations only
newValidLocations =            trackedPoints(isValid,:);
oldValidLocations = inlierCameraPts.Location(isValid,:);

% Get new Geometric Transformation if Tracked Points are vaild
if (nnz(isValid) >= 2)
    [trackingTransform, oldInlierLocations, newInlierLocations] = ...
        estimateGeometricTransform(oldValidLocations, newValidLocations, 'Similarity');
end

% Display Tracked Points in Consecutive Frames
figure Name 'Tracking Points'
showMatchedFeatures(prevCameraFrame, cameraFrame, oldInlierLocations, newInlierLocations, 'Montage');
title ('Tracked Points between Previous Frame and Current Frame');
legend('Previous Frame Interest Points', 'Current Frame Interest Points', 'Tracked Points');

% Reset point tracker for tracking in next frame
setPoints(pointTracker, newValidLocations);
