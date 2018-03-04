%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Run README in MATLAB to invoke entire Project
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Run this to show steps of how Object Recognition and Tracking is performed

main;

%% Run this to Create a Video Player for your AR Application

liveAR;

%% Run this to create a video clip after providing required files

% function(Reference Image Path, Source Video Path, Replacement Video Path, Output Filename (AVI only))
generateVideo('compassCard.png', 'E:\AR (Similarity).mp4', 'Compass Cloud Mobile Ticketing.mp4', 'Output.avi')