function [bad_v, bad_r] = findBadElectrode(data, threshold, neighbours, location)
%function to find bad electrodes based on the correlation with its
%neighbours 
% This function doesnot
% incorporate length of the measurement, so this should be long enough.
%
% [badr] = findBadElectrode(data, threshold, neighbours, location)
% 
% data  : the channels of the data (nrchan x sampletime)
% threshold: allowed corrlation, 1 = omit all, 0 = omit nothing: 
%   0.2 real bad gone
%   0.3 bad also gone
%   0.4 remove dubious electrodes
%   0.5 slightly dubious also found
% neighbours: matrix with neighbours (nrchan x nrchan, 1 if they are
% neighbours
% location: location of the data in xyz coordinates. (the neighbours matrix can
% be constructed with this matrix, but now this fucntion can be called repeatedly
% without recalculation the neighbours matrix)
%
% R is the repair matrix. data_repaired = R* data
% badr are the bad electrodes.
%
% always test the results with your data!
%R = sparse(eye(size(neighbours)));
%badr = [];

warning off

%detrend 
data = detrend(data')';

%get the extreme values in the variance (these are certainly bad)
v = var(data,[],2);
mv = median(v);
bad_v = find(v > 10*mv);

%omit these values
data(bad_v,:) = 0;

%lowpass filter the data to find the difference in trends
[b,a] = butter(4,30/128);
data = filter(b, a, data')';

%change neighbour matrix so that these extreme electrodes are not used
neighb = neighbours;
neighb(:,bad_v) = 0;

% 'interpolated' measurement at all locations (rough)
y = neighb*data;

% find correlations
for j = 1:size(data,1)
    ndata   = sqrt(data(j,:)*data(j,:)');
    ny      = sqrt(y(j,:)*y(j,:)');
    r(j)    = (data(j,:)*y(j,:)')/(ny*ndata);
end

%select bad 
bad_r = find(abs(r)<threshold);

warning on

if(0)
[rs ri]  = sort(abs(r));
for j=1:256
    plot(data' + 15*repmat((1:256),352,1),'bl')
    hold on
    plot(data(ri(1:j-1),:)' + 15*repmat(ri(1:j-1),352,1),'gr')
    plot(data(ri(j),:)' + 15*repmat(ri(j),352,1),'r')
    axis([0 350 0 2600]);
    title([num2str(j), ' ',num2str(rs(j)),' ',num2str(ri(j))]);
    pause
    hold off
end
end