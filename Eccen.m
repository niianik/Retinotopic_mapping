function Eccen(Subj, Direc, saveVideo, Emul)
% Eccen('bd','+', 0, 0): subj BD, expanding rings, don't save Video, use
% scanner mode (don't wait for response).
% Eccen(Subj, Direc)
%
% Eccentricity mapping
%
% Duration video 4min 0sec (8 cycles of 30sec each)

% mode '003'
% trigger pulse registered as regular keyboard input:  't' for RGBY
% or '5'  for num mode
% response boxes '1' to '4' & '6' to '9'

addpath('Common_Functions');
%Emul=0;
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
    Parameters.Resolution=[0 0 1280 800];%no! 1280 x 800
else
    Parameters.Screen=0;    % Main screen
    Parameters.Resolution=[0 0 1440 900];% [0 0 1440 900];   % Resolution %need to modify checkerboard size in gencheckerboard to = resolution height
end
Parameters.Foreground=[0 0 0];  % Foreground colour
Parameters.Background=[127 127 127];    % Background colour
Parameters.FontSize = 15;   % Size of font
Parameters.FontName = 'Helvetica';  % Font to use

%% Scanner parameters
Parameters.TR=3.0;      % Seconds per volume
Parameters.Number_of_Slices=30; % Number of slices
Parameters.Dummies=4;   % Dummy volumes
Parameters.Overrun=5;   % Dummy volumes at end

%% Experiment parameters
Parameters.Cycles_per_Expmt=8;  % Stimulus cycles per run
Parameters.Vols_per_Cycle=10;   % Volumes per cycle 
Parameters.Prob_of_Event=0.05;  % Probability of a jerk event
Parameters.Event_Duration=0.2;  % Duration of a jerk event
Parameters.Event_Size=0.02;  % Size of jerk event in proportion
Parameters.Apperture='Ring';    % Stimulus type
Parameters.Apperture_Width=128;  % Width of ring in pixels
Parameters.Direction=Direc; % Direction of cycling
Parameters.Rotate_Stimulus=false;   % Does image rotate?
% Conventional checkerboard
load('Checkerboard');
Parameters.Stimulus(:,:,1)=Checkerboard;
Parameters.Stimulus(:,:,2)=InvertContrast(Checkerboard);
Parameters.Refreshs_per_Stim=8;

%% Various parameters
Parameters.Instruction='Welcome!\n\nPress button when there is a jump!';
[Parameters.Session Parameters.Session_name]=CurrentSession([Subj '_Eccen' Direc]); % Determine current session

%% Run the experiment

Retinotopic_Mapping(Parameters, Emul,saveVideo);
