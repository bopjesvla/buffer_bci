function send_remote_key(machine, user, password, application, key)
quote = char(39);
command0 = ['tell application "Finder" of machine "eppc://' user ':' password '@' machine '" to do shell script "SEactivate.sh"'];
%script is in /usr/bin/ of target system
command1 = ['tell application "' application '" of machine "eppc://' user ':' password '@' machine '" to activate'];
command2 = ['tell application "System Events" of machine "eppc://' user ':' password '@' machine '" to key code ' num2str(key)];
command = ['!osascript -e ' quote command1 quote ' -e ' quote command2 quote]
precommand = ['!osascript -e ' quote command0 quote];
%
eval(precommand);
pause on;
pause(1);
eval(command);
% space bar = 49
% 0 = 29
%send_remote_key('mmmeegstim.nici.ru.nl', 'mmm', 'ememem', 'Logic Express', 49)  start
%send_remote_key('mmmeegstim.nici.ru.nl', 'mmm', 'ememem', 'Logic Express', 29) stop