function Retinotopic_Mapping_NN(Parameters, Emulate, display)
%Retinotopic_Mapping(Parameters, Emulate, display)
% 
% Cyclic presentation with a rotating and/or expanding aperture.
% Behind the aperture a background is displayed as a movie.
%
% Parameters:
%   Parameters :    Struct containing various parameters
%   Emulate :       0 (default) for scanning
%                   1 for manual trigger
%   display :       Struct containing display parameters
%
% 
% Niia Nikolova 1.2014
%  Edits:
%       added input parameter structure 'display'
%       uses OpenWindow function
%       -> strange circle appears in stimulus?



% Create the mandatory folders if not already present 
if ~exist([cd '\Results'], 'dir')
    mkdir('Results');
end

%% Behavioural data
Behaviour = struct;
Behaviour.EventTime = [];
Behaviour.Response = [];
Behaviour.ResponseTime = [];

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

%% Initialize PTB
display = OpenWindow(display);
Win = display.windowPtr;
Rect = display.res;
HideCursor;
RefreshDur = Screen('GetFlipInterval',Win);
Slack = RefreshDur / 2;


%% Prepare event times output 

ResultsTrialNo=1;
ResultsEventSecOnset=2;     
ResultsEventsDuration=3;     
ResultsEventFramesOnset=4;    
ResultsAngle=5;
ResultsScale=6;
ResultsCycle=7;
ResultsCycleFrame=8;
ResultsCycleTime=9;
    
length(Events)
Results=zeros(9,length(Events));%allow 5 jumps per cycle
taskCount=0;

waitCurrTime = 0;
eventON=0;
totalFrameNo=0;


%% Load background movie
StimRect = [0 0 size(Parameters.Stimulus,2) size(Parameters.Stimulus,1)];
BgdTextures = [];
if length(size(Parameters.Stimulus)) < 4
    for f = 1:size(Parameters.Stimulus, 3)
        BgdTextures(f) = Screen('MakeTexture', Win, Parameters.Stimulus(:,:,f));
    end
else
    for f = 1:size(Parameters.Stimulus, 4)
        BgdTextures(f) = Screen('MakeTexture', Win, Parameters.Stimulus(:,:,:,f));
    end
end

%% Create fixation cross
Fix_Cross = cross_matrix(16) * 255;
[fh fw] = size(Fix_Cross);
Fix_Cross(:,:,2) = Fix_Cross;   % alpha layer
Fix_Cross(:,:,1) = InvertContrast(Fix_Cross(:,:,1));
FixCrossTexture = Screen('MakeTexture', Win, Fix_Cross);

%% Standby screen
Screen('FillRect', Win, display.bkColor, Rect);
DrawFormattedText(Win, [Parameters.Instruction '\n \n' TrigStr], 'center', 'center', display.fgColor); 
Screen('Flip', Win);

%% Wait for start of experiment
if Emulate == 1
    KbWait;
    WaitSecs(Parameters.TR*Parameters.Dummies);
    Start_Session = GetSecs;
    CurrSlice = 0;
else
    %%% CHANGE THIS TO WHATEVER CODE YOU USE TO TRIGGER YOUR SCRIPT!!! %%%
    config_serial;
    start_cogent;
    Port = 1;
    CurrSlice = waitslice(Port, Parameters.Dummies * Parameters.Number_of_Slices + 1);  
end

%% Begin main experiment 
Start_of_Expmt = NaN;   % Time when cycling starts
FrameTimes = [];  % Time stamp of each frame
CurrEvent = 1;  % Current dimming event
CurrFrame = 1;  % Current stimulus frame
CurrRefresh = 0;   % Current video refresh
CurrAngle = 0;  % Current angle of wedge
CurrScale = 0;  % Current inner radius of ring
PrevKeypr = 0;  % If previously key was pressed

%% Draw the fixation cross
Screen('FillRect', Win, display.bkColor, Rect);
Screen('DrawTexture', Win, FixCrossTexture, [0 0 fh fw], CenterRect([0 0 fh fw], Rect));
Screen('Flip', Win);

%% Initialize apperture texture
AppTexture = Screen('MakeTexture', Win, 127 * ones(Rect([4 3])));

%% Start cycling the stimulus
Behaviour.EventTime = Events;
CycleDuration = Parameters.TR * Parameters.Vols_per_Cycle;
CyclingEnd = CycleDuration * Parameters.Cycles_per_Expmt;
CyclingStart = GetSecs;
CurrTime = GetSecs-CyclingStart;
IsEvent = false; 
WasEvent = false;

% Loop until the end of last cycle
while CurrTime < CyclingEnd    
    %% Update frame number
    CurrRefresh = CurrRefresh + 1;
    if CurrRefresh == Parameters.Refreshs_per_Stim
        CurrRefresh = 0;
        CurrFrame = CurrFrame + 1;
        if length(size(Parameters.Stimulus)) < 4
            if CurrFrame > size(Parameters.Stimulus,3) 
                CurrFrame = 1;
            end
        else
            if CurrFrame > size(Parameters.Stimulus,4) 
                CurrFrame = 1;
            end
        end
    end
    % Current time stamp
    CurrTime = GetSecs-CyclingStart;        
    % Current frame time & condition
    FrameTimes = [FrameTimes; CurrTime CurrFrame CurrAngle CurrScale];
    
    %% Determine size & angle
    % Rotation of apperture
    if strcmpi(Parameters.Direction, '+')
        CurrAngle = 90 - Parameters.Apperture_Width/2 + (CurrTime/CycleDuration) * 360;
    elseif strcmpi(Parameters.Direction, '-')
        CurrAngle = 90 - Parameters.Apperture_Width/2 - (CurrTime/CycleDuration) * 360;
    end
    % Size of apperture
    if strcmpi(Parameters.Direction, '+')
        CurrScale = 0 + mod(CurrTime, CycleDuration)/CycleDuration * StimRect(4);
    elseif strcmpi(Parameters.Direction, '-')
        CurrScale = StimRect(4) - mod(CurrTime, CycleDuration)/CycleDuration * StimRect(4);
    end
    
    %% Create apperture texture
    Screen('Fillrect', AppTexture, display.bkColor);
    if strcmpi(Parameters.Apperture, 'Ring')
        Screen('FillOval', AppTexture, [0 0 0 0], CenterRect([0 0 repmat(CurrScale+Parameters.Apperture_Width,1,2)], Rect));
        Screen('FillOval', AppTexture, [display.bkColor 255], CenterRect([0 0 repmat(CurrScale,1,2)], Rect));
        % Wrapping around?
        WrapAround = CurrScale+Parameters.Apperture_Width-StimRect(4);
        if WrapAround < 0
            WrapAround = 0;
        end
        Screen('FillOval', AppTexture, [0 0 0 0], CenterRect([0 0 repmat(WrapAround,1,2)], Rect));
    elseif strcmpi(Parameters.Apperture, 'Wedge')
        Screen('FillArc', AppTexture, [0 0 0 0], CenterRect([0 0 repmat(StimRect(4),1,2)], Rect), CurrAngle, Parameters.Apperture_Width);
    elseif strcmpi(Parameters.Apperture, 'Propeller')
        Screen('FillArc', AppTexture, [0 0 0 0], CenterRect([0 0 repmat(StimRect(4),1,2)], Rect), CurrAngle, Parameters.Apperture_Width);
        Screen('FillArc', AppTexture, [0 0 0 0], CenterRect([0 0 repmat(StimRect(4),1,2)], Rect), CurrAngle+180, Parameters.Apperture_Width);
    end

    %% Stimulus presentation
    % Display background
    if Parameters.Rotate_Stimulus
        BgdAngle = CurrAngle;
    else        
        BgdAngle = 0;
    end
    % Rotate background movie?
    SineRotate = cos(CurrTime/Parameters.TR * 2*pi) * Parameters.Sine_Rotation;

    Screen('DrawTexture', Win, BgdTextures(CurrFrame), StimRect, CenterRect(StimRect, Rect), BgdAngle+SineRotate);
    % Draw aperture
    Screen('DrawTexture', Win, AppTexture);
    % Draw the fixation cross & aperture
    Screen('DrawTexture', Win, FixCrossTexture);    
    % Is this an event?
    CurrEvents = Events - CurrTime;
    if sum(CurrEvents > 0 & CurrEvents < Parameters.Event_Duration)
        IsEvent = true;
        if WasEvent == false
            RndAngle = RandOri;
            RndScale = round(rand*(Rect(4)/2));
            WasEvent = true;
        end
        if strcmpi(Parameters.Apperture, 'Wedge')
            [X Y] = pol2cart((90+CurrAngle+Parameters.Apperture_Width/2)/180*pi, RndScale);
        elseif strcmpi(Parameters.Apperture, 'Propeller')
            [X Y] = pol2cart((90+CurrAngle+Parameters.Apperture_Width/2)/180*pi, RndScale);
        elseif strcmpi(Parameters.Apperture, 'Ring')
            [X Y] = pol2cart(RndAngle/180*pi, CurrScale/2+Parameters.Apperture_Width/4);
        end
        X = Rect(3)/2-X;
        Y = Rect(4)/2-Y;
        % Draw event
        Screen('FillOval', Win, display.bkColor, [X-Parameters.Event_Size/2 Y-Parameters.Event_Size/2 X+Parameters.Event_Size/2 Y+Parameters.Event_Size/2]);
    else
        IsEvent = false;
        WasEvent = false;
    end
    % Draw current video frame   
    rft = Screen('Flip', Win);
    if isnan(Start_of_Expmt)
        Start_of_Expmt = rft;
    end
    
    %% Behavioural response
    [Keypr KeyTime Key] = KbCheck;
    if Key(KeyCodes.Escape) 
        % Abort screen
        Screen('FillRect', Win, display.bkColor, Rect);
        DrawFormattedText(Win, 'Experiment was aborted!', 'center', 'center', display.fgColor); 
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
            Behaviour.Response = [Behaviour.Response; find(Key)];
            Behaviour.ResponseTime = [Behaviour.ResponseTime; KeyTime - CyclingStart];
        end
    else
        if PrevKeypr
            PrevKeypr = 0;
        end
    end
end

%% Draw the fixation cross
Screen('DrawTexture', Win, FixCrossTexture);
End_of_Expmt = Screen('Flip', Win);

%%% REMOVE THIS IF YOU DON'T USE COGENT!!! %%%
% Turn off Cogent
% if Emulate == 0
%     stop_cogent;
% end

%% Farewell screen
Screen('FillRect', Win, display.bkColor, Rect);
DrawFormattedText(Win, 'Goodbye & Thank you!', 'center', 'center', display.fgColor); 
Screen('Flip', Win);
WaitSecs(Parameters.TR * Parameters.Overrun);
ShowCursor;
Screen('CloseAll');

%% Save workspace
Parameters = rmfield(Parameters, 'Stimulus');  
clear('Apperture', 'R', 'T', 'X', 'Y');
Parameters.Stimulus = [];
save(['Results' filesep Parameters.Session_name]);

%% Experiment duration
new_line;
ExpmtDur = End_of_Expmt - Start_of_Expmt;
ExpmtDurMin = floor(ExpmtDur/60);
ExpmtDurSec = mod(ExpmtDur, 60);
disp(['Cycling lasted ' num2str(ExpmtDurMin) ' minutes, ' num2str(ExpmtDurSec) ' seconds']);
new_line;
WaitSecs(1);
