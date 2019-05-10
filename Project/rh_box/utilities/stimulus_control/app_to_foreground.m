function app_to_foreground(machine, user, password, application)
quote = char(39);
command0 = ['tell application "Finder" of machine "eppc://' user ':' password '@' machine '" to do shell script "SEactivate.sh"'];
%script is in /usr/bin/ of target system
command1 = ['tell application "' application '" of machine "eppc://' user ':' password '@' machine '" to activate'];
%command2 = ['tell application "System Events" of machine "eppc://' user ':' password '@' machine '" to key code ' num2str(key)];
%command = ['!osascript -e ' quote command1 quote ' -e ' quote command2 quote]
command = ['!osascript -e ' quote command1 quote]
precommand = ['!osascript -e ' quote command0 quote];
%
eval(precommand);
pause on;
pause(1);
eval(command);
