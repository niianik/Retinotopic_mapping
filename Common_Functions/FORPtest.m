
% check first what is actually attached to this machine
[keyboardIndices, productNames, allInfos]=GetKeyboardIndices






%% testing FORP device (response box) at the scanner
% /Applications/Psychtoolbox/PsychHardware/FORP

%% if things don't work, restart matlab while device is plugged in %%
%
% % List of vendor IDs for valid FORP devices: [line 46, FORPCheck.m]
%     vendorIDs = [1240 6171]; % add device ID (932)


%%
% -- Check FORP button state, similar toKbCheck
[KeyPressed,EventTime] = FORPCheck()     
%                   for keyboards.
%
% -- Wait for FORP button press with timeout.
Seconds=5;
[KeyPressed,EventTime] = FORPWait([Seconds])  
%                    Similar to KbWait for keyboards.
%
% -- Clear queued FORP button presses.
FORPQueueClear(deviceNumber)
% unclear to me which deviceNumber that would be - likely keyboad index
% from GetKeyboardIndices.
