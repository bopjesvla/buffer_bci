%example of interpolating and the such (take care that every thing is in
%the path!)

%%%%%%%%%%%%%
%% example 1: find 75 virtual electrodes that best cover our 256 setting

%load the cap (first output is cell array, second is structure)
[cap256c, cap256s] = readCap('cap256.txt');

%get xyz coordinates
[cap] = cap2xyz(cap256c);
xyz = cell2mat(cap(:,4:6));

%find new distribution, and interpolation matrix (R). The 0.94 gives the
%percentage that the neighbouring electrodes have to contribute)
[xyz75, R] = downsampleElectrodes(xyz, 75, 'interpolate', 500, 10, 0.94);

%get eeglab structure for plotting (second argument can be used for labels, use a cell array)
labels = num2cell(1:75);
chanlocs = xyz2eeglab(xyz75,labels);

%plot
topoplot(zeros(75,1),chanlocs,'electrodes','on');

%%%%%%%%%%%%%
%% example 2: go from 256 to 32 electrodes

%load the cap (first output is cell array, second is structure)
[cap256c, cap256s] = readCap('cap256.txt');
[cap32c, cap32s] = readCap('cap32.txt');

%get xyz coordinates
[cap] = cap2xyz(cap256c);
xyz256 = cell2mat(cap(:,4:6));
[cap] = cap2xyz(cap32c);
xyz32 = cell2mat(cap(:,4:6));

%find interpolation matrix
R = sphericalInterpolate(xyz32, xyz256, 0.95);

