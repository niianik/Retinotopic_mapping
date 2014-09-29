
%% IOPort test to listen to scanner trigger
% 
% IOPort - A Psychtoolbox driver for general port I/O:
% 
% 
% General information:
% 
% version = IOPort('Version');
% oldlevel = IOPort('Verbosity' [,level]);
% 
% General commands for all types of input/output ports:
% 
% IOPort('Close', handle);
% IOPort('CloseAll');
% [nwritten, when, errmsg, prewritetime, postwritetime, lastchecktime] = IOPort('Write', handle, data [, blocking=1]);
% IOPort('Flush', handle);
% [data, when, errmsg] = IOPort('Read', handle [, blocking=0] [, amount]);
% navailable = IOPort('BytesAvailable', handle);
% IOPort('Purge', handle);
%
% Commands specific to serial ports:
% 
% [handle, errmsg] = IOPort('OpenSerialPort', port [, configString]);
% IOPort('ConfigureSerialPort', handle, configString);

% on terminal: 
% cd /dev/
% ls
% find something like cu.usbserial... that name has to be used to get a handle on the device:

% set up the device to get a handle to interface with it
[TriggerPulseHandle, errmsg] = IOPort('OpenSerialPort', '/dev/cu.usbserial...');% [, configString]);

% listening for a pulse
[data, when, errmsg] = IOPort('Read', TriggerPulseHandle);% [, blocking=0] [, amount]);

%
IOPort('Close', TriggerPulseHandle);


