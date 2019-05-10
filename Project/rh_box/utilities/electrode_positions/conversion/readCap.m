function [cap_cell,cap_struct] = readCap(filename);
%this function reads in a capfile based on 
% the biosemi specification [label, latitude, azimuth]
% and returns an arrayed structure with all the information.
% This info can be used to convert to EEGlab coordinates (cap2eeglab)
% or to carthesian cordinats (cap2xyz).

%read file
[label, lt, az] = textread(filename,'%s %f %f');

%convert to radians
lt = lt/180*pi;
az = az/180*pi;

%make a cell array
cap_cell = label;
cap_cell(:,[2,3]) = num2cell([lt az]);

%make a struct array
cap_struct = cell2struct(cap_cell,{'label','latitude','azimuth'},2);