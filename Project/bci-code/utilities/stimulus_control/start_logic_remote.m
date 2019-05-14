function start_logic_remote(machine, user, password)
quote = char(39);
command0 = ['tell application "Finder" of machine "eppc://' user ':' password '@' machine '" to do shell script "SEactivate.sh"'];
command1 = ['tell application "Logic Express" of machine "eppc://' user ':' password '@' machine '" to activate'];
command2 = ['tell application "System Events" of machine "eppc://' user ':' password '@' machine '" to key code 49'];
command = ['!osascript -e ' quote command0 quote ' -e ' quote command1 quote ' -e ' quote command2 quote]
% 
eval(command);
