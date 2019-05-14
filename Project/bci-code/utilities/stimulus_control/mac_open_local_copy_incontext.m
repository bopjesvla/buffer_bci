function mess = mac_open_local_copy_incontext(sourcen, targetn, machine, user, password, detach)
quote = char(39);
[pathstr, name, ext, versn]=fileparts(sourcen);
parsest = pathstr;
allWords = '';
while (any(parsest))
	[chopped,parsest] = strtok(parsest, '/');
	allWords = strvcat(allWords, chopped);
end
sourcefolder = strrep([pathstr '/'], '/', ':');
sourcefolder2 = strrep(sourcefolder, ':Volumes', '');
targetfolder = strrep(targetn, '/', ':');
targetfile = strrep([targetn chopped '/' name ext], '/', ':');

command1 = ['set source_folder to folder"' sourcefolder2 '"'];
command5 = ['set target_folder to folder"' targetfolder '"'];
command2 = ['tell application "Finder" of machine "eppc://' user ':' password '@' machine '"'];
command3 = 'duplicate source_folder to target_folder replacing yes';
command6 = ['open file "' targetfile '"'];
command4 = 'end tell';
if detach
	command7 = '&';
else
	command7 = '';
end
command = ['!osascript -e ' quote command2 quote ' -e ' quote command1 quote ' -e ' quote command5 quote ' -e ' quote command3 quote ' -e ' quote command6 quote ' -e ' quote command4  quote command7]
pause(1);
mess = evalc(command);

%mac_open_local_copy_incontext('/Volumes/BCI Stims/abc/Test/Test.txt',
%'AlexHD/Users/alexbrandmeyer/Desktop/', '131.174.202.70', 'alexbrandmeyer', 'password', 0)
