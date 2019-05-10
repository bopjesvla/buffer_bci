function [subset,value] = jt_lcs_clustering(v,K,sync,dseg)
%[subset,value] = jt_lcs_clustering(v,k,a,d)
%
% INPUT
%   v    = [s p]  p variables of s samples
%   K    = [int]  number of variables in subset
%   sync = [bool] synchronous correlations (true)
%   dseg = [int]  length of segment (1)
%
% OUTPUT
%   subset = [1 n] ascending indices of the subset in v
%   value  = [flt] correlation value of the subset

p = size(v,2);
if nargin<3||isempty(sync); sync=true; end
if nargin<4||isempty(dseg); dseg=1; end

% Compute correlation
if sync
    c = jt_correlation(v,v);
else
    c = jt_correlation_loop(v,v,'shift',dseg);
    while length(size(c))>2
        c = squeeze(max(c,[],3));
    end
end

% Cluster
links = linkage(c,'single');
clusters = cluster(links,'maxclust',K)';

% Ignore diagonal
c(logical(eye(p))) = NaN;

% Define order of clusters
r = zeros(1,K);
for i = 1:K
    % Select cluster
    clust = clusters==i;
    % Select highest correlation
    r(i) = nanmax(nanmax(c(clust,~clust),[],2));
end
[~,order] = sort(r,'descend');

% Define the subset
rmv = false(1,p);
for i = 1:K
    % Select cluster
    clust = clusters==order(i);
    idx = find(clust);
    % Select representative
    [~,reprs] = nanmin(nanmax(c(clust,~clust&~rmv),[],2));
    reprs = idx(reprs);
    % Remove non-representatives        
    rmv(clust) = true;
    rmv(reprs) = false;
end

% Extract subset
subset = find(~rmv);

% Compute output
subset = sort(subset,'ascend');
value = nanmax(nanmax(c(subset,subset)));