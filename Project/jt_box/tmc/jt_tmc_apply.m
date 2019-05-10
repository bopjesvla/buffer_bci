function [labels, results, classifier] = jt_tmc_apply(classifier, X, active_codes, locations)
%[labels, results, classifier] = jt_tmc_apply(classifier, X, active_codes)
%Applies the classifier to single-trial or multi-trial data.
%
% INPUT
%   classifier   = [struct] classifier structure
%   X            = [c m k]  data of channels by samples by trials
%   active_codes = [n 1]    n booleans, one for each code in U: currently active codes at stimulus presentation scene (ones(n, 1))
%   locations    = [n 1]    n integers, one for each code in U: current locations of the codes (ones(n, 1))
%
% OUTPUT  
%   labels  = [k 1]    the predicted labels, NaN if below threshold,
%                      negative label if below threshold and not forced
%                      stop
%   results = [struct] addition results of the classifier
%       .r   = [n k] similarity matrix of all n templates by k trials
%       .t   = [1 k] trial duration (i.e., forward step) in seconds of k trials
%       .d   = [1 k] trial length (i.e., backward step) in seconds of k trials
%       .v   = [1 k] certainty at classification for k trials
%                       is similarity margin (1st-2nd) if margin stopping model
%                       is probability if beta stopping model
%   classifier = [struct] updated classifier

% Initialize active codes to all active if not specified
n = size(classifier.stim.Mus, 3);
if nargin < 3 || isempty(active_codes)
   active_codes = true(n, 1);
elseif length(active_codes) ~= n
   [a, b] = size(active_codes);
   error('The size of ''active_codes'' [%d,%d], does not match the number of actual classes [%d]!', a, b, n);
end
if nargin < 4 || isempty(locations)
    locations = ones(n, 1);
elseif length(locations) ~= n
   [a, b] = size(locations);
   error('The size of ''locations'' [%d,%d], does not match the number of actual classes [%d]!', a, b, n);
end

% Set datatime to nan if not specified
if ~isfield(classifier, 'datatime')
    classifier.datatime = NaN;
end

% Make data double precision always
X = double(X);

% Classify
if classifier.cfg.online
    [labels, results, classifier] = jt_tmc_apply_online(classifier, X, active_codes, locations);
else
    [labels, results, classifier] = jt_tmc_apply_offline(classifier, X, active_codes, locations);
end

%--------------------------------------------------------------------------
% Match templates with single trials
% Note: this pipeline is meant for online use, because it operates on
% individual single-trials. It is optimized to do computations as fast as
% possible, by utilizing the fact that we always will only classify one
% trial only. 
function [label, result, classifier] = jt_tmc_apply_online(classifier, X, active_codes, locations)

    % Quit if multiple trials provided to single-trial pipeline
    if size(X, 3) > 1
        error('The online pipeline cannot be applied to multiple trials! Instead use cfg.online=false, or manually loop over trials instead.');
    end
    
    % Initialize return variables
    label = NaN;
    result = struct('r', 0, 't', 0, 'd', 0, 'v', 0, 'datatime', 0);
    
    %--------------------------------------------------------------------------
    % Set some variables
    
    [c, m] = size(X); % number of channels and data samples
    if isnan(classifier.datatime)
        mh = m;
    else
        mh = round(classifier.datatime * classifier.cfg.fs); % number of data samples recorded in total (if circular buffer used, mh can be larger than m loosing synchrony at sample 0)
    end
    d = floor(classifier.cfg.segmenttime * classifier.cfg.fs); % number of samples in a segment
    t = floor(m / d); % number of segments in the data, or number of current segment
    nl  = numel(unique(locations)); % number of unique locations
    
    % Skip classification if not yet a full datasegment is collected
    if t == 0 || mod(m / d, 1) > 0
        return
    end
    
    minsegments = floor(classifier.cfg.mintime / classifier.cfg.segmenttime);
    maxsegments = floor(classifier.cfg.maxtime / classifier.cfg.segmenttime);
    minbacksegments = floor(classifier.cfg.minbacktime / classifier.cfg.segmenttime);
    maxbacksegments = floor(classifier.cfg.maxbacktime / classifier.cfg.segmenttime);
    frstminsegments = floor(classifier.cfg.frstmintime / classifier.cfg.segmenttime);
    
    %--------------------------------------------------------------------------
    % Unsupervised model update
    
    % Unsupervised: update classifier
    if ~classifier.cfg.supervised
        classifier = pm_zt_update(X, classifier);
    end
    s = size(classifier.templates.Tus, 1); % number of template samples
    
    % Unsupervised: check if this is the first trial
    if ~classifier.cfg.supervised && classifier.model.count < classifier.cfg.frstmintime * classifier.cfg.fs
        firsttrial = true;
    else
        firsttrial = false;
    end
    
    %--------------------------------------------------------------------------
    % Spatially filter data
    
    % Spatially filter data
    if classifier.cfg.supervised
        fX = zeros(m, nl);
        for i = 1:nl
            fX(:, i) = tprod(X, [-1 1 2], classifier.filter(1 + (i-1) * c:i * c), [-1 3], 'n');
        end
    else
        if nl > 1
            error('Error: unsupervised is not yet compatible with more than one location!')
        end
        fX = reshape(tprod(X, [-1 1 2], classifier.filter, [-1 3], 'n'), m, []); % [m n]
    end
    
    %--------------------------------------------------------------------------
    % Compute correlations
    
    if classifier.cfg.runcorrelation
        
        error('Not implemented yet!');
        
        % Extract data: last segment of single-trial
        idx = 1 + (t-1) * d:t * d;
        fX = fX(idx, :);
        T = cat(1, ...
            classifier.templates.Tus(idx(idx <= s), :), ...
            classifier.templates.Tuw(mod(idx(idx > s) - 1, s) + 1, :));

        % Update correlation state 
        if t <= 1; classifier.state = []; end
        if strcmpi(classifier.cfg.method, 'bwd')
            [r, classifier.state] = jt_correlation(T, fX, struct('method', 'bwd', 'lenseg', d, 'maxfwd', maxsegments, 'minbwd', minbacksegments, 'maxbwd', maxbacksegments, 'runcor', true), classifier.state);
            r = r(:, :, 1:t);
        else
            [r, classifier.state] = jt_correlation(T, fX, struct('method', 'fix', 'lenseg', d, 'maxfwd', maxsegments, 'runcor', true), classifier.state);
            r = r(:, :, t);
        end
        
    else
        
        % Extract data: remove front part lost due to circular buffer
        idx = 1 + (mh - m):mh;
        T = cat(1, ...
            classifier.templates.Tus(idx(idx <= s), :), ...
            classifier.templates.Tuw(mod(idx(idx > s) - 1, s) + 1, :));
        
        % Compute correlation
        if classifier.cfg.supervised
            r = cell(nl, 1);
            for i = 1:nl
                if strcmpi(classifier.cfg.method, 'bwd')
                    r{i} = jt_correlation(T(:, locations==i), fX(:, i), struct('method', 'bwd', 'lenseg', d, 'maxfwd', t, 'minbwd', min(t, minbacksegments), 'maxbwd', min(t, maxbacksegments), 'runcor', false)); % [n 1 b]
                else
                    r{i} = jt_correlation(T(:, locations==i), fX(:, i), struct('method', 'fix', 'lenseg', d, 'maxfwd', t, 'runcor', false)); % [n 1]
                end
            end
            r = cat(1, r{:});
        else
            if strcmpi(classifier.cfg.method, 'bwd')
                r = jt_correlation(T, fX, struct('method', 'bwd', 'lenseg', d, 'maxfwd', t, 'minbwd', min(t, minbacksegments), 'maxbwd', min(t, maxbacksegments), 'runcor', false)); % [n 1 b]
            else
                r = jt_correlation(T, fX, struct('method', 'fix', 'lenseg', d, 'maxfwd', t, 'runcor', false)); % [n 1]
            end
        end
    end
    
    %--------------------------------------------------------------------------
    % Usupervised some additional administration
    
    % Unsupervised: select auto-models
    if ~classifier.cfg.supervised
        nbwd = size(r, 3);
        tmp = r;
        r = zeros(size(r, 1), 1, nbwd);
        for ibwd = 1:nbwd
            r(:, 1, ibwd) = diag(tmp(:, :, ibwd));
        end
    end
    
    % Unsupervised: set targeted accuracy of first trial
    if ~classifier.cfg.supervised && firsttrial
        accuracy = classifier.cfg.frstaccuracy;
    else
        accuracy = classifier.cfg.accuracy;
    end
    
    % Correct accuracy for false positives within multiple tests
    accuracy = accuracy ^ (1 / maxsegments);
    
    %--------------------------------------------------------------------------
    % Confidences
    
    p = zeros(size(r));
    
    % Confidences based on the margin model
    if strcmp(classifier.cfg.method, 'fix')
        p = r;
        
    elseif strcmp(classifier.cfg.stopping, 'margin')
        
        % Compute confidences for each backward step
        nbwd = size(r, 3);
        for ibwd = 1:nbwd

            ri = r(:, :, ibwd);
            
            % Compute second max
            val = sort(ri, 1, 'descend');
            ri_smax = val(2);
            
            % Compute difference scores
            dri = ri - ri_smax;
            
            % Compute distances to the margin
            p(:, :, ibwd) = dri - classifier.margins(t);
            
        end
    
    % Confidences based on the beta model
    elseif strcmp(classifier.cfg.stopping, 'beta')
    
        % Convert to a range of [0 1] for Beta distribution
        rh = (r + 1) / 2;

        % Compute confidences for each backward step
        nbwd = size(r, 3);
        for ibwd = 1:nbwd

            rhi = rh(:, :, ibwd); % [n 1]
            
            % Trick to ignore inactive codes but to keep dimensions
            rhia = rhi;
            rhia(~active_codes, :) = -1;

            % Compute max and non-max correlations within ative codes
            [~, i_rhi_max] = max(rhia);
            rhi_non_max = rhi(~ismember(1:numel(rhi), i_rhi_max));

            % Fit a beta distribution to the non-max correlations
            beta = betafit(rhi_non_max, 0.05);

            % Compute probability of the correlations
            p(:, :, ibwd) = betacdf(rhi, beta(1), beta(2)) .^ numel(rhi);

        end
        
    elseif strcmp(classifier.cfg.stopping, 'ttest')

        error('not implemented yet');
        % Probably works only with inner products instead of correlations
        
        % Compute confidences for each backward step
        nbwd = size(r, 3);
        for ibwd = 1:nbwd

            ri = abs(r(:, :, ibwd));  % [n 1]
            
            % Trick to ignore inactive codes but to keep dimensions
            ria = ri;
            ria(~active_codes, :) = -1;

            % Compute max and non-max correlations within ative codes
            [~, i_ri_max] = max(ria);
            ri_non_max = ri(~ismember(1:numel(ri), i_ri_max));

            % Compute sample deviation
            mu = mean(ri_non_max);
            sigma = std(ri_non_max);
            
            % Compute z scores
            z = (ri - mu) / (sigma / sqrt(numel(ri)));

            % Compute probability of the correlations
            p(:, :, ibwd) = 1 - normcdf(z);
        end
        
    else
        
        error('Unknown stopping method: %s', classifier.cfg.stopping);
        
    end
    
    %--------------------------------------------------------------------------
    % Classifiction
    
    % Trick to ignore inactive codes but to keep dimensions
    pa = p;
    pa(~active_codes, :, :) = -1;
    
    % Maximize confidence over backward step within active codes
    [p_max, p_max_back] = max(pa, [], 3);
    
    % Maximize confidence over classes within active codes
    [p_max, p_max_class] = max(p_max, [], 1);
    
    % Dynamic stopping
    if strcmp(classifier.cfg.method, 'fix') && t >= maxsegments || ... % Fixed-length trials and maximum trial length reached
       ~strcmp(classifier.cfg.method, 'fix') && ... % Not fixed-length trials but forward/backward stopping and ...
            (strcmp(classifier.cfg.stopping, 'margin') && p_max >= 0 || ... % margin model and margin was reached
            strcmp(classifier.cfg.stopping, 'beta') && p_max >= accuracy || ... % beta model and targeted accuracy was reached
            t >= maxsegments && classifier.cfg.forcestop) % the end of any trial and we are forced to emit a label
        label = p_max_class;
    elseif t >= maxsegments && ~classifier.cfg.forcestop % the end of any trial and we are not forced to emit a label
        label = -p_max_class;
    end
    
    % Set result structure
    result.r = r(:, :, p_max_back(p_max_class)); % raw correlations
    result.t = t * classifier.cfg.segmenttime; % forward time
    if strcmp(classifier.cfg.method, 'bwd')
        result.d = min(t, minbacksegments + p_max_back(p_max_class) - 1) * classifier.cfg.segmenttime; % backward time
    else
        result.d = t * classifier.cfg.segmenttime;
    end
    result.v = p_max; % confidence
    result.datatime = mh / classifier.cfg.fs;
    
    % Prevent classification, t < minsegments
    if ~classifier.cfg.supervised && firsttrial && t < frstminsegments || ... % Unsupervised: if minimum time for first trial not yet reached
       t < minsegments % If minimum time not yet reached
        label = NaN;
    end
    
    %--------------------------------------------------------------------------
    % Unsupervised select best model
    
    % Unsupervised: if classified, update model
    if ~classifier.cfg.supervised && label > 0
        classifier = pm_zt_choose(label, classifier, X);
    end

%--------------------------------------------------------------------------
% Match templates with multiple trials
% Note: this pipeline can be applied to multiple trials at once. It will
% simulate asif trials are collected on the fly. Specifically, dynamic
% stopping will consider all possible stops within a trial, and will emit
% the earliest stop. This way, it mimics asif the dataset provided was
% collected online. The added benefit of this pipeline over the online
% pipeline above, is that it runs faster than doing the above with a
% for-loop over trials. 
function [labels ,results, classifier] = jt_tmc_apply_offline(classifier, X, active_codes, locations)
    
    % Variables
    [~, n_samples, n_trials] = size(X);
    n_segment_samples = floor(classifier.cfg.segmenttime * classifier.cfg.fs);
    n_segments = floor(n_samples / n_segment_samples);
    
    % Prepare results structure
    labels = nan(n_trials, 1);
    results.r = zeros(size(classifier.stim.Mus, 3), n_trials);
    results.t = zeros(1, n_trials);
    results.d = zeros(1, n_trials);
    results.v = zeros(1, n_trials);
    results.datatime = zeros(1, n_trials);
    
    % Loop over trials
    for i_trial = 1:n_trials
        
        % Loop over segments
        for i_segment = 1:n_segments
            
            % Classify trial up to current segment
            x = X(:, 1:i_segment * n_segment_samples, i_trial);
            [lab, ret, classifier] = jt_tmc_apply_online(classifier, x, active_codes, locations);
            
            % Stop trial and save results if classified
            if ~isnan(lab)
                labels(i_trial) = lab;
                results.r(:, i_trial) = ret.r;
                results.t(i_trial) = ret.t;
                results.d(i_trial) = ret.d;
                results.v(i_trial) = ret.v;
                results.datatime(i_trial) = ret.datatime;
                break;
            end
            
        end
        
    end
    