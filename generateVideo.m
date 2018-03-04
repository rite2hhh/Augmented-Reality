function generateVideo(refImg, srcVid, repVid, opVid)
    %% Progress bar for user feedback
    h = waitbar(0,'Please wait...');


    %% Load Reference Image, Detect Features

    % Read Reference Image
    compassCard = imread(refImg);
    compassCardGray = rgb2gray(compassCard);

    % Detect and extract SURF features
    referencePts = detectSURFFeatures(compassCardGray);
    referenceFeatures = extractFeatures(compassCardGray, referencePts);


    %% Initialize Camera and Replacement Videos

    % Initialize Camera Video
    cam = vision.VideoFileReader(srcVid, 'VideoOutputDataType', 'uint8');

    % Initialize Replacement Video 
    video = vision.VideoFileReader(repVid, 'VideoOutputDataType', 'uint8');

    % Initialize Video Writer object
    v = VideoWriter(opVid);
    open(v)
    
    videoPlayer = vision.VideoPlayer;
    %% Detect and Extract SURF Features from Camera Frame

    for i = 1:498

        % Obtain Camera Frame
        cameraFrame = step(cam);
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

        % Superimpose Warped Video on Camera Frame
        outputFrame = step(alphaBlender, cameraFrame, videoFrameTransformed, mask);

        % Write Frame to Output Video
        %writeVideo(v, outputFrame);
        step(videoPlayer,outputFrame)
        
        % Increment Progress bar
        waitbar(i / 498)
    end

    close(h);
    close(v);
end