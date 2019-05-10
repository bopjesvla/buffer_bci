function mac_open_file(logic_file)
quote = char(39);
command1 = ['set filenm2 to POSIX file "' logic_file '"'];
command2 = 'tell application "Finder" to open filenm2';
command = ['!osascript -e ' quote command1 quote ' -e ' quote command2 quote]
eval(command);
