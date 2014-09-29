
%cedrus response box test

% on terminal: 
% cd /dev/
% ls
% find something like cu.usbserial... that name has to be put in line 10:

% set up the device to get a handle to interface with it
boxhandle = CedrusResponseBox('Open', '/dev/cu.usbserial-00002006')


%clear previous button presses
buttons = 1;
  while any(buttons(1,:))
    buttons = CedrusResponseBox('FlushEvents', boxhandle );
  end
  
  
% anything happening on that box?
evt = CedrusResponseBox('WaitButtonPress', boxhandle )


% e.g.
% evt = 
% 
%              raw: 144
%             port: 0
%           action: 1
%           button: 5
%         buttonID: 'middle'
%          rawtime: 942.8020
%     ptbfetchtime: 1.5582e+04
