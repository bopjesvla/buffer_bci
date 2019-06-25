% This script uses calibration data to train an erp classifier. It also
% shows the spatial filters used and the signals per electrode per class
% (p300 or no p300). Then it shows a confusion matrix and the training
% accuracy.

% Reconstruction of the header without buffer
% Note: should work for standard setting Mobita 32 channels. Changing data
% formats in other .m files will require changes in this configuration. 
clear hdr; % Errors if it already exists 
hdr.nSamples = 3984900;
hdr.nSamplesPre = 0;
hdr.nTrials = 718;
hdr.orig = struct(); 
hdr.nChans = 37; 
hdr.nEvents = 718; 
hdr.Fs = 250; 
hdr.data_type = 9;
hdr.bufsize = 70; 
hdr.label = num2cell(1:32); 

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
fprintf(1,'Saving clsfr to : %s\n',fname);
save(fname,'-struct','clsfr');