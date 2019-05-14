
%% 256 cap
% filename = AdaptPathToPlatform('/Volumes/BCI code/electrode_positions/BioSemi_Cap_256.elp');
% addpath((genpath('/Volumes/BCI code/eeglab6/')));
% biosemilocs=readlocs(filename,'filetype', 'besa');
% X=[biosemilocs.X];
% Y=[biosemilocs.Y];
% Z=[biosemilocs.Z];
% labels = {biosemilocs.labels};

%% 64 cap
addpath '/Volumes/BCI code/Utilities/ElectrodePos/conversion/'
[cap_newc, cap_news] = readCap('/Volumes/BCI code/Utilities/ElectrodePos/caps/cap64.txt');
[cap] = cap2xyz(cap_newc)
X = cell2mat(cap(:,4))';
Y = cell2mat(cap(:,5))';
Z = cell2mat(cap(:,6))';
labels = {cap_news(:,1).label}';

%% get neighbors
CartesianCoordinates = [X; Y; Z]';
addpath '/Volumes/BCI code/Utilities/FindNeighbours/'
%slicedis = 0.1606; % note: this is specific to the BioSemi 256 electrode cap
slicedis=0.4189; % 5 slices: (120/5)/180*pi
[nbsvector,nbsmatrix] = NeighbourList(CartesianCoordinates, slicedis, 3);

% rotate head view 270 degrees in order to plot nose on top of the figure
clf;
PlotNeighbours(CartesianCoordinates,labels,nbsvector,pi*270/180);

