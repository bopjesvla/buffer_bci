function nrcontr = contribute(D,perc)
%function to determine which elements contribute to the value of the
%interpolated electrode.
%
% nrcontr = contribute(D,perc)
%
% D;    matrix of new_electr x electr
% perc: percentage
% 
% the output is the mean number of elements in the matrix D that contribute
% for perc percent to the value of the new interpolated electodes. This
% function is called to determine a smoothing function.

%sum of the rows is used to normalise
sumv = sum(D,2);

%how many sum to perc% of this value
D = sort(D,2,'descend');
D = cumsum(D,2)./(repmat(sumv,1,size(D,2)));

%determine howmany elements per row are used
contr = logical(D < perc);

%add these elements per row
sumv = sum(contr,2);

%get the mean
nrcontr = mean(sumv);