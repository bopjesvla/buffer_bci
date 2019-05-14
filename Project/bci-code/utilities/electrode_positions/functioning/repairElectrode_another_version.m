function [R, badr] = repairElectrode(data, threshold, neighbours, location)
%function to find bad electrodes based on the correlation with its
%neighbours and replaces these with a linear combination of the neighbours.
% This function doesnot
% incorporate length of the measurement, so this should be long enough.
%
% [R, badr] = badElectrode(data, threshold, neighbours, location)
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

% 'interpolated' measurement at all locations (rough)
y = neighbours*data;

% find correlations
for j = 1:size(data,1)
    ndata   = sqrt(data(j,:)*data(j,:)');
    ny      = sqrt(y(j,:)*y(j,:)');
    r(j)    = (data(j,:)*y(j,:)')/(ny*ndata);
end

%select bad 
badr = find(abs(r)<threshold);

%find the neighbours of these bad electrodes. If one of the neighbours is
%bad, use his neighbours.

%go for all the bad electrodes
for j = 1:length(badr)
    
    %the first badneighbour you are yourself 
    badn = badr(j);
    
    %keep track of processed electrodes. This is to determine for loops
    procelectr = badn;
    
    %as long as there are badneighbours, continue
    while(~isempty(badn))
        
        %if you have several bad neighbours, find their neighbours (wow)
        neighb = [];
        for k = 1:length(badn)
            neighb = union(neighb,find(neighbours(badn(k),:) == 1));
        end

        %are there any bad neighbours in this new set?
        badn = unique(intersect(badr, neighb));

        %remove the bad neighbours within the set (otherwise we loop) These
        %are already processed, so contained in procelectr.
        badn = unique(setdiff(badn, procelectr));
        
        %update the processed electrodes
        procelectr = unique(union(procelectr, neighb));
        
    end
    
    %the neighb that can be used for interpolation are the processed
    %electrodes minus the bad electrodes.
    N{j} = unique(setdiff(procelectr,badr));
end

% The interpolation is inv. prop. with the distance. Place this in 'repair
% matrix'
R = sparse(eye(size(neighbours)));
for j = 1:length(badr)
   
    %substract coordinates
    dist = location(N{j},:) - repmat(location(badr(j),:),length(N{j}),1);
    
    %calculate distance
    dist = sqrt(dist(:,1).^2 + dist(:,2).^2 + dist(:,3).^2);

    %take inverse
    invdist = 1./(dist);
    
    %take care that sum is one to make weighted average
    invdist = invdist./(sum(invdist));
    
    %place in the repair matrix
    R(badr(j),N{j}) = invdist;
    
    %don't contribute yourself
    R(badr(j),badr(j)) = 0;
end

    
    
