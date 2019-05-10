function [results] = jt_tmc_cv(data, cfg, n_folds, cvswitch)
%[results] = jt_tmc_cv(data, cfg, n_folds, cvswitch)
% Cross-validation to validate classification performance.
%
% INPUT
%   data = [struct] data structure:
%       .X   = [c m k]  data of c channels, m samples and k trials
%       .y   = [1 k]    labels of k trials
%       .V   = [s p]    trained sequences of s samples and p codes
%   cfg      = [struct] classifier configuration structure, see jt_tmc_train
%   n_folds  = [int]    number of folds (10)
%   cvswitch = [bool]   switch train and test folds (false)
%
% OUTPUT
%   results = [struct] results structure
%       .p = [1 n] accuracies for each fold
%       .t = [1 n] trial-lengths for each fold
%       .d = [1 n] data-lenghts for each fold

% Defaults
if nargin<2||isempty(cfg); cfg=[]; end
if nargin<3||isempty(n_folds); n_folds=10; end
if nargin<4||isempty(cvswitch); cvswitch=false; end
cfg.verbosity = 0;
cfg.subsetU = cfg.subsetV;
cfg.layoutU = cfg.layoutV;
cfg.online = false;

% Fold data
cv = cvpartition(numel(data.y), 'Kfold', n_folds);

% Loop over folds
results.p = zeros(1, n_folds);
results.t = zeros(1, n_folds);
results.d = zeros(1, n_folds);
for i_fold = 1:n_folds

    % Assign folds
    if cvswitch
        trnidx = cv.test(i_fold);
        tstidx = cv.training(i_fold);
    else
        trnidx = cv.training(i_fold);
        tstidx = cv.test(i_fold);
    end

    % Train classifier
    classifier = jt_tmc_train(struct('X', data.X(:, :, trnidx), 'y', data.y(trnidx), 'V', data.V, 'U', data.V), cfg);
    
    % Apply classifier
    [labels, ret] = jt_tmc_apply(classifier, data.X(:, :, tstidx));
    results.p(i_fold) = mean(labels == data.y(tstidx));
    results.t(i_fold) = mean(ret.t);
    results.d(i_fold) = mean(ret.d);
end