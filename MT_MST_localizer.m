function MT_MST_localizer( Subj, modeIn , Emulate )
% MT-MST_localizer
%
% MT/MT+ localizer for fMRI
%

%         
%       mode
%           1     MT localizer: alternating fields of contracting/expanding, and stationary dots
%                   DURATION: 4.2 minutes
%
%           2     Ipsilateral stimulus for MT/MST differentiation
%                   DURATION (5 cycles/side): 12 minutes
%
%
%       Ipsilateral stimulus
%           Huk et al. 2002: 15 deg diameter circular dot patch to left or right of
%           fixation. 18 sec moving, 18 sec stationary, 7 cycles. center 25deg from
%           frixation. 6-12 reps per side
%
%
%
%
% note that at magnet, viewing distance is 202 cm; 5 deg visual angle
% correxponding to 365 pixels (0.0137deg/pxl = 0.822'/pxl)
% need to change monitor dimensions below for changes in display. Stimuli
% are changed automatically.
% Need to change fixation spot size! (possibly, check how it looks)
%
% add task??: indicate brief periods of random dot motion

%
% 25.09.2014 edited from MT_localizer to use KBQueue instead of KbCheck
% 
% Niia Nikolova 03.2014

smallScreen = 0;


addpath('Common_Functions');
% Create the mandatory folders if not already present
% cd /Users/nnikolova/ownCloud/MATLABscripts/NNscripts/Retinotopic_Mapping
if ~exist([cd '\data'], 'dir')
    mkdir('data');
end

persistent mode

if isempty(mode),
    % if we have not run before, we initialize to the last mode in the
    % sequence. the next block will advance us to the first
    if nargin>1,
        mode = modeIn;
    else
        mode = 1;
    end
end

% if no mode is provided, we advance to the next
if nargin<2,
    switch mode
        case 1,
            mode = 2;
        case 2,
            mode = 1;
    end
end

if nargin==0
    Subj = 'Demo';
    Emulate = 1;
%     mode = 1;
elseif nargin==1 
    Emulate=0; 
%     mode = modeIn;
elseif nargin==2
    Emulate=0;
    mode = modeIn;
end

%% is there an open window?
Win = Screen('Windows');
if numel(Win)>1,
    Win = [];
    sca;
end

%% Engine parameters
sc = Screen('Screens');
if length(sc)>1  && isempty(Win),
    % two screens, no window open
    Parameters.Screen = str2num(input(['Screen number (' num2str(sc) '):'],'s'));
    if ~find(sc==Parameters.Screen),
        error('Invalid screen number');
    end
    %Parameters.Commandscreen = sc(sc~=Parameters.Screen);
    display.dist = 202;             %in cm
    display.width = 52;%1280; 
    display.heigth = 32;%800;
elseif isempty(Win),
    % one screen
    Parameters.Screen = 0;
    %Parameters.Commandscreen = [];
    display.dist = 50;               %in cm                  
    display.width = 33;                
    display.heigth = 21;
else
    % two screens, window already open
    Parameters.Screen = Screen('WindowScreenNumber',Win);
    %Parameters.Commandscreen = sc(sc~=Paremeters.Screen);
end
display.screenNum = Parameters.Screen;
Parameters.Resolution=Screen('Rect',Parameters.Screen);
Parameters.Foreground=[256 256 256];  % Foreground colour
Parameters.Background=[127 127 127];    % Background colour
Parameters.FontSize = 15;   % Size of font
Parameters.FontName = 'Helvetica';  % Font to use

display.bkColor = Parameters.Background;
if smallScreen
    display.rect = [0 0 360 225];%[0 0 1440 900];
end

%% Scanner parameters
Parameters.TR=3.00;%3.06;     % Seconds per volume
Parameters.Dummies=4;   % Dummy volumes
Parameters.Overrun=5;   % Dummy volumes at end

%% Experiment parameters
Parameters.Cycles_per_Expmt=4;%7;  % Stimulus cycles per run
Parameters.Vols_per_Cycle=6;%10;   % Volumes per cycle 
Parameters.Prob_of_Event=0.05;  % Probability of a target event
Parameters.Event_Duration=0.2;  % Duration of a target event

%% Various parameters
Parameters.Instruction='Please fixate at all times!  Press button when a target appears!';
[Parameters.Session Parameters.Session_name]=CurrentSession([Subj '_MT-MST_loc']); % Determine current session
Parameters.FontSize = 35;   % Size of font
Parameters.FontName = 'Helvetica';  % Font to use

%% Stimulus params
design.mode = mode;
design.coherence = 1;        
design.direction = 1; 
design.duration = 1;
design.nReps = (design.duration.*60)/2;  % # of direction reversals         
design.stimDur = 1;                 % stimulus duration (sec) 
design.nDots=600;   %300;           % # dots in each field
design.dotSpeed = 8;%9              % dot speed in pix/frame
design.dotLT=15;%10;%40;                % dot lifetime in frames
design.DateTime = datestr(now);     % get current time

               
dots.nDots = design.nDots;               
dots.speed = design.dotSpeed;            % pix/frame
dots.direction = NaN;                   
dots.lifetime = design.dotLT;            % frames
dots.color = [256 256 256];              
dots.size = 0.12;%3;%5;                        % degrees
dots.coherence = design.coherence;                    


switch mode   
    case 1          % MT localizer
        dots.apertureSize = [20,20];   %deg, radius          
        dots.center = [0,0];
        design.stationarDur = 27;      %sec

    case 2          % MST localizer - Ipsilateral
        Parameters.Cycles_per_Expmt=10;  % Stimulus cycles per run
        dots.apertureSize = [14,14];             
        dots.center = [10,0];%[-10,0];
        design.stationarDur = 18;      %sec
end


%% Behavioural data
Behaviour = struct;
Behaviour.EventTime = [];
Behaviour.Response = [];
Behaviour.ResponseTime = [];
videoname='MT-MST_localizer';
   
%% Initialize randomness & keycodes
SetupRand;
SetupKeyCodes;

%% Stimulus conditions 
Volumes = [];  
% Cycle through repeats of each set
for i = 1 : Parameters.Cycles_per_Expmt 
    Volumes = [Volumes; ones(Parameters.Vols_per_Cycle, 1)];
end
Vols_per_Expmt = length(Volumes);
if Emulate
    % In manual start there are no dummies
    Parameters.Dummies = 0;
    Parameters.Overrun = 0;
end
disp(['Volumes = ' num2str(Vols_per_Expmt + Parameters.Dummies + Parameters.Overrun)]); disp(' ');
WaitSecs(0.5);
% Add column for volume time stamps
Volumes = [Volumes, zeros(Vols_per_Expmt,1)];
Cycle_Vols = find(Volumes(:,1) == 1);

%% Event timings 
Events = [];
for e = Parameters.TR : Parameters.Event_Duration : (Parameters.Cycles_per_Expmt * Parameters.Vols_per_Cycle * Parameters.TR)
    if rand < Parameters.Prob_of_Event
        Events = [Events; e];
    end
end
% Add a dummy event at the end of the Universe
Events = [Events; Inf];


%% Configure scanner 
if Emulate 
    % Emulate scanner
    TrigStr = 'Press key to start...';    % Trigger string
else
    % Real scanner
    TrigStr = 'Stand by for scan...';    % Trigger string
end



%% Run the experiment

try
    % Open a graphics window on the main screen
    display = OpenWindow(display);
    HideCursor;
    
    Win = display.windowPtr;
    Rect = display.res;
    
    
    Screen('TextFont', Win, Parameters.FontName);
    Screen('TextSize', Win, Parameters.FontSize);
    
    % Query frame duration: We use it later on to time 'Flips' properly for an
    % animation with constant framerate:
    Priority(9);%Enable realtime-scheduling
    ifi = Screen('GetFlipInterval', Win,5);
    Priority(0);%Disable realtime-scheduling
    framesPerSecond=1/ifi;
    
    %% Prepare event times output 

    triggers = [];

    ResultsTrialNo=1;
    ResultsEventSecOnset=2;     
    ResultsEventsDuration=3;     
    ResultsEventFramesOnset=4;    
    ResultsAngle=5;
    ResultsScale=6;
    ResultsCycle=7;
    ResultsCycleFrame=8;
    ResultsCycleTime=9;

    Results=zeros(9,length(Events));%allow 5 jumps per cycle
    taskCount=0;

    waitCurrTime = 0;
    eventON=0;
    totalFrameNo=0;
    
    %% Standby screen
    Screen('FillRect', Win, Parameters.Background, Rect);
    drawText(display,[0,5],[Parameters.Instruction],[255,255,255]);
    drawText(display,[0,-2],[ TrigStr],[255,255,255]);
    Screen('Flip', Win);
    
%% Wait for start of experiment
% set up key queue
KbName('UnifyKeyNames');

KeyCodes.Trigger = KbName('5%');
KeyCodes.Escape = KbName('Escape');
KbQueueCreate; 
KbQueueStart;
   
    
    
%%     Wait for start of experiment
[~,firstPressed] = KbQueueCheck;
while ~firstPressed(KeyCodes.Trigger),
    [~,firstPressed] = KbQueueCheck;
end
    

WaitSecs(Parameters.TR*Parameters.Dummies);
Start_Session = GetSecs;
CurrSlice = 0;
    
%% Begin main experiment 
FrameTimes = [];  % Time stamp of each frame
CurrEvent = 1;  % Current dimming event
CurrFrame = 1;  % Current stimulus frame
CurrAngle = 0;  % Current angle of wedge
CurrScale = 0;  % Current inner radius of ring
PrevKeypr = 0;  % If previously key was pressed

%% Start cycling the stimulus
Behaviour.EventTime = Events;
CycleDuration = Parameters.TR * Parameters.Vols_per_Cycle;
CyclingEnd = CycleDuration * Parameters.Cycles_per_Expmt;
CyclingStart = GetSecs;
CurrTime = GetSecs-CyclingStart;
Start_of_Expmt = CurrTime;
countCycle=1;

ifi
framesPerSecond

CycleDuration
CurrTime
CyclingEnd
 
while CurrTime < CyclingEnd
    
          
% Trigger // Behavioural response
  
    [ pressed, firstPress]=KbQueueCheck; % Collect keyboard events since KbQueueStart was invoked

    if pressed
        
        if firstPress(KeyCodes.Escape)
			% Abort screen
            Screen('FillRect', Win, Parameters.Background, Rect);
            DrawFormattedText(Win, 'Experiment was aborted!', 'center', 'center'); 
            WaitSecs(2);
            ShowCursor;
            Screen('CloseAll');
            disp(' '); 
            disp('Experiment aborted by user!'); 
            disp(' ');
            KbQueueFlush;
            return
        end
        
        if GetSecs - PrevKeypr > 0.2,
            PrevKeypr = GetSecs;
            if firstPress(KeyCodes.Trigger),
                triggers = [triggers; GetSecs GetSecs - CyclingStart];
            else
                k = find(firstPress);
                Behaviour.Response = [Behaviour.Response; k];
                Behaviour.ResponseTime = [Behaviour.ResponseTime; ones(size(k))*(GetSecs - CyclingStart)];
            end
        end
    end


    % Current time stamp
    CurrTime = GetSecs-CyclingStart; 
    
    % Current frame time & condition
    FrameTimes = [FrameTimes; CurrTime CurrFrame CurrAngle CurrScale];

    % Is this an event? (Jump apperture by a step)
    CurrEvents = Events - CurrTime;


div = CurrTime/CycleDuration - floor(CurrTime/CycleDuration);
%     if mod((round(CurrTime/CycleDuration)),2)==0    % exapnding / contracting motion
    if div  <= 0.5
        
        dots(1).speed = design.dotSpeed;
        dots(1).lifetime = design.dotLT;
        
        if mode == 2
            if mod(round(CurrTime/(CycleDuration.*4)),2) == 0
                dots.center = [10,0];
            else
                dots.center = [-10,0];
            end
        end
        
        if mod(round(CurrTime),2)==0        %expanding
            dots(1).direction = -(design.direction);
        elseif mod(round(CurrTime),2)==1    %contracting
            dots(1).direction = design.direction;
        end
        
        [triggers] = drawDots_MTloc(display,dots(1),design.stimDur,Behaviour,KeyCodes,triggers,CyclingStart,PrevKeypr);
        
        CurrTime = GetSecs-CyclingStart;
        
        
    
    else                                            % stationary
       
        dots(1).speed = 0;
        dots(1).lifetime = exp(10);
        
        [triggers] = drawDots_MTloc(display,dots(1),design.stationarDur,Behaviour,KeyCodes,triggers,CyclingStart,PrevKeypr);
        
        Results(ResultsCycleTime,countCycle)=CurrTime;
        Results(ResultsCycleFrame,countCycle)=totalFrameNo;
        
    end
    
    
    
    
%     if sum(CurrEvents > 0 & CurrEvents < Parameters.Event_Duration)
%         disp('CurrEvents > 0 & CurrEvents < Parameters.Event_Duration');
%     end

    countCycle=countCycle+1;
  
end

%% Finish up
    % save event times and stats to textfiles
    DateTimeStr=datestr(now,'dd-mm-yyyy_HH-MM');
    outputfile=[videoname '_' DateTimeStr '.txt'];
    fid = fopen(outputfile,'w');
    fprintf(fid,'totalFrames: %u \n totalTimeSec: %4.2f   avgFramesPerSec: %4.2f \n', totalFrameNo, CurrTime, totalFrameNo/CurrTime);
    fprintf(fid,'\n NofTrials: %u\n',taskCount);
    for x=1:Parameters.Cycles_per_Expmt
        fprintf(fid,'\nCycle: %u   StartTimeSec: %4.2f    StartFrame: %u',x,Results(ResultsCycleTime,x),Results(ResultsCycleFrame,x));
    end;
    fprintf(fid,'\n\n');
    for x=1:length(Events)
        fprintf(fid,'\nTrialNo: %u     TaskOnsetSec: %4.2f      TaskOnsetFrames: %u     TaskDurationSec: %4.2f     Angle: %4.2f    Scale: %4.2f    Cycle: %u\n',Results(ResultsTrialNo,x),Results(ResultsEventSecOnset,x), Results(ResultsEventFramesOnset,x),Results(ResultsEventsDuration,x),Results(ResultsAngle,x),Results(ResultsScale,x),Results(ResultsCycle,x));
    end;
    fclose(fid);
    
    %% Farewell screen
    End_of_Expmt = GetSecs-CyclingStart;
    Screen('Flip', Win); 
    Screen('FillRect', Win, Parameters.Background, Rect);
    DrawFormattedText(Win, 'Goodbye & Thank you!', 'center', 'center', Parameters.Foreground); 
    Screen('Flip', Win);
    WaitSecs(Parameters.TR * Parameters.Overrun);
    Screen('CloseAll');
    ShowCursor;                         
    KbQueueRelease;
    
    cd Results
    Parameters.Session_name = [Parameters.Session_name '_' DateTimeStr];
    eval(['save ', Parameters.Session_name, ' Results Behaviour triggers']);
%     
%     save ([savingpath(variable),'/',savingsubpaths(variable),'/',nameofthefile(variable)],'var')

    %% Experiment duration
    new_line;
    ExpmtDur = End_of_Expmt - Start_of_Expmt;
    ExpmtDurMin = floor(ExpmtDur/60);
    ExpmtDurSec = mod(ExpmtDur, 60);
    disp(['Cycling lasted ' num2str(ExpmtDurMin) ' minutes, ' num2str(ExpmtDurSec) ' seconds']);
    new_line;
    WaitSecs(1);
    
catch ME
    rethrow(ME)
    % Abort screen
    Screen('FillRect', Win, Parameters.Background, Rect);
    DrawFormattedText(Win, 'Experiment was aborted!', 'center', 'center'); 
    WaitSecs(2);
    ShowCursor;
    Screen('CloseAll');
    disp(' '); 
    disp('Experiment aborted by user!'); 
    disp(' ');
    KbQueueFlush;
    return
end

end

