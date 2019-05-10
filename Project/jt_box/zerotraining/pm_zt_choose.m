function [classifier] = pm_zt_choose(label, classifier, X)
%[classifier] = pm_zt_choose(label,classifier)
% Update classifier covariance model for the given label. If the label is
% nan (no classification) nothing happens. 

% INPUT
%   label      = [int]    the label for the classified trial
%   classifier = [struct] classifier
%   X          = [c m]    current single-trial
% 
% OUTPUT
%   classifier  = [struct] updated classifier

% Select winning model
if classifier.cfg.runcovariance
    classifier.model.avg  = repmat(classifier.model.avg(:, label), 1, classifier.model.n);
    classifier.model.cov  = repmat(classifier.model.cov(:, :, label), 1, 1, classifier.model.n);
    classifier.filter     = classifier.filter(:, label);
    classifier.transients = classifier.transients(:, label);
else
    m = size(X, 2);
    s = size(classifier.stim.Mus, 2);
    M = cat(2, classifier.stim.Mus(:, :, label), repmat(classifier.stim.Muw(:, :, label), 1, ceil(m/s - 1), 1));
    M = M(:, 1:m, :);
    
    classifier.model.X    = cat(1, classifier.model.X, X');
    classifier.model.M    = cat(1, classifier.model.M, M');
    classifier.filter     = classifier.filter(:, label);
    classifier.transients = classifier.transients(:, label);
end

% Update templates
classifier.templates.Tus = jt_compose_cca(classifier.stim.Mus, classifier.transients);
classifier.templates.Tuw = jt_compose_cca(classifier.stim.Muw, classifier.transients);