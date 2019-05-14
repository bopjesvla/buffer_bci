function mess = mac_open_local_copy_incontext1(sourcen, targetn, machine, user, password, detach)
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
%sourcefile = [sourcefolder ':' name '.' ext];
command1 = ['set source_folder to folder"' sourcefolder2 '"'];
command2 = ['set target_folder to folder"' targetfolder '"'];
command3 = ['tell application "Finder" of machine "eppc://' user ':' password '@' machine '"'];
chkcomm1 = 'set file1 to false';
chkcomm2 = 'try';
chkcomm3 = ''; %'set info1 to info for source_folder';
%chkcomm3 = '';
chkcomm4 = 'set file1 to true';
chkcomm5 = 'end try';
chkcomm6 = 'if (not file1) then return "Error: source file does not exist';
chkcomm7 = 'set file2 to false';
chkcomm8 = 'try';
%chkcomm9 = ''
chkcomm9 = ''; %'set info2 to info for target_folder';
chkcomm10 = 'set file2 to true';
chkcomm11 = 'end try';
chkcomm12 = 'if (file1 and file2) then';
chkcomm13 = ''; %'if ((modification date of info1) > (modification date of info2)) then';
chkcomm14 = ''; %'duplicate source_folder to target_folder replacing yes';
chkcomm15 = ''; %'end if';
chkcomm16 = 'else if (file1 and not file2) then';
chkcomm17 = ''; %'duplicate source_folder to target_folder replacing yes';
chkcomm18 = 'end if';
command4 = ''; %['open file "' targetfile '"'];
%command4 = '';
command5 = 'end tell';
if detach 
    command6 = '&'; 
else
    command6 = '';
end
    command = ['!osascript -e ' quote command3 quote ' -e ' quote command1 quote ' -e ' quote command2 quote ...
               ' -e ' quote chkcomm1 quote ' -e ' quote chkcomm2 quote ' -e ' quote chkcomm3 quote ' -e ' quote chkcomm4 quote ...
               ' -e ' quote chkcomm5 quote ' -e ' quote chkcomm6 quote ' -e ' quote chkcomm7 quote ' -e ' quote chkcomm8 quote ...
               ' -e ' quote chkcomm9 quote ' -e ' quote chkcomm10 quote ' -e ' quote chkcomm11 quote ' -e ' quote chkcomm12 quote ...
               ' -e ' quote chkcomm13 quote ' -e ' quote chkcomm14 quote ' -e ' quote chkcomm15 quote ' -e ' quote chkcomm16 quote ...
               ' -e ' quote chkcomm17 quote ' -e ' quote chkcomm18 quote ' -e ' quote command4 quote ' -e ' quote command5  quote command6];

mess = evalc(command);

%mac_open_local_copy_incontext('/Volumes/BCI Stims/abc/Test/Test.txt',
%'AlexHD/Users/alexbrandmeyer/Desktop/', '131.174.202.70',
%'alexbrandmeyer', 'password', 0)