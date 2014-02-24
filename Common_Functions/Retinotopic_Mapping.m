function Retinotopic_Mapping(Parameters, Emulate, saveVideo)
%Retinotopic_Mapping(Parameters, Emulate)
% 
% Cyclic presentation with a rotating and/or expanding aperture.
% Behind the aperture a background is displayed as a movie.
%
% Parameters:
%   Parameters :    Struct containing various parameters
%   Emulate :       0 (default) for scanning
%                   1 for simulation with SimulScan
%                   2 for manual trigger
%
% includes time output for phase jumps to allow correlation with subject
% responses in the scanner.

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
[Win Rect] = Screen('OpenWindow', Parameters.Screen, Parameters.Background, Parameters.Resolution); 
Screen('TextFont', Win, Parameters.FontName);
Screen('TextSize', Win, Parameters.FontSize);
Screen('BlendFunction', Win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
HideCursor;
RefreshDur = Screen('GetFlipInterval',Win);
Slack = RefreshDur / 2;


%% video output
% prepare struct to contain individual frames for export to video
% struct for movie frames -> for avi output -- trick here is that for movie2avi()
% to work, the struct must have the fields cdata and colormap, even if
% colormap is not used.

%saveVideo=0;

framesPerSecond=1/RefreshDur;

totalFramesVideo=0;
    countVideo=0;
%     durationVideo=baseBlockDuration+stimBlockDuration
    maxFramesVideo=100;%round((durationVideo/1000)*framesPerSecond)
    videoname='Retinotopy';
   stimString='_';

if strcmpi(Parameters.Apperture, 'Wedge')
    stimString='Polar';
elseif strcmpi(Parameters.Apperture, 'Ring')
    stimString='Eccen';
end;
    
videoname=[videoname '_' stimString]; 
ims(maxFramesVideo).cdata=zeros(size(Parameters.Stimulus,2),size(Parameters.Stimulus,1));%maxFramesVideo);%[];
ims(maxFramesVideo).colormap=[];%zeros(3,maxFramesVideo);%[];


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
for f = 1:size(Parameters.Stimulus, 3)
    BgdTextures(f) = Screen('MakeTexture', Win, Parameters.Stimulus(:,:,f));
end

%% Create apperture texture
[X Y] = meshgrid(-Rect(3)*2/3:Rect(3)*2/3, -Rect(3)*2/3:Rect(3)*2/3);
[T R] = cart2pol(X,Y);
T = NormDeg(T / pi * 180);
Apperture = 127 * ones(size(T));
if strcmpi(Parameters.Apperture, 'Ring')
    Apperture(:,:,2) = (R < Rect(4)/2 - Parameters.Apperture_Width | R > Rect(4)/2) * 255;
elseif strcmpi(Parameters.Apperture, 'Wedge')
    Apperture(:,:,2) = (T < 90-Parameters.Apperture_Width/2 | T > 90+Parameters.Apperture_Width/2 | R > Rect(4)/2) * 255;
end
AppRect = [0 0 size(Apperture,2) size(Apperture,1)];
AppTexture = Screen('MakeTexture', Win, Apperture);

%% Create fixation cross
Fix_Cross = cross_matrix(16) * 255;
[fh fw] = size(Fix_Cross);
Fix_Cross(:,:,2) = Fix_Cross;   % alpha layer
Fix_Cross(:,:,1) = InvertContrast(Fix_Cross(:,:,1));
FixCrossTexture = Screen('MakeTexture', Win, Fix_Cross);

%% Standby screen
Screen('FillRect', Win, Parameters.Background, Rect);
DrawFormattedText(Win, [Parameters.Instruction '\n \n' TrigStr], 'center', 'center', Parameters.Foreground); 
Screen('Flip', Win);

%% Wait for start of experiment
if Emulate == 1
    KbWait;
    WaitSecs(Parameters.TR*Parameters.Dummies);
    Start_Session = GetSecs;
    CurrSlice = 0;
else
    %%% INSERT CODE FOR TRIGGERING VIA THE SCANNER PULSE !!! %%%		
    config_serial;
    start_cogent;
    Port = 1;
    %%waitserialbyte(port_num, t, b) %??
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
Screen('FillRect', Win, Parameters.Background, Rect);
Screen('DrawTexture', Win, FixCrossTexture, [0 0 fh fw], CenterRect([0 0 fh fw], Rect));
Screen('Flip', Win);

%% Start cycling the stimulus
Behaviour.EventTime = Events;
CycleDuration = Parameters.TR * Parameters.Vols_per_Cycle;
CyclingEnd = CycleDuration * Parameters.Cycles_per_Expmt;
CyclingStart = GetSecs;
CurrTime = GetSecs-CyclingStart;

countCycle=0;

MovieDelay=0;

% Loop until the end of last cycle
while CurrTime < CyclingEnd   
    
    % Update frame number
    CurrRefresh = CurrRefresh + 1;
    if CurrRefresh == Parameters.Refreshs_per_Stim
        CurrRefresh = 0;
        CurrFrame = CurrFrame + 1;
        if CurrFrame > size(Parameters.Stimulus,3) 
            CurrFrame = 1;
        end
    end
    % Current time stamp
    CyclingStart=CyclingStart+MovieDelay;
    %CyclingEnd=CyclingEnd;
    CurrTime = GetSecs-CyclingStart; 
    MovieDelay=0;
    
    % Current frame time & condition
    FrameTimes = [FrameTimes; CurrTime CurrFrame CurrAngle CurrScale];

    %% Prepare aperture
    % Is this an event? (Jump apperture by a step)
    CurrEvents = Events - CurrTime;

    if CurrTime>countCycle*CycleDuration
        Results(ResultsCycleTime,countCycle+1)=CurrTime;
        Results(ResultsCycleFrame,countCycle+1)=totalFrameNo;
        countCycle=countCycle+1;
    end;
    if sum(CurrEvents > 0 & CurrEvents < Parameters.Event_Duration)
        AppJump = Parameters.Event_Size;
        %save event times and frames to Results-array for later output
            %to text file
        if eventON==0
            taskCount=taskCount+1;
            Results(ResultsTrialNo,taskCount)=taskCount;
            Results(ResultsEventSecOnset,taskCount)=CurrTime;
            if saveVideo==1
                Results(ResultsEventSecOnset,taskCount)=totalFrameNo*RefreshDur;
            end;
            Results(ResultsEventsDuration,taskCount)=Parameters.Event_Duration;
            Results(ResultsEventFramesOnset,taskCount)=totalFrameNo;
            if strcmpi(Parameters.Apperture, 'Wedge') && strcmpi(Parameters.Direction, '+')
                Results(ResultsAngle,taskCount)=CurrAngle-90-360*(countCycle-1);
            elseif strcmpi(Parameters.Apperture, 'Wedge') && strcmpi(Parameters.Direction, '-')
                Results(ResultsAngle,taskCount)=CurrAngle+90+360*(countCycle-1);
            elseif strcmpi(Parameters.Apperture, 'Ring')
                Results(ResultsAngle,taskCount)=CurrAngle;
            end;
            Results(ResultsScale,taskCount)=CurrScale;
            Results(ResultsCycle,taskCount)=countCycle;
            sprintf('\nTrial: %u    CurrentTime %4.2f sec    CurrentFrame: %u    CurrentAngle %4.2f    CurrentScale: %u    cycleNo: %u',taskCount,CurrTime,totalFrameNo, Results(ResultsAngle,taskCount),CurrScale, countCycle)
            eventON=1;
        end;
    else 
        eventON=0;
        AppJump = 0;
    end
    % Determine size & angle
    if strcmpi(Parameters.Apperture, 'Wedge')
        CurrScale = 1;
        if strcmpi(Parameters.Direction, '+')
            CurrAngle = 90 + (CurrTime/CycleDuration) * 360 + AppJump;
        elseif strcmpi(Parameters.Direction, '-')
            CurrAngle = 90 - (CurrTime/CycleDuration) * 360 + AppJump;
        end
    elseif strcmpi(Parameters.Apperture, 'Ring')
        CurrAngle = 90;
        if strcmpi(Parameters.Direction, '+')
            CurrScale = 0.05 + mod(CurrTime, CycleDuration)/CycleDuration * 0.95 + AppJump;
        elseif strcmpi(Parameters.Direction, '-')
            CurrScale = 1 - mod(CurrTime, CycleDuration)/CycleDuration * 0.95 + AppJump;
        end
    end
      
    %% Stimulus presentation
    % Display background
    if Parameters.Rotate_Stimulus
        BgdAngle = CurrAngle;
    else        
        BgdAngle = 0;
    end

    Screen('DrawTexture', Win, BgdTextures(CurrFrame), StimRect, CenterRect(CurrScale * StimRect, Rect), BgdAngle);
    % Draw aperture
    Screen('DrawTexture', Win, AppTexture, [0 0 size(Apperture,2) size(Apperture,1)], CenterRect(CurrScale * AppRect, Rect), CurrAngle);
    % Draw the fixation cross & aperture
    Screen('DrawTexture', Win, FixCrossTexture);    
    % Draw current video frame   
    rft = Screen('Flip', Win);
    totalFrameNo=totalFrameNo+1;
    
    if isnan(Start_of_Expmt)
        Start_of_Expmt = rft;
    end
    
    %% Behavioural response
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
            Behaviour.Response = [Behaviour.Response; find(Key)];
            Behaviour.ResponseTime = [Behaviour.ResponseTime; KeyTime - CyclingStart];
        end
    else
        if PrevKeypr
            PrevKeypr = 0;
        end
    end

    
    
    % if this is a video-export run, save this frame to ims.cdata
    totalFramesVideo=totalFramesVideo+1;
    if saveVideo==1
        preMovieTime=GetSecs;
        ims(totalFramesVideo).cdata=Screen('GetImage',Win);

        if totalFramesVideo>maxFramesVideo 

            %xx%
           % videonamestring=[videoname num2str(countVideo) '_' num2str(totalFramesVideo) '.avi'];
                videonamestring=[videoname '_' num2str(countVideo) '.avi'];
                videonamestringNoAVI=[videoname '_' num2str(countVideo)];
                if countVideo>=100
                    videonamestringNoAVI=[videoname '_' num2str(countVideo)];
                    videonamestring=[videoname '_' num2str(countVideo) '.avi'];
                elseif countVideo<100 && countVideo>=10
                    videonamestringNoAVI=[videoname '_0' num2str(countVideo)];
                    videonamestring=[videoname '_0' num2str(countVideo) '.avi'];
                elseif countVideo<10
                    videonamestringNoAVI=[videoname '_00' num2str(countVideo)];
                    videonamestring=[videoname '_00' num2str(countVideo) '.avi'];
                end;

                movie2avi(ims,videonamestring,'COMPRESSION','None','FPS',framesPerSecond);   
                compressVideo(videonamestringNoAVI, 'comp',1);
                %compressVideo([videoname num2str(countVideo) '_' num2str(totalFramesVideo)], 'comp',1);
                totalFramesVideo=0;

                % reset timing after writing out frames
                % note: moved this section from %xx% (line 329) to line 352
                totalFramesVideo
                countVideo=countVideo+1;
                %
                MovieDelay=GetSecs-preMovieTime;
                fprintf('time: %u start: %u end: %u delay: %f \n',CurrTime,CyclingStart,CyclingEnd,MovieDelay);
        end;
        MovieDelay=GetSecs-preMovieTime;
    end;
    
    
    
end

% if this is a video-export run, save this frame to ims.cdata
% if saveVideo==1   
%     glueVideo('comp','videoname',0);
% end;
DateTimeStr=datestr(now,'dd-mm-yyyy_HH-MM');
if saveVideo==1   
    glueVideo('comp',[videoname '_' DateTimeStr],1);
end;

% save event times and stats to textfiles
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



%% Draw the fixation cross
Screen('DrawTexture', Win, FixCrossTexture);
End_of_Expmt = Screen('Flip', Win);

%%% INSERT CODE FOR DEACTIVATION PARALLEL PORT IF NECESSARY %%%
% Turn off Cogent
% if Emulate == 0
    % stop_cogent;
% end

%% Farewell screen
Screen('FillRect', Win, Parameters.Background, Rect);
DrawFormattedText(Win, 'Goodbye & Thank you!', 'center', 'center', Parameters.Foreground); 
Screen('Flip', Win);
WaitSecs(Parameters.TR * Parameters.Overrun);
ShowCursor;
Screen('CloseAll');

%% Save workspace
clear('Apperture', 'R', 'T', 'X', 'Y');
Parameters.Stimulus = [];
save(['Results\' Parameters.Session_name]);

%% Experiment duration
new_line;
ExpmtDur = End_of_Expmt - Start_of_Expmt;
ExpmtDurMin = floor(ExpmtDur/60);
ExpmtDurSec = mod(ExpmtDur, 60);
disp(['Cycling lasted ' num2str(ExpmtDurMin) ' minutes, ' num2str(ExpmtDurSec) ' seconds']);
new_line;
WaitSecs(1);
