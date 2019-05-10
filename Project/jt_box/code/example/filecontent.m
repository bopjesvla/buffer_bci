% mgold_61_6521_flip_balanced.mat
%  original file with modulate goldcodes
%  
% mgold_61_6521_flip_balanced.txt
%  original file in text format 
%  
% mgold_61_6521_flip_balanced_align_60.txt
%  codes timeshifted to start with run of 1s and end with run of 0s, worse correlation in stim domain: test if worse in practice.
%  
% mgold_61_6521_flip_balanced_trunc_60.txt
%  codes truncated to contain only a short pulses, more data to fit one event, but less difference between codes
% 
% mgold_61_6521_flip_balanced_60at120.txt
%  double rows, stimuli will appear at 60 (like we used to) when framerate is 120: good hardware/software test for 120
%  
% mgold_61_6521_flip_balanced_90at120resample.txt
%  simulate 90 hz, contains 3 events (1,2,3 bits long), contains LF (111000) (20 hz)and HF (10) (60 hz) spectral content
%  
% mgold_61_6521_flip_balanced_90at120raw.txt
%  simulate 90 hz, contains 2 events (1, 3 bits), 60,40,30,24 hz spectrum
% 
% mgold_61_6521_flip_balanced_90at120.txt
% simulate 90 hz, contains 2 events (1, 3 bits), HF removed 40,30,24 hz spectrum


% test 1, load all text files and check presentation (allign, trunc, 90),
% for perception

% test 2, with BCI
% 1 base case 'mgold_61_6521_flip_balanced' at 60
% 2 should be same as 'mgold_61_6521_flip_balanced_60at120' at 120 (120 ok) (train and test)
% 3 compare mgold_61_6521_flip_balanced_trunc_60 at 60, (1 event) with base (train and test)
% 4 confirm worse 'mgold_61_6521_flip_balanced_align_60' at 60, (shift codes) than base (train)

% 5 test 'mgold_61_6521_flip_balanced_90at120' at 120 (train and test)
% 6 compare 5 with 'mgold_61_6521_flip_balanced_90at120raw' (train and test) (wider spectrum)
% 7 compare 5 with 'mgold_61_6521_flip_balanced_90at120resample' (train and test) (3 events)

