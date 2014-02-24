function Polar(Subj, Direc,saveVideo, Emul)
%Polar(Subj, Direc)
%
% Polar mapping
%
% Duration video 4min 0sec (8 cycles of 30sec each)


addpath('Common_Functions');
if nargin==0
    Subj='Demo';
    Direc='+';
    Emul=1;
    saveVideo=0;
elseif nargin==1
    Direc='+';
    Emul=0;
    saveVideo=0;
elseif nargin==2
    Emul=0;
    saveVideo=0;
end

%% Engine parameters
if length(Screen('Screens'))>1
    message = 'Screen number: ';
    Parameters.Screen= input(message);
    Parameters.Resolution=[0 0 2560 1600];
else
    Parameters.Screen=0;    % Main screen
    Parameters.Resolution=[0 0 1280 800];%[0 0 1440 900];   % Resolution
end
Parameters.Foreground=[0 0 0];  % Foreground colour
Parameters.Background=[127 127 127];    % Background colour
Parameters.FontSize = 15;   % Size of font
Parameters.FontName = 'Helvetica';  % Font to use

%% Scanner parameters
Parameters.TR=3;    % Seconds per volume
Parameters.Number_of_Slices=30; % Number of slices
Parameters.Dummies=4;   % Dummy volumes
Parameters.Overrun=0;   % Dummy volumes at end

%% Experiment parameters
Parameters.Cycles_per_Expmt=8;  %8 Stimulus cycles per run
Parameters.Vols_per_Cycle=10;   % Volumes per cycle 
Parameters.Prob_of_Event=0.05;  % Probability of a jerk event
Parameters.Event_Duration=0.2;  % Duration of a jerk event
Parameters.Event_Size=2.5;  % Size of jerk event in degrees
Parameters.Apperture='Wedge';   % Stimulus type
Parameters.Apperture_Width=40;  % Width of wedge in degrees
Parameters.Direction=Direc; % Direction of cycling
Parameters.Rotate_Stimulus=true;    % Does image rotate?
% Conventional checkerboard
load('Checkerboard');
Parameters.Stimulus(:,:,1)=Checkerboard;
Parameters.Stimulus(:,:,2)=InvertContrast(Checkerboard);
Parameters.Refreshs_per_Stim=8;

%% Various parameters
Parameters.Instruction='Welcome!\n\nPress button when there is a jump!';
[Parameters.Session Parameters.Session_name]=CurrentSession([Subj '_Polar' Direc]); % Determine current session

%% Run the experiment
Retinotopic_Mapping(Parameters, Emul,saveVideo);
