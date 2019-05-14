function [xyz, labels] = eeglab2xyz(chanlocs);
%this function reads in uses the chanlocs structure from EEGlab, 
%  most often EEG.chanlocs, and converts the xyz positions, and a label
%  cell array. 
% this function can be used to find the stuff you want to omit, and go back
% to a eeglab structure with xyz2eeglab. 


%get our info out the structure
x = [chanlocs.X];
y = [chanlocs.Y];
z = [chanlocs.Z];
labels = {chanlocs.labels};

%put it in a cell. The original cap 
xyz = [x(:) y(:) z(:)];
