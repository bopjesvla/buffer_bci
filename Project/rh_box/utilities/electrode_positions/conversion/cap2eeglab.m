function [chanlocs] = cap2eeglab(cap_in);
% converts the biosemi coordinates to the chanlocs structure
% that is used in EEGlab. 
% I first go to carthesian coordinates, because the code was
% already there. If you want, please do it directly ;-)
%
% cap_in should be one of the results from readCap

%make it a cell array so we dson't need to loop:
if(~iscell(cap_in))
    cap_cell = struct2cell(cap_in)';
else
    cap_cell = cap_in;
end
nelectr = size(cap_cell,1);


%get latitude and azimuth
lat = [cap_cell{:,2}];
azi = [cap_cell{:,3}];

%remove them from the cell array, as eeglab does not use them
cap_cell(:,2:3) = [];


%go to carthesian
x = sin(lat).*sin(azi);
y = - sin(lat).*cos(azi);
z = cos(lat);

%go to spherical
[th, phi, r] = cart2sph(x, y, z);
sph_theta = th'*180/pi;
sph_phi = phi'*180/pi;

%go to topoplot coordinates
[chn, angl, rad] = sph2topo([(1:nelectr)', sph_phi, sph_theta], 1, 2);

%fill the cell array (can this be done better?, mat2cell is depricated)
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


