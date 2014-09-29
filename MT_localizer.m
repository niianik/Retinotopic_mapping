function MT_localizer( Subj, Durat, Emulate )
% MT_localizer
%
% MT/MT+ localizer for fMRI
%
% alternates fields of translating, expanding, rotating dots
% task: indicate brief periods of random dot motion
%
%
% note that at magnet, viewing distance is 202 cm; 5 deg visual angle
% correxponding to 365 pixels (0.0137deg/pxl = 0.822'/pxl)
% need to change monitor dimensions below for changes in display. Stimuli
% are changed automatically.
% Need to change fixation spot size! (possibly, check how it looks)
% Might need to change dot field size (could be too small for all the dots, or need to reduce dot number if density too high)
% before creating videos for scanner, set monitor resolution to 1280:800!
%
% Niia Nikolova 03.2014


addpath('Common_Functions');
% Create the mandatory folders if not already present
cd /Users/nnikolova/ownCloud/MATLABscripts/NNscripts/Retinotopic_Mapping
if ~exist([cd '\Results'], 'dir')
    mkdir('Results');
end

if nargin==0
    Subj='Demo';
    Durat=1;%minutes
    Emulate=1;
elseif nargin==1
    Durat=8;    %blocks
    Emulate=0; 
elseif nargin==2
    Emulate=0;
end


%% Engine parameters
if length(Screen('Screens'))>1
    display.screenNum = 1;    % Extra screen, in scanner
    display.dist = 2025;
    display.width = 650;%1280; 
    display.heigth = 400;%800;

else
    display.screenNum = 0;    % Main screen
    display.dist = 50;                  
    display.width = 30;                
    display.heigth = 20;
end

display.fgColor = [256 256 256];  % Foreground colour
display.bkColor = [0 0 0];  % background color = grey
display.setBlendFunction = 1;
display.text.size = 24;

%% Scanner parameters
Parameters = struct;    % Initialize the parameters variable
Parameters.TR=3.06;     % Seconds per volume
Parameters.Number_of_Slices=30; % Number of slices
Parameters.Dummies=4;   % Dummy volumes
Parameters.Overrun=0;   % Dummy volumes at end

%% Experiment parameters
Parameters.Cycles_per_Expmt=8;  % Stimulus cycles per run
Parameters.Vols_per_Cycle=10;   % Volumes per cycle 
Parameters.Prob_of_Event=0.05;  % Probability of a target event
Parameters.Event_Duration=0.2;  % Duration of a target event

%% Various parameters
Parameters.Instruction='Please fixate at all times!  Press button when a target appears!';
[Parameters.Session Parameters.Session_name]=CurrentSession([Subj '_MT-MST_loc']); % Determine current session
Parameters.FontSize = 35;   % Size of font
Parameters.FontName = 'Helvetica';  % Font to use

%% Stimulus params
design.coherence = 1;        
design.direction = 1;               
design.nReps = (Durat.*60)/2;           
design.stimDur = 1;                 % stimulus duration (sec) 
design.nDots=600;   %300;           % # dots in each field
design.dotSpeed = 9;%5              % dot speed in pix/frame
design.dotLT=10;%40;                % dot lifetime in frames
design.DateTime = datestr(now);     % get current time

               
dots(1).nDots = design.nDots;               % # of dots in this field
dots(1).speed = design.dotSpeed;            % pix/frame
dots(1).direction = NaN;                    % defined by 'direction' param in function call (1 contraction, -1 expansion)
dots(1).lifetime = design.dotLT;            % frames
dots(1).apertureSize = [20,20];             % aperture size for this field
dots(1).center = [0,0];
dots(1).color = [256 256 256];              % black
dots(1).size = 5;%2;                        % pixels
dots(1).coherence = design.coherence;                    % to be defined in each trial


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
Start_of_Expmt = NaN;   % Time when cycling starts

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
    Screen('FillRect', Win, display.bkColor, Rect);
    drawText(display,[0,5],[Parameters.Instruction],[255,255,255]);
    drawText(display,[0,-2],[ TrigStr],[255,255,255]);
    Screen('Flip', Win);
    
%% Wait for start of experiment
if Emulate == 1
    KbWait;
end
    WaitSecs(Parameters.TR*Parameters.Dummies);
    Start_Session = GetSecs;
    CurrSlice = 0;
    
%% Begin main experiment 
Start_of_Expmt = NaN;   % Time when cycling starts
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
countCycle=1;


CycleDuration
CurrTime
CyclingEnd
 
while CurrTime < CyclingEnd
    
          
        %% Trigger // Behavioural response
        [Keypr KeyTime Key] = KbCheck;
        if Key(KeyCodes.Escape) 
            % Abort screen
            Screen('FillRect', Win, Parameters.Background, Rect);
            DrawFormattedText(Win, 'Experiment was aborted!', 'center', 'center', Parameters.Foreground); 
            Results
            WaitSecs(0.5);
            ShowCursor;
            Screen('CloseAll');
            disp(' '); 
            disp('Experiment aborted by user!'); 
            disp(' ');
            return
        end
        if Keypr 
            if ~PrevKeypr
                PrevKeypr = 1;
                if Key(KeyCodes.Number(5))%find(Key)== 34 is trigger pulse (keyboard 5)
                    triggers = [triggers;KeyTime KeyTime - CyclingStart]
                else
                    Behaviour.Response = [Behaviour.Response; find(Key)];
                    Behaviour.ResponseTime = [Behaviour.ResponseTime; KeyTime - CyclingStart];
                end
            end
        else
            if PrevKeypr
                PrevKeypr = 0;
            end
        end
       


    % Current time stamp
    CurrTime = GetSecs-CyclingStart; 
    
    % Current frame time & condition
    FrameTimes = [FrameTimes; CurrTime CurrFrame CurrAngle CurrScale];

    % Is this an event? (Jump apperture by a step)
    CurrEvents = Events - CurrTime;

%     CurrTime;
%     countCycle*CycleDuration;
%     num = (round((CurrTime)/2));
%     div = floor(CycleDuration);

    if mod((round(CurrTime/CycleDuration)),2)==0
        
        dots(1).speed = design.dotSpeed;
        dots(1).lifetime = design.dotLT;
        
        if mod(round(CurrTime),2)==0        %even
            dots(1).direction = -(design.direction);
        elseif mod(round(CurrTime),2)==1    %odd
            dots(1).direction = design.direction;
        end
        
        drawDots02072013(display,dots(1),design.stimDur);
        
        CurrTime = GetSecs-CyclingStart;
    else
        

        dots(1).speed = 0;
        dots(1).lifetime = exp(10);
        drawDots02072013(display,dots(1),30);
        
        Results(ResultsCycleTime,countCycle)=CurrTime;
        Results(ResultsCycleFrame,countCycle)=totalFrameNo;
        
    end
    
    if sum(CurrEvents > 0 & CurrEvents < Parameters.Event_Duration)
        disp('CurrEvents > 0 & CurrEvents < Parameters.Event_Duration');
    end

    countCycle=countCycle+1;
    
    
end
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
    End_of_Expmt = Screen('Flip', Win);
    Screen('FillRect', Win, display.bkColor, Rect);
    DrawFormattedText(Win, 'Goodbye & Thank you!', 'center', 'center', display.fgColor); 
    Screen('Flip', Win);
    WaitSecs(Parameters.TR * Parameters.Overrun);
    Screen('CloseAll');
    ShowCursor;                         % show the mouse cursor again
    
    
    cd Results
    Parameters.Session_name = [Parameters.Session_name '_' DateTimeStr];
    eval(['save ', Parameters.Session_name, ' Results Behaviour triggers']);

    %% Experiment duration
    new_line;
    ExpmtDur = End_of_Expmt - Start_of_Expmt;
    ExpmtDurMin = floor(ExpmtDur/60);
    ExpmtDurSec = mod(ExpmtDur, 60);
    disp(['Cycling lasted ' num2str(ExpmtDurMin) ' minutes, ' num2str(ExpmtDurSec) ' seconds']);
    new_line;
    WaitSecs(1);
catch ME
    Screen('CloseAll');
    rethrow(ME)
end

end

