function mac_open_local_copy(sourcen, targetn, machine, user, password, detach)
quote = char(39);
[pathstr, name, ext, versn]=fileparts(sourcen);

targetfolder = strrep(targetn, '/', ':');
targetfile = strrep([targetn name ext], '/', ':');

command1 = ['set source_folder to POSIX file "' sourcen '"'];
command5 = ['set target_folder to "' targetfolder '"'];
command2 = ['tell application "Finder" of machine "eppc://' user ':' password '@' machine '"'];
command3 = 'duplicate source_folder to folder target_folder replacing yes';
command6 = ['open file "' targetfile '"'];
command4 = 'end tell';
if detach 
    command7 = '&'; 
else
    command7 = '';
end
    command = ['!osascript -e ' quote command2 quote ' -e ' quote command1 quote ' -e ' quote command5 quote ' -e ' quote command3 quote ' -e ' quote command6 quote ' -e ' quote command4  quote command7]

eval(command);
