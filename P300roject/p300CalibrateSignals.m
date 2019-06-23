% This script sets up a buffer to save and record data for 600ms after
% every 'stimulus.rowtgtFlash' and 'stimulus.coltgtFlash' events and
% terminates upon receiving a 'stimulus.training' event with value 'end'.
% The recorded data is then saved to 'calibration_data.mat'.

% Setting paths and connecting to the buffer
try cd(fileparts(mfilename('fullpath'))); catch; end
try
    run ../matlab/utilities/initPaths.m
catch
    msgbox({'Please change to the directory where this file is saved'...
        'before running the rest of this code'}, 'Change directory');
end
try cd(fileparts(mfilename('fullpath'))); catch; end

buffhost = 'localhost'; buffport = 1972;
% Wait for the buffer to return valid header information
hdr=[];
while ( isempty(hdr) || ~isstruct(hdr) || (hdr.nchans==0) )
    try
        hdr=buffer('get_hdr', [], buffhost,buffport);
    catch
        hdr=[];
        fprintf('Invalid header info... waiting.\n');
    end
    pause(1);
end

% Set the real-time-clock to use
initgetwTime;
initsleepSec;

% Record and save the data
verb=1;
trlen_ms=600;
dname='calibration_data';

[data,devents,state] = buffer_waitData(buffhost ,buffport, [],...
    'startSet', {{'stimulus.rowtgtFlash', 'stimulus.coltgtFlash'}},...
    'exitSet', {'stimulus.training' 'end'},...
    'verb', verb,'trlen_ms', trlen_ms);
mi=matchEvents(devents, 'stimulus.training', 'end'); devents(mi)=[];
data(mi)=[]; % Remove the exit event
fprintf('Saving %d epochs to : %s\n', numel(devents), dname);
save(dname, 'data', 'devents');