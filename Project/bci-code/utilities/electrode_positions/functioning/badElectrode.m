function [badr, r] = badElectrode(data, threshold, neighbours)
%function to find bad electrodes based on the correlation with its
%neighbours. Close electrods should give similar measurements. This function doesnot
%incorporate length of the measurement, so this should be long enough.
%
% [badr, r] = badElectrode(data, threshold, neighbours)
% 
% data  : the channels of the data (nrchan x sampletime)
% threshold: allowed corrlation, 1 = omit all, 0 = omit nothing: 
%   0.2 real bad gone
%   0.3 bad also gone
%   0.4 remove dubious electrodes
%   0.5 slightly dubious also found
% neighbours: matrix with neighbours (nrchan x nrchan, 1 if they are
% neighbours
%
% always test the results with your data!


%first de-tred sothat the offset and linear trends don't do damage
data = (detrend(data'))';

% 'interpolated' measurement at all locations
y = neighbours*data;

% find correlations
for j = 1:size(data,1)
    ndata   = sqrt(data(j,:)*data(j,:)');
    ny      = sqrt(y(j,:)*y(j,:)');
    r(j)    = (data(j,:)*y(j,:)')/(ny*ndata);
end

%select bad 
badr = find(abs(r)<threshold);