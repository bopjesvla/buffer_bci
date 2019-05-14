function mess = mac_open_file(file,detach)
if nargin < 2, detach = 0; end
quote = char(39);
command1 = ['set filenm2 to POSIX file "' file '"'];
command2 = 'tell application "Finder" to open filenm2';
if detach 
    command3 = '&'; 
else
    command3 = '';
end
command = ['!osascript -e ' quote command1 quote ' -e ' quote command2 quote command3];
command
mess = evalc(command);

% mac_open_file('/Volumes/BCI Code/MaxMSP/BCI_Self_Paced.app')
% mac_open_file('/Volumes/MacintoshHD/test.lso');

