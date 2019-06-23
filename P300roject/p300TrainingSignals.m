% This script uses calibration data to train an erp classifier. It also
% shows the spatial filters used and the signals per electrode per class
% (p300 or no p300). Then it shows a confusion matrix and the training
% accuracy.

% Connecting to the buffer
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
while ( isempty(hdr) || ~isstruct(hdr) || (hdr.nchans==0) ) % wait for the buffer to contain valid data
    try
        hdr = buffer('get_hdr', [], buffhost, buffport);
    catch
        hdr = [];
        fprintf('Invalid header info... waiting.\n');
    end
    pause(1);
end

% Configuration
capFile = 'cap_tmsi_mobita_32ch.txt';
overridechnm = 1; % capFile channel names override those from the header!
dname = 'calibration_data';
fname = 'clsfr';

load(dname);
% Train classifier
[clsfr, temp] = buffer_train_erp_clsfr(data, devents, hdr, 'spatialfilter',...
    'wht', 'freqband', [0 .3 10 12], 'badchrm', 0, 'capFile', capFile,...
    'overridechnms', overridechnm);
% Save the classifier
fprintf(1,'Saving clsfr to : %s',fname);
save(fname,'-struct','clsfr');
