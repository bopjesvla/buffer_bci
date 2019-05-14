function mess = mac_open_file_remote(filen, machine, user, password, detach)
quote = char(39);
command0 = 'try';
command1 = ['set filenm2 to POSIX file "' filen '"'];
command2 = ['tell application "Finder" of machine "eppc://' user ':' password '@' machine '"'];
command3 = 'open filenm2';
command4 = 'end tell';
command5 = 'return 0';
command6 = 'on error errMsg number errNum';
command7 = 'return "Error Number " & errNum & ": " & errMsg';
command8 = 'end try';
if detach 
    command9 = '&'; 
else
    command9 = '';
end
command = ['!osascript -e ' quote command0 quote ' -e ' quote command2 quote ' -e ' quote command1 quote ' -e ' quote command3 quote ' -e ' quote command4 quote ' -e ' quote command5 quote ' -e ' quote command6 quote ' -e ' quote command7 quote ' -e ' quote command8 quote command9];
mess = evalc(command);

% detach is a boolean (0 or 1) which tells matlab to continue execution
% immediately
% mac_open_file_remote('/Volumes/BCI Code/MaxMSP/BCI_Self_Paced.app',
% '131.174.203.244', 'mmm', 'ememem')


