function [Tv,Tu,R,W] = jt_reconvolution_cca(data,cfg)
%[Tv,Tu,R,W] = jt_reconvolution_cca(data,cfg)
%Applies reconvolution within a CCA to data returning the predicted 
%responses as templates, the estimated temporal responses to the individual 
%events as well as the spatial dynamics.
%
% INPUT
%   data = [struct] data structure:
%       .X   = [c m k]  data of channels by samples by trials
%       .y   = [1 k]    labels indicating class-index for each trial
%       .V   = [m p]    train sequences of samples by classes
%       .U   = [m q]    predict sequences of samples by classes
%       .Mv  = [e m p]  structure matrices of V
%       .Mu  = [e m q]  structure matrices of U
%   cfg = [struct] configuration structure:
%       .cca        = [str]  CCA method
%       .event      = [str]  type of decomposition event ('duration')
%       .L          = [1 r]  length of transient responses in samples (100)
%       .delay      = [int]  number of samples delay in signal (0)
%       .component  = [int]  CCA component to use (1)
%       .lx         = [flt]  regularization on data.X (1)
%                     [1 c]  regularization on data.X for each sample
%                     [str]  regularization on data.X with taper
%       .ly         = [flt]  regularization on Y (1)
%                     [1 L]  regularization on Y for each sample
%                     [str]  regularization on data.X with taper
%       .lxamp      = [flt]  amplifier for lx regularization penalties, i.e., maximum penalty (0.1)
%       .lyamp      = [flt]  amplifier for ly regularization penalties, i.e., maximum penalty (0.01)
%       .lyperc     = [flt]  relative parts of the taper that is regularized (.2)
%       .modelonset = [bool] whether or not to model the onset, uses L(end) as length (false)
%       .wraparound = [bool] whether or not to wrap responses around (false)
%
% OUTPUT
%   Tv = [m p] p predicted responses of m samples for V
%   Tu = [m q] q predicted responses of m samples for U
%   R  = [e 1] concattenated transient responses of e=sum(L) samples
%   W  = [c 1] spatial filter over c channels
%
% See also jt_reconvolution

% Defaults
if nargin<2||isempty(cfg); cfg=[]; end
cca         = jt_parse_cfg(cfg,'cca','qr');
event       = jt_parse_cfg(cfg,'event','duration');
L           = jt_parse_cfg(cfg,'L',100);
delay       = jt_parse_cfg(cfg,'delay',0);
component   = jt_parse_cfg(cfg,'component',1);
lx          = jt_parse_cfg(cfg,'lx',1);
ly          = jt_parse_cfg(cfg,'ly',1);
lxamp       = jt_parse_cfg(classifier.cfg,'lxamp',0.1);
lyamp       = jt_parse_cfg(classifier.cfg,'lyamp',0.01);
lyperc      = jt_parse_cfg(classifier.cfg,'lyperc',.2);
modelonset  = jt_parse_cfg(cfg,'modelonset',false);
wraparound  = jt_parse_cfg(cfg,'wraparound',false);

% Construct structure matrices
if ~isfield(data,'Mv') || ~isfield(data,'Mu')
    p = size(data.V,2);
    M = jt_structure_matrix(...
        [data.V data.U],...
        struct('L',L,'delay',delay,'event',event,'modelonset',modelonset,'wraparound',wraparound));
    data.Mv = M(:,:,1:p);
    data.Mu = M(:,:,p+1:end);
end

% Deconvolution
[R,W] = jt_decompose_cca(...
    data.X,data.Mv(:,:,data.y),...
    struct('cca',cca,'L',L,'component',component,'lx',lx,'ly',ly,'lxamp',lxamp,'lyamp',lyamp,'lyperc',lyperc,'modelonset',modelonset));

% Convolution
Tv = jt_compose_cca(data.Mv,R);
Tu = jt_compose_cca(data.Mu,R);
