function [keysPressed, timeStamp, RT] = waitForTrigger(keyboard)
% [keysPressed timeStamp] = waitForTrigger()
%
% waits for 'keyboard' input from mri scanner
%
% keyboard is the index of the keyboard to use
%   found with  keyboard=GetKeyboardIndices();
%               keyboard=keyboard(end);
%
%   tt      trigger pulse

%
% Niia Nikolova
% 08/2014


if ~exist('keyboard','var')
    keyboard=GetKeyboardIndices();
    keyboard=keyboard(end);
end

%disable output to the command window
ListenChar(2);


keyIsDown = 0;
key = '';
keysPressed = [];
startTime = GetSecs;  %read the current time on the clock
  
while ~(strcmp(keysPressed,'tt'))  
         
    [ keyIsDown, timeSecs, keyCode ] = KbCheck(keyboard);  %read the keyboard  

    if keyIsDown

        if iscell(key)
            key=key{end};
        end

        %determine which key was pressed
        key = KbName(keyCode);

        if strcmp(key, 't')

            keysPressed = [keysPressed, key];
            timeStamp = timeSecs;
            %clear the keyboard buffer 
            while KbCheck; end

        end
    end
end


%calculate the reaction time
RT = timeStamp-startTime;

ListenChar(0);
end