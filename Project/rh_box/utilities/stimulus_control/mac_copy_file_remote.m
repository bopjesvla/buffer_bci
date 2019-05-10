function mac_copy_file_remote(sourcen, targetn, machine, user, password)
quote = char(39);
targetn2 = strrep(targetn, '/', ':');

command1 = ['set source_folder to POSIX file "' sourcen '"'];
command5 = ['set target_folder to "' targetn2 '"'];
command2 = ['tell application "Finder" of machine "eppc://' user ':' password '@' machine '"'];
command3 = 'duplicate source_folder to folder target_folder replacing yes';
command4 = 'end tell';
command = ['!osascript -e ' quote command2 quote ' -e ' quote command1 quote ' -e ' quote command5 quote ' -e ' quote command3 quote ' -e ' quote command4 quote];
eval(command);

% mac_copy_file_remote('/Volumes/BCI Stims/Channels.txt', '/AlexHD/Users/alexbrandmeyer/Desktop/', '131.174.202.70', 'alexbrandmeyer', 'newera07')