function [Tv,Tu,R] = jt_reconvolution(data,cfg)
%[Tv,Tu,R] = jt_reconvolution(data,cfg)
%Applies reconvolution to data returning the predicted responses as
%templates and the estimated responses to the individual events.
%
% INPUT
%   data = [struct] data structure:
%       .X   = [c m k]  data of channels by samples by trials
%       .y   = [1 k]    labels indicating class-index for each trial
%       .V   = [m p]    train sequences of samples by classes
%       .U   = [m q]    predict sequences of samples by classes
%       .Mv  = [m e p]  structure matrices of V
%       .Mu  = [m e q]  structure matrices of U
%   cfg = [struct] configuration structure:
%       .L          = [1 r] length of transient responses in samples (100)
%       .event      = [str] type of decomposition event ('duration')
%       .delay      = [1 r] positive delay of each event start (0)
%       .modelonset = [bool] whether or not to model the onset, uses L(end) as length (false)
%       .wraparound = [bool] whether or not to wrap responses around (false)
%
% OUTPUT
%   Tv = [c m p] p predicted responses of c channels and m samples for V
%   Tu = [c m q] q predicted responses of c channels and m samples for U
%   R  = [c e]   concattenated transient responses of e=sum(L) samples and c channels

% Defaults
if nargin<2||isempty(cfg); cfg=[]; end
L           = jt_parse_cfg(cfg,'L',100);
event       = jt_parse_cfg(cfg,'event','duration');
delay       = jt_parse_cfg(cfg,'delay',0);
modelonset  = jt_parse_cfg(cfg,'modelonset',false);
wraparound  = jt_parse_cfg(cfg,'wraparound',false);

% Construct structure matrices
if ~isfield(data,'Mv') || ~isfield(data,'Mu')
    p = size(data.V,2);
    M = jt_structure_matrix(...
        [data.V data.U],...
        struct('L',L,'event',event,'modelonset',modelonset,'wraparound',wraparound,'delay',delay));
    data.Mv = M(:,:,1:p);
    data.Mu = M(:,:,p+1:end);
end

% Deconvolution
R = jt_decompose(data.X,data.Mv(:,:,data.y));

% Convolution
Tv = jt_compose(data.Mv,R); 
Tu = jt_compose(data.Mu,R); 