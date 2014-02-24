function [Session, Sess_name] = CurrentSession(Base_name)
%[Session, Sess_name] = CurrentSession(Base_name)
%
% Returns the number and name of the current session.
%

Session = 1;
Sess_name = [Base_name '_' num2str(Session)];

while exist(['Results\' Sess_name '.mat'])
    Session = Session + 1;
    Sess_name = [Base_name '_' num2str(Session)];
end

disp(['Running session: ' Sess_name]); disp(' ');