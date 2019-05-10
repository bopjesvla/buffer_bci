function [subset,value] = jt_lcs_random(v,K,option)
%[subset,value] = jt_lcs_random(x,n,option)
%Random subset.
%
% INPUT
%   v = [t m] t samples of m variables
%   K = [int] number of variables in subset
%
% OPTIONS
%   option = [str] lock|shift correlations (lock)
%
% OUTPUT
%   subset = [1 n] positions of the subset in x
%   value  = [flt] correlation value of the subset

if nargin<3||isempty(option); option='fix'; end;
numvar = size(v,2);
if K>numvar; error('x does not hold n variables!'); end

% Compute correlations
correlations = jt_correlation(v,v,option);
correlations = max(correlations,[],3);
correlations(logical(eye(numvar))) = NaN; %ignore diagonal

% Select subset
index = randperm(numvar);

% Compute output
subset = index(1:K);
value = nanmax(nanmax(correlations(subset, subset)));