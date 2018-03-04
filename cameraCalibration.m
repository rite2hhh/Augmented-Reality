% Auto-generated by cameraCalibrator app on 02-Nov-2017
%-------------------------------------------------------


% Define images to process
imageFileNames = {'C:\Users\Chinmay\Google Drive\MS\Fall 2017\EE657\Project\Calibration Images\Image1.png',...
    'C:\Users\Chinmay\Google Drive\MS\Fall 2017\EE657\Project\Calibration Images\Image2.png',...
    'C:\Users\Chinmay\Google Drive\MS\Fall 2017\EE657\Project\Calibration Images\Image3.png',...
    'C:\Users\Chinmay\Google Drive\MS\Fall 2017\EE657\Project\Calibration Images\Image4.png',...
    'C:\Users\Chinmay\Google Drive\MS\Fall 2017\EE657\Project\Calibration Images\Image5.png',...
    'C:\Users\Chinmay\Google Drive\MS\Fall 2017\EE657\Project\Calibration Images\Image6.png',...
    'C:\Users\Chinmay\Google Drive\MS\Fall 2017\EE657\Project\Calibration Images\Image7.png',...
    'C:\Users\Chinmay\Google Drive\MS\Fall 2017\EE657\Project\Calibration Images\Image9.png',...
    'C:\Users\Chinmay\Google Drive\MS\Fall 2017\EE657\Project\Calibration Images\Image11.png',...
    'C:\Users\Chinmay\Google Drive\MS\Fall 2017\EE657\Project\Calibration Images\Image12.png',...
    'C:\Users\Chinmay\Google Drive\MS\Fall 2017\EE657\Project\Calibration Images\Image13.png',...
    'C:\Users\Chinmay\Google Drive\MS\Fall 2017\EE657\Project\Calibration Images\Image14.png',...
    'C:\Users\Chinmay\Google Drive\MS\Fall 2017\EE657\Project\Calibration Images\Image15.png',...
    'C:\Users\Chinmay\Google Drive\MS\Fall 2017\EE657\Project\Calibration Images\Image16.png',...
    'C:\Users\Chinmay\Google Drive\MS\Fall 2017\EE657\Project\Calibration Images\Image17.png',...
    'C:\Users\Chinmay\Google Drive\MS\Fall 2017\EE657\Project\Calibration Images\Image18.png',...
    'C:\Users\Chinmay\Google Drive\MS\Fall 2017\EE657\Project\Calibration Images\Image19.png',...
    'C:\Users\Chinmay\Google Drive\MS\Fall 2017\EE657\Project\Calibration Images\Image20.png',...
    };

% Detect checkerboards in images
[imagePoints, boardSize, imagesUsed] = detectCheckerboardPoints(imageFileNames);
imageFileNames = imageFileNames(imagesUsed);

% Generate world coordinates of the corners of the squares
squareSize = 25;  % in units of 'mm'
worldPoints = generateCheckerboardPoints(boardSize, squareSize);

% Calibrate the camera
[cameraParams, imagesUsed, estimationErrors] = estimateCameraParameters(imagePoints, worldPoints, ...
    'EstimateSkew', false, 'EstimateTangentialDistortion', false, ...
    'NumRadialDistortionCoefficients', 2, 'WorldUnits', 'mm', ...
    'InitialIntrinsicMatrix', [], 'InitialRadialDistortion', []);

% View reprojection errors
h1=figure; showReprojectionErrors(cameraParams, 'PatternCentric');

% Visualize pattern locations
h2=figure; showExtrinsics(cameraParams, 'CameraCentric');

% Display parameter estimation errors
displayErrors(estimationErrors, cameraParams);

% For example, you can use the calibration data to remove effects of lens distortion.
originalImage = imread(imageFileNames{1});
undistortedImage = undistortImage(originalImage, cameraParams);

% See additional examples of how to use the calibration data.  At the prompt type:
% showdemo('MeasuringPlanarObjectsExample')
% showdemo('StructureFromMotionExample')
