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


%% Initialize Camera and Replacement Videos

% Initialize Camera Video
% cam = vision.VideoFileReader('E:\AR (Similarity).mp4', 'VideoOutputDataType', 'uint8');
cam = webcam('HD Webcam');
                          
% Initialize Replacement Video 
video = vision.VideoFileReader('Compass Cloud Mobile Ticketing.mp4', 'VideoOutputDataType', 'uint8');


 %% Video Player
    
    videoPlayer = vision.VideoPlayer;

    
%% Detect and Extract SURF Features from Camera Frame

while ~isDone(video)
    
    % Obtain Camera Frame
    cameraFrame = snapshot(cam);
    cameraFrameGray = rgb2gray(cameraFrame);

    % Detect and Extract Features
    cameraPts = detectSURFFeatures(cameraFrameGray);
    cameraFeatures = extractFeatures(cameraFrameGray, cameraPts);


    %% Try to match reference image and camera frame features

    % Match Extracted Features
    indexPairs = matchFeatures(cameraFeatures, referenceFeatures);

    % Store the SURF points that were matched
    matchedCameraPts    =    cameraPts(indexPairs(:,1));
    matchedReferencePts = referencePts(indexPairs(:,2));

    
    %% Geometric Transformation

    % Get Geometric Transformation between Reference Image and Camera Frame
    [referenceTransform, inlierReferencePts, inlierCameraPts] ...
        = estimateGeometricTransform(matchedReferencePts, matchedCameraPts, 'Similarity');


    %% Resize Video

    % Capture Frame from Video
    videoFrame = step(video);

    % Get replacement and reference dimensions
    refDims = size(compassCardGray);
    vidDims = size(videoFrame(:,:,1));

    % Scale Video Frame to Reference Frame
    scaleImage = imresize(videoFrame, refDims);

    
    %% Transform Image to fit in Scaled Image

    % Apply Geometric Transformation to VIdeo Frame
    outputView = imref2d(size(cameraFrame));
    videoFrameTransformed = imwarp(scaleImage, referenceTransform, 'OutputView', outputView);


    %% Insert transformed replacement video frame into Camera Frame

    % Create object that allows us to blend two Frames
    alphaBlender = vision.AlphaBlender('Operation', 'Binary Mask', 'MaskSource', 'Input Port');

    % Create mask from Warped Image
    mask = videoFrameTransformed(:,:,1)| ...
           videoFrameTransformed(:,:,2)| ...
           videoFrameTransformed(:,:,3) > 0;
    
       
    %% Initialize Point Tracker

    % Create a Point Tracker that allows us to track Reference object
    pointTracker = vision.PointTracker('MaxBidirectionalError', 2);
    initialize(pointTracker, inlierCameraPts.Location, cameraFrame);

    %% Estimate Geometric Transformation between two frames

    % Store previous frame for visual comparison
    prevCameraFrame = cameraFrame;

    % Get next Camera frame
    cameraFrame = snapshot(cam);

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
    
    % Reset point tracker for tracking in next frame
    setPoints(pointTracker, newValidLocations);

    %% Rescale new replacement video frame
    
    videoFrame = step(video);
    scaleImage = imresize(videoFrame, refDims);
    
    outputView = imref2d(size(cameraFrame));
    videoFrameTransformed = imwarp(scaleImage, referenceTransform, 'OutputView', outputView);

    outputFrame = step(alphaBlender, cameraFrame, videoFrameTransformed, mask);
    step(videoPlayer,outputFrame)

end
