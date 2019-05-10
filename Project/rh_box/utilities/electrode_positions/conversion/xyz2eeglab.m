function [chanlocs] = xyz2eeglab(xyz,labels);
% converts xyz coordinates to a chanlocs structure (to use with topoplot)
% that is used in EEGlab. The labels will just be the numbers if no cell
% array is given as the second argument

%get number of electrodes
nelectr = size(xyz,1);

%use only numbers if no labels are given
if(nargin==1)
    labels = num2cell(1:nelectr);
end

%go to carthesian
x = xyz(:,1);
y = xyz(:,2);
z = xyz(:,3);

%go to spherical
[th, phi, r] = cart2sph(x, y, z);
sph_theta = th*180/pi;
sph_phi = phi*180/pi;

%go to topoplot coordinates
[chn, angl, rad] = sph2topo([(1:nelectr)', sph_phi, sph_theta], 1, 2);

%fill the cell array (can this be done better?, mat2cell is depricated)
cap_cell(1:nelectr,1) = labels;
cap_cell(:,2) = num2cell(x)';
cap_cell(:,3) = num2cell(y)';
cap_cell(:,4) = num2cell(z)';
cap_cell(:,5) = num2cell(sph_theta);
cap_cell(:,6) = num2cell(sph_phi);
cap_cell(:,7) = num2cell(ones(1,nelectr));
cap_cell(:,8) = num2cell(angl);
cap_cell(:,9) = num2cell(rad);
cap_cell(:,10) = num2cell(chn);

%convert to struct
chanlocs = cell2struct(cap_cell,{'labels','X','Y','Z','sph_theta','sph_phi','sph_radius','theta','radius','urchan'},2);


