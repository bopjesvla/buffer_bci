function mess = KillRemoteApp(Appname, user, password, machine)
quote = char(39);
command1 = ['tell application "Finder" of machine "eppc://' user ':' password '@' machine '"'];
command2 = ['do shell script "killscript.sh ' Appname '"'];
command1and2and3 = ['tell application "' Appname '" of machine "eppc://' user ':' password '@' machine '"' ' to quit'];
command3 = 'end tell';
newcommand=['!osascript -e ' quote command1and2and3 quote];
command = ['!osascript -e ' quote command1 quote ' -e ' quote command2 quote ' -e ' quote command3 quote];
%mess = evalc(command);
mess = evalc(newcommand);

%KillRemoteApp("Logic", "mmm", "ememem", "mmmeegstim.nici.ru.nl") ...
%command to kill Logic on the stim computer (from the Server)

%KillRemoteApp("MATLAB", "matlab", "testbci", "mmmserver.nici.ru.nl") ...
%command to kill Matalb on the server (from the Stim computer)
