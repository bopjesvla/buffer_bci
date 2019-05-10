function [classifier] = pm_zt_update(X, classifier)
%[classifier] = pm_zt_update(X,classifier,stoplearning,maxsamples)
% Updates the classifier covariance model and templates with new data. 
% 
% INPUT
%   X          = [c m]    data of channels by samples
%   classifier = [struct] classifier
%
% OUTPUT
%   classifier = [struct] updated classifier

% Variables
m = size(X, 2);
ds = floor(classifier.cfg.segmenttime * classifier.cfg.fs); 
t  = floor(m / ds);
s = size(classifier.stim.Mus, 2);

cfg = [];
cfg.L             = floor(classifier.cfg.fs .* classifier.cfg.L);
cfg.modelonset    = classifier.cfg.modelonset;
cfg.component     = classifier.cfg.component;
cfg.lx            = classifier.cfg.lx;
cfg.ly            = classifier.cfg.ly;
cfg.lxamp         = classifier.cfg.lxamp;
cfg.lyamp         = classifier.cfg.lyamp;
cfg.lyperc        = classifier.cfg.lyperc;
cfg.runcovariance = classifier.cfg.runcovariance;

% Extract data
if classifier.cfg.runcovariance
    % Use only latest segment for update
    idx = 1 + (t-1) * ds:t * ds;
    X = X(:, idx);
    M = cat(2,...
        classifier.stim.Mus(:, idx(idx <= s), :),...
        classifier.stim.Muw(:, mod(idx(idx > s) - 1, s) + 1, :));
else
    % Use full data stack
    M = cat(2, classifier.stim.Mus, repmat(classifier.stim.Muw, 1, ceil(m/s - 1), 1));
    M = M(:, 1:m, :);
end

% Update model
[classifier.model, classifier.filter, classifier.transients] = pm_recompose_cca(X, M, classifier.model, cfg);

% Update templates
classifier.templates.Tus = jt_compose_cca(classifier.stim.Mus, classifier.transients);
classifier.templates.Tuw = jt_compose_cca(classifier.stim.Muw, classifier.transients);