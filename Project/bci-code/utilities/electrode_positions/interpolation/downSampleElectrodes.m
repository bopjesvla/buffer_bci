function [electr, R] = downsampleElectrodes(loc, nelectr, type, Niter, Nrep, perc)
%
% Function to downsample EEG electrodes. 
%
%downSampleElectrodes(loc, nelectr, type)
%
% loc:  location file in (xyz) coordinates
% nelectr:  number of new electrodes
% type:     how to downdate. This can be:
%          'interpolate'   A interpolation matrix is returned by which
%                          the measurements of the new 'electrode' can be
%                          found. The new electrode is placed at the
%                          centroid of the combined electrodes.
%          'downdate'      Returns the electrodenumbers that are evenly spread 
%                          around the scalp. No interpolation. 
%          'downdateInterpolate'    Returns the electrodenumbers that are
%                           evenly spread around the scalp and returns an
%                           interpolation matrix
%          'sets'          Returns several sets of the downdated matrix. This can
%                          be used to run multiple ICA algorithms on
%                          downdated data and then combine the results
% Niter:    number of iterations to find the electrodes
% Nrep:     number of times the iteration scheme is started afresh. This is
%           usefull it get stuck in a local minimum
% perc:     percentage of interpolated value contributed by the elements in
%           the cluster. (0 < perc 1) The larger the value, the more local
%           the interpolation. I use 0.75 .. 0.9

%get some numbers
[nelectr_old, ncoord] = size(loc);

%First cluster the data in the specified regions. By use of the cosine distance, the 
%values are mapped ot a sphere
try
    [IDX, C, sumd, D] = kmeans(loc,nelectr,'maxiter', Niter ,'replicates',Nrep,'distance','cosine');
catch
    fprintf('%s',lasterr);
    error('Cannot get the correct kmeans file. It should be the one provided by statistics toolbox. \n not the one from the statistical pattern recognition toolbox');
end

switch type
    case 'interpolate'
        fprintf('returns interpolation matrix and centroid positions.\n');
        
        %give the new electrode position
        electr = C;
        
        %call the spherical interpolation scheme
        R = sphericalInterpolate(electr, loc, perc);
        
    case 'downdate'
        fprintf('returning electrodes closest to centroids\n');

        %allocate memory for interpolation matrix
        R = zeros(nelectr, nelectr_old);
        
        %find closest electrode per cluster
        for j =1:nelectr
            [weg, electr(j)] = min(D(:,j));   
            R(j,electr(j)) = 1;
        end  
        
    case 'downdateInterpolate'
        fprintf('returning electrodes closest to centroids and give interpolation matrix\n');

        %find closest electrode per cluster
        for j =1:nelectr
            [weg, electr(j)] = min(D(:,j));   
        end  
        
        %find interpoloation matrix
        R = sphericalInterpolate(loc(electr,:),loc, perc);
                
     case 'sets'
        fprintf('return different possible electrode selections\n');
        
        % no interpolation matrix is returned
        R = 0;
        
        %first set is the electrodes closest to the centroid
        for j =1:nelectr
            [weg, electr(j,1)] = min(D(:,j));   
        end  
        
        % use an indx vector that stores the original numbering. This is
        % needed because elements will be removed.
        indx = (1:nelectr_old)';
        
        %remove these electrodes from the location var and index to keep original numbering.
        loc(electr(:,1),:) = [];
        indx(electr(:,1)) = [];
        
        %find new electrodes, as long as there are enough
        k = 1;
        while(length(indx) >= nelectr)
            
            %updat the run var.
            k = k + 1;
            
            %find new clusters
            [IDX, C, sumd, D] = kmeans(loc,nelectr,'maxiter', Niter ,'replicates',Nrep,'distance','cosine');
                      
            %find closest electrodes
            for j =1:nelectr
                [weg, tempElectr(j)] = min(D(:,j));   
            end
                        
            %place the orginal number is the electr
            electr(:,k) = indx(tempElectr);
            
            %omit the electrodes
            loc(tempElectr,:) = [];
            indx(tempElectr) = [];
                   
        end
               
    otherwise
        error('type shoud be: interpolate, downdate or sets\n');
end
