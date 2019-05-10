function [classifier] = jt_tmc_train(data, cfg)
%[classifier] = jt_tmc_train(data, cfg)
% Trains a template matching classifier
%
% INPUT
%   data = [struct] data structure:
%       .X   = [c m k] training data of c channels, m samples, and k trials
%       .y   = [k 1]   training labels or targets of k trials, i.e., indexes in V
%       .l   = [k 1]   locations/grouping of k trials, i.e., locations of the targets in y (ones(k, 1))
%       .V   = [s p]   one period of training sequences of s samples and p codes, should be at the same sample frequency as .X
%       .U   = [s q]   one period of testing sequences of s samples and q codes, should be at the same sample frequency as .X
%   cfg = [struct] configuration structure
%         [struct] classifier with cfg and empty fields at retrainable properties
%
%   General:
%       .verbosity      = [int] verbosity level: 0=off, 1=classifier, 2=classifier with optimistic accuracy, 3=classifier with generalized cross-validated accuracy (1)
%       .nfolds         = [int] number of folds to use in the cross-validation if verbosity==3 (10)
%       .user           = [str] name of current user, only used if verbosity > 0 to view the classifier('user')
%       .capfile        = [str] file name of electrode positions, only used if verbosity > 0 to view the spatial filter ('nt_cap64.loc')
%
%   Timing:
%       .fs             = [int] data sample frequency in hertz (256)
%       .segmenttime    = [flt] data segment length in seconds (.1)
%       .mintime        = [flt] minimum trial length in seconds (.segmenttime)
%       .maxtime        = [flt] maximum trial length in seconds (4.0)
%       .minbacktime    - [flt] minimum trial length for backward stopping in seconds (.segmenttime)
%       .maxbacktime    - [flt] maximum trial length for backward stopping in seconds (.maxtime)
%       .intertrialtime = [flt] inter-trial time in seconds, only used for calculating the ITR if verbosity > 1 (0)
%       .delay          = [1 e] overall positive delay of onsets of events in seconds, e.g., marker transmission delay (0)
%       .latencyV       = [1 p] latencies for individual training sequences in seconds, e.g. rasterization delay (zeros(p, 1))
%       .latencyU       = [1 q] latencies for individual testing sequences in seconds, e.g. rasterization delay (zeros(q, 1))
%
%   Classification:
%       .method         = [str]  classification method: fix=fixed-length trials, fwd=forward-stopping, bwd=backward-stopping ('fix')
%       .online         = [bool] whether or not to classify an online single-trial, or to use a simulated multi-trial offline approach (true)
%       .supervised     = [bool] whether or not supervised or unsupervised/zero-training (true)
%       .synchronous    = [bool] whether or not synchronous or asynchronous (true)
%       .runcorrelation = [bool] whether or not to use running correlations (false)
%
%   Reconvolution
%       .cca            = [str]  CCA method: qr, svd, cov, eig ('cov')
%       .L              = [1 e]  length of transient responses in seconds (0.3)
%       .event          = [str]  event type for decomposition: see jt_event_matrix ('duration')
%       .component      = [int]  CCA component to use (1)
%       .lx             = [int]  regularization for Wx (i.e., spatial filter)) between 0 (unreliable) and 1 (reliable) (1)
%                       = [1 c]  penalties for each channel c
%                       = [str]  penalty type for Wx (e.g., tukey)
%       .ly             = [int]  regularization for Wy (i.e., transient response(s)) between 0 (unreliable) and 1 (reliable) (1)
%                       = [1 l]  penalties for each response sample l
%                       = [str]  penalty type for Wy (e.g., tukey)
%       .lxamp          = [flt]  amplifier for lx regularization penalties, i.e., maximum penalty (0.1)
%       .lyamp          = [flt]  amplifier for ly regularization penalties, i.e., maximum penalty (0.01)
%       .lyperc         = [flt]  relative parts of the taper that is regularized (.2)
%       .modelonset     = [bool] whether or not to model the onset, uses L(end) as length (false)
%
%   Subset Selection:
%       .subsetV        = [1 p] training subset (1:p)
%       .subsetU        = [1 q] testing subset (1:q)
%                       = [str] optimization method, e.g. clustering
%       .nclasses       = [int] number of training codes, only for optimization ([])
%
%   Layout Selection
%       .layoutV        = [1 p] training layout (1:p)
%       .layoutU        = [1 q] testing layout (1:q)
%                       = [str] optimization method, e.g. incremental
%       .neighbours     = [x 2] neighbour pairs, only for otptimization ([])
%
%   Dynamic Stopping:
%       .stopping       = [str]  stopping method: margin or beta ('beta')
%       .forcestop      = [bool] whether or not to force stop at maxtime (true)
%       .accuracy       = [flt]  targeted stopping accuracy (.95)
%
%   Asynchronous
%       .shifttime      = [flt] step size for shifting templates in seconds (1/30)
%       .shifttimemax   = [flt] maximum shift in seconds (1)
%
%   Transfer-learning
%       .transfermodel  = [str] which transfer model to use: train, transfer, transfertrain, no ('no')
%       .transferfile   = [str] file of the transfer model ('nt_model_chn64_ev144')
%       .transfercount  = [int] number of samples/weight of the model (0)
%
%   Unsupervised
%       .runcovariance  = [bool] whether or not to use running covariance (false)
%       .frstmintime    = [flt]  minimum trial length for first trial in seconds (.maxtime)
%       .frstaccuracy   = [flt]  targeted accuracy for first trial (.accuracy)
%
% OUTPUT
%   classifier = [struct] classifier structure:
%       .cfg = [struct] configuration
%       .stim = [struct] stimuli structure matrices
%           .Mvs = [l s p] structure matrices for V, period==1, subset and layout are applied
%           .Mvw = [l s p] structure matrices for V, period>1, subset and layout are applied
%           .Mus = [l s q] structure matrices for U, period==1, subset and layout are applied
%           .Muw = [l s q] structure matrices for U, period>1, subset and layout are applied
%       .transients = [l 1] transient response(s)
%       .filter = [c 1] spatial filter
%       .model = [struct] covariance model
%           .count = [int] counter of data in model
%           .avg   = [N-D] running average
%           .cov   = [N-D] running covariance
%           .X     = [c z] stacked data of c channels and q samples so far
%           .M     = [l z] stacked structure matrices of classified labels of e response samples and q samples so far
%       .templates = [struct] templates
%           .Tvs = [s p] templates for V, period==1, subset and layout are applied
%           .Tvw = [s p] templates for V, period>1, subset and layout are applied
%           .Tus = [s q] templates for U, period==1, subset and layout are applied
%           .Tuw = [s q] templates for U, period>1, subset and layout are applied
%       .subset = [struct] subset
%           .V = [1 p] training subset for V
%           .U = [1 q] testing subset for U
%       .layout = [struct] layout
%           .V = [1 p] training layout for V
%           .U = [1 q] testing layout for U
%       .margins = [1 z] threshold margins for margin stopping model
%       .accuracy = [struct] accuracy estimation
%           .p   = [flt] estimate of the accuracy
%           .t   = [flt] estimate of the trial duration, i.e., forward stop
%           .d   = [flt] estimate of the trial length, i.e., backward stop
%           .itr = [flt] estimate of the Wolpaw information transfer rate
%       .view = [hdl] figure handle to classifier figure

if nargin<2 || isempty(cfg); cfg=[]; end
if jt_exists_in(data, 'y'); data.y = data.y(:); end
if ~jt_exists_in(data, 'l'); data.l = ones(numel(data.y), 1); end
data.X = double(data.X);

% Variables
[c, m, ~] = size(data.X);
[s, p] = size(data.V);
q = size(data.U, 2);

%--------------------------------------------------------------------------
% Initialization

% The cfg is an 'old' classifier to be re-used
if isfield(cfg,'cfg') 
    classifier = cfg;
    cfg = classifier.cfg;
% Initialize a new classifier with specified cfg
else
    classifier = struct();
    classifier.cfg = struct();
end

%--------------------------------------------------------------------------
% Defaults

% General
classifier.cfg.verbosity = jt_parse_cfg(cfg, 'verbosity', 1);
classifier.cfg.nfolds = jt_parse_cfg(cfg, 'nfolds', 10);
classifier.cfg.user = jt_parse_cfg(cfg, 'user', 'user');
classifier.cfg.capfile = jt_parse_cfg(cfg, 'capfile', 'nt_cap64.loc');

% Timing
classifier.cfg.fs = jt_parse_cfg(cfg, 'fs', 256);
classifier.cfg.segmenttime = jt_parse_cfg(cfg, 'segmenttime', 0.1);
classifier.cfg.mintime = jt_parse_cfg(cfg, 'mintime', classifier.cfg.segmenttime);
classifier.cfg.maxtime = jt_parse_cfg(cfg, 'maxtime', 4.0);
classifier.cfg.minbacktime = jt_parse_cfg(cfg, 'minbacktime', classifier.cfg.segmenttime);
classifier.cfg.maxbacktime = jt_parse_cfg(cfg, 'maxbacktime', classifier.cfg.maxtime);
classifier.cfg.intertrialtime = jt_parse_cfg(cfg, 'intertrialtime', 0);
classifier.cfg.delay = jt_parse_cfg(cfg, 'delay', 0);
classifier.cfg.latencyV = jt_parse_cfg(cfg, 'latencyV', zeros(p, 1));
classifier.cfg.latencyU = jt_parse_cfg(cfg, 'latencyU', zeros(q, 1));

% Classification
classifier.cfg.method = jt_parse_cfg(cfg, 'method', 'fix');
classifier.cfg.online = jt_parse_cfg(cfg, 'online', true);
classifier.cfg.supervised = jt_parse_cfg(cfg, 'supervised', true);
classifier.cfg.synchronous = jt_parse_cfg(cfg, 'synchronous', true);
classifier.cfg.runcorrelation = jt_parse_cfg(cfg, 'runcorrelation', false);

% Reconvolution
classifier.cfg.cca = jt_parse_cfg(cfg, 'cca', 'cov');
classifier.cfg.L = jt_parse_cfg(cfg, 'L', 0.3);
classifier.cfg.event = jt_parse_cfg(cfg, 'event', 'duration');
classifier.cfg.component = jt_parse_cfg(cfg, 'component', 1);
classifier.cfg.lx = jt_parse_cfg(cfg, 'lx', 1);
classifier.cfg.ly = jt_parse_cfg(cfg, 'ly', 1);
classifier.cfg.lxamp = jt_parse_cfg(cfg, 'lxamp', 0.1);
classifier.cfg.lyamp = jt_parse_cfg(cfg, 'lyamp', 0.01);
classifier.cfg.lyperc = jt_parse_cfg(cfg, 'lyperc', 0.2);
classifier.cfg.modelonset = jt_parse_cfg(cfg, 'modelonset', false);

% Subset
classifier.cfg.subsetV = jt_parse_cfg(cfg, 'subsetV', 1:p);
classifier.cfg.subsetU = jt_parse_cfg(cfg, 'subsetU', 1:q);
classifier.cfg.nclasses = jt_parse_cfg(cfg, 'nclasses', []);

% Layout
classifier.cfg.layoutV = jt_parse_cfg(cfg, 'layoutV', 1:p);
classifier.cfg.layoutU = jt_parse_cfg(cfg, 'layoutU', 1:q);
classifier.cfg.neighbours = jt_parse_cfg(cfg, 'neighbours', []);

% Dynamic Stopping
classifier.cfg.stopping = jt_parse_cfg(cfg, 'stopping', 'beta');
classifier.cfg.forcestop = jt_parse_cfg(cfg, 'forcestop', true);
classifier.cfg.accuracy = jt_parse_cfg(cfg, 'accuracy', 0.95);

% Asynchronous
classifier.cfg.shifttime = jt_parse_cfg(cfg, 'shifttime', 1/30);
classifier.cfg.shifttimemax = jt_parse_cfg(cfg, 'shifttimemax', 1);

% Transfer-learning
classifier.cfg.transfermodel = jt_parse_cfg(cfg, 'transfermodel', 'no');
classifier.cfg.transferfile = jt_parse_cfg(cfg, 'transferfile', 'nt_model_chn64_ev144');
classifier.cfg.transfercount = jt_parse_cfg(cfg, 'transfercount', 0);

% Unsupervised
classifier.cfg.runcovariance = jt_parse_cfg(cfg, 'runcovariance', false);
classifier.cfg.frstaccuracy = jt_parse_cfg(cfg, 'frstaccuracy', classifier.cfg.accuracy);
classifier.cfg.frstmintime = jt_parse_cfg(cfg, 'frstmintime', classifier.cfg.segmenttime);

% Classification should at least use one segment!
classifier.cfg.mintime     = max(classifier.cfg.mintime,     classifier.cfg.segmenttime);
classifier.cfg.minbacktime = max(classifier.cfg.minbacktime, classifier.cfg.segmenttime);
classifier.cfg.maxbacktime = max(classifier.cfg.maxbacktime, classifier.cfg.segmenttime);
classifier.cfg.frstmintime = max(classifier.cfg.frstmintime, classifier.cfg.segmenttime);

%--------------------------------------------------------------------------
% Structure matrices

if ~jt_exists_in(classifier, 'stim') || ~jt_exists_in(classifier.stim, {'Mvs','Mvw','Mus','Muw'})
    
    % Build structure matrices
    M = jt_structure_matrix(repmat(cat(2, data.V, data.U), [2 1]), struct(...
        'L', floor(classifier.cfg.L * classifier.cfg.fs),...
        'delay', floor(classifier.cfg.delay * classifier.cfg.fs),...
        'event', classifier.cfg.event,...
        'modelonset', classifier.cfg.modelonset));
    classifier.stim.Mvs = M(:, 1:s, 1:p);
    classifier.stim.Mvw = M(:, 1+s:end, 1:p);
    classifier.stim.Mus = M(:, 1:s, p+1:end);
    classifier.stim.Muw = M(:, 1+s:end, p+1:end);

    % Make sure there is an L for each event
    if numel(classifier.cfg.L) == 1
        classifier.cfg.L = repmat(classifier.cfg.L, [1 floor(size(M, 1) / (classifier.cfg.L * classifier.cfg.fs))]); 
    end
    
end

%--------------------------------------------------------------------------
% Training subset and layout

classifier.subset.V = classifier.cfg.subsetV;
classifier.layout.V = classifier.cfg.layoutV;
classifier.stim.Mvs = classifier.stim.Mvs(:, :, classifier.subset.V(classifier.layout.V));
classifier.stim.Mvw = classifier.stim.Mvw(:, :, classifier.subset.V(classifier.layout.V));

%--------------------------------------------------------------------------
% Latencies

p = size(classifier.stim.Mvs, 3);
if ~all(classifier.cfg.latencyV == 0)
    assert(p == numel(classifier.cfg.latencyV));
    for i = 1:p
        shift = floor(classifier.cfg.latencyV(i) * classifier.cfg.fs);
        classifier.stim.Mvs(:, :, i) = circshift(classifier.stim.Mvs(:, :, i), shift, 2);
        classifier.stim.Mvw(:, :, i) = circshift(classifier.stim.Mvw(:, :, i), shift, 2);
        classifier.stim.Mvs(:, 1:shift, i) = 0;
    end
end

q = size(classifier.stim.Mus, 3);
if ~all(classifier.cfg.latencyU == 0)
    assert(q == numel(classifier.cfg.latencyU));
    for i = 1:q
        shift = floor(classifier.cfg.latencyU(i) * classifier.cfg.fs);
        classifier.stim.Mus(:, :, i) = circshift(classifier.stim.Mus(:, :, i), shift, 2);
        classifier.stim.Muw(:, :, i) = circshift(classifier.stim.Muw(:, :, i), shift, 2);
        classifier.stim.Mus(:, 1:shift, i) = 0;
    end
end

%--------------------------------------------------------------------------
% Deconvolution

if ~jt_exists_in(classifier, {'transients', 'filter'})
    
    % Initialize
    classifier.transients = [];
    classifier.filter = [];
    classifier.model = [];
    
    % Create CCA data matrix
    y = unique(data.y);
    ny = numel(y);
    l = unique(data.l);
    nl = numel(l);
    X = zeros(c * nl, m, nl);
    for i = 1:ny
        for j = 1:nl
            idx = data.y==y(i) & data.l==l(j);
            if sum(idx) > 0
                X(1 + (j-1) * c:j * c, :, i) = mean(data.X(:, :, idx), 3);
            end
        end
    end

    % Create CCA design matrix
    l = size(classifier.stim.Mvs, 2);
    M = cat(2, classifier.stim.Mvs, repmat(classifier.stim.Mvw, [1 ceil(m/l)-1 1]));
    M = M(:, 1:m, y);

    % Create configuration
    cfg = classifier.cfg;
    cfg.L = floor(classifier.cfg.fs .* classifier.cfg.L);

    % Supervised
    if classifier.cfg.supervised

        % Train transients only
        if jt_exists_in(classifier, 'filter')
            classifier.transients = pm_decompose_ls(X, M, classifier, cfg);
        % Train filter only
        elseif jt_exists_in(classifier, 'transients')
            [~, classifier.filter] = pm_decompose_ls(X, M, classifier, cfg);
        % Train transients and filter
        else
            [classifier.transients, classifier.filter] = jt_decompose_cca(X, M, cfg);
        end

    % Unsupervised / transfer-learning
    else

        % Use transfer data 
        if any(strcmpi(classifier.cfg.transfermodel, {'transfer', 'transfertrain'}))
            in = load(classifier.cfg.transferfile);
            in.model.n = 1;
            [classifier.model, classifier.filter, classifier.transients] = pm_recompose_cca([], [], in.model, cfg);
            classifier.model.n = q;
            if isnumeric(classifier.cfg.transfercount)
                classifier.model.count = classifier.cfg.transfercount;
            end
        end

        % Use training data
        if any(strcmpi(classifier.cfg.transfermodel, {'train', 'transfertrain'})) && ~isempty(data.X) && ~isempty(data.y)
            [classifier.model, classifier.filter, classifier.transients] = pm_recompose_cca(reshape(data.X, size(data.X, 1), []), reshape(Mv, size(Mv, 1),[]), classifier.model, cfg);
            classifier.model.n = q;
        end

    end
    
end

%--------------------------------------------------------------------------
% Convolution

if ~jt_exists_in(classifier, 'templates') || ~jt_exists_in(classifier.templates, {'Tvs','Tvw','Tus','Tuw'})
    
    % Initialize
    classifier.templates.Tvs = [];
    classifier.templates.Tvw = [];
    classifier.templates.Tus = [];
    classifier.templates.Tuw = [];

    % Convolution
    if ~isempty(classifier.transients)
        classifier.templates.Tvs = jt_compose_cca(classifier.stim.Mvs,classifier.transients);
        classifier.templates.Tvw = jt_compose_cca(classifier.stim.Mvw,classifier.transients);
        classifier.templates.Tus = jt_compose_cca(classifier.stim.Mus,classifier.transients);
        classifier.templates.Tuw = jt_compose_cca(classifier.stim.Muw,classifier.transients);
    end
    
end

%--------------------------------------------------------------------------
% Testing subset

if ~jt_exists_in(classifier.subset, 'U')
    
    % Select subset
    if isnumeric(classifier.cfg.subsetU)
        classifier.subset.U = classifier.cfg.subsetU;
    else
        switch classifier.cfg.subsetU

            case 'no'
                classifier.subset.U = 1:q;

            case 'default_36'
                in = load('nt_subset.mat');
                classifier.subset.U = in.subset;
                q = numel(classifier.subset.U);

            case {'yes', 'clustering'}
                if ~classifier.cfg.supervised 
                    error('Impossible to optimize a subset unsupervised.'); 
                end
                if isempty(classifier.cfg.nclasses)
                    error('Subset optimization requires a specification of the number of classes.')
                end
                templates = cat(1, classifier.templates.Tus, classifier.templates.Tuw);
                classifier.subset.U = jt_lcs_clustering(templates, classifier.cfg.nclasses, classifier.cfg.synchronous, classifier.cfg.segmenttime * classifier.cfg.fs);
                
                q = numel(classifier.subset.U);
                classifier.model.n = q;

            otherwise
                error('Unknown subset method %s.',classifier.cfg.subsetU);
        end
    end

    % Apply subset
    classifier.stim.Mus = classifier.stim.Mus(:, :, classifier.subset.U);
    classifier.stim.Muw = classifier.stim.Muw(:, :, classifier.subset.U);
    if ~isempty(classifier.templates.Tus) && ~isempty(classifier.templates.Tuw)
        classifier.templates.Tus = classifier.templates.Tus(:, classifier.subset.U);
        classifier.templates.Tuw = classifier.templates.Tuw(:, classifier.subset.U);
    end
    
end

%--------------------------------------------------------------------------
% Testing layout

if ~jt_exists_in(classifier.layout, 'U')
    
    % Select layout
    if isnumeric(classifier.cfg.layoutU)
        classifier.layout.U = classifier.cfg.layoutU;
    else
        switch classifier.cfg.layoutU

            case 'no'
                classifier.layout.U = 1:q;

            case 'default_36'
                in = load('nt_layout.mat');
                classifier.layout.U = in.layout;

            case {'yes', 'incremental'}
                if ~classifier.cfg.supervised
                    error('Impossible to train a layout unsupervised.'); 
                end
                templates = cat(1, classifier.templates.Tus, classifier.templates.Tuw);
                if isnumeric(classifier.cfg.neighbours) && numel(classifier.cfg.neighbours) == 2
                    neighbours = jt_findneighbours(reshape((1:q)', classifier.cfg.neighbours));
                end
                classifier.layout.U = jt_lcl_incremental(templates, neighbours, classifier.cfg.synchronous, classifier.cfg.segmenttime * classifier.cfg.fs);

            otherwise
                error('Unknown layout method %s.', classifier.cfg.layoutU);
        end
    end

    % Apply layout
    classifier.stim.Mus = classifier.stim.Mus(:, :, classifier.layout.U);
    classifier.stim.Muw = classifier.stim.Muw(:, :, classifier.layout.U);
    if ~isempty(classifier.templates.Tus) && ~isempty(classifier.templates.Tuw)
        classifier.templates.Tus = classifier.templates.Tus(:, classifier.layout.U);
        classifier.templates.Tuw = classifier.templates.Tuw(:, classifier.layout.U);
    end
    
end

%--------------------------------------------------------------------------
% Asynchronous

if ~classifier.cfg.synchronous
    
    % Check if templates can be or are already shifted
    if isempty(classifier.templates.Tus) || isempty(classifier.templates.Tuw) || size(classifier.templates.Tus, 2) ~= q
        return;
    end

    % Add shifted templates
    d = classifier.cfg.shifttime * classifier.cfg.fs;
    for i = 2:floor(classifier.cfg.shifttimemax * classifier.cfg.fs / d);
        classifier.templates.Tvs = cat(2, classifier.templates.Tvs, circshift(classifier.templates.Tvs(:, end-p+1:end), d));
        classifier.templates.Tvw = cat(2, classifier.templates.Tvw, circshift(classifier.templates.Tvw(:, end-p+1:end), d));
        classifier.templates.Tus = cat(2, classifier.templates.Tus, circshift(classifier.templates.Tus(:, end-q+1:end), d));
        classifier.templates.Tuw = cat(2, classifier.templates.Tuw, circshift(classifier.templates.Tuw(:, end-q+1:end), d));
    end
    
end

%--------------------------------------------------------------------------
% Margins

if ~jt_exists_in(classifier, 'margins')
    
    % Initialize
    classifier.margins = [];

    % Margins
    switch classifier.cfg.stopping

        case 'beta'
            classifier.margins = nan(1, floor(classifier.cfg.maxtime / classifier.cfg.segmenttime));

        case 'margin'
            if isempty(classifier.templates.Tvs) || isempty(classifier.templates.Tvw) || isempty(data.X) || isempty(data.y)
                error('Margins can only be computed given data and templates.');
            end

            fX = tprod(data.X, [-1 1 2], classifier.filter, -1);
            Tu = cat(1, classifier.templates.Tvs, repmat(classifier.templates.Tvw, [ceil(m/s) 1]));
            Tu = Tu(1:m,:);
            classifier.margins = jt_learn_margins(fX, data.y, Tu, struct(...
                'nclasses', q,...
                'method', classifier.cfg.method,...
                'segmentlength', classifier.cfg.segmenttime * classifier.cfg.fs,...
                'forcestop', classifier.cfg.forcestop,...
                'accuracy', classifier.cfg.accuracy,....
                'runcorrelation', classifier.cfg.runcorrelation)); 
    end
    
end

%--------------------------------------------------------------------------
% Accuracy

if nl > 1 && classifier.cfg.verbosity > 0
    error('Error: verbosity > 0 not possible with more than 1 locations!')
end

if ~jt_exists_in(classifier, 'accuracy')
    
    % Initialize
    classifier.accuracy = [];
    classifier.accuracy.p = [];
    classifier.accuracy.t = [];
    classifier.accuracy.d = [];

    % Check if accuracy can be computed
    if classifier.cfg.verbosity > 1 && (~jt_exists_in(classifier.templates, {'Tvs','Tvw'}) || ~jt_exists_in(data, {'X','y'}) )
        error('For accuracy estimation data is required.');
    end

    % Accuracy
    switch classifier.cfg.verbosity

        case 2
            % Test directly on train data (cheaty/optimistic, but fast)
            tmp = classifier;
            tmp.cfg.supervised = true;
            tmp.cfg.online = false;
            tmp.cfg.forcestop = true;
            tmp.templates.Tus = classifier.templates.Tvs;
            tmp.templates.Tuw = classifier.templates.Tvw;
            [labels, results] = jt_tmc_apply(tmp, data.X);
            classifier.accuracy.p = mean(labels == data.y);
            classifier.accuracy.t = mean(results.t);
            classifier.accuracy.d = mean(results.d);
            classifier.accuracy.itr = jt_itr(size(classifier.stim.Mus, 3), classifier.accuracy.p, classifier.accuracy.t + classifier.cfg.intertrialtime);

        case 3
            % Cross-validation 10-fold (good/generalized, but slow)
            tmp = classifier.cfg;
            tmp.supervised = true;
            tmp.online = false;
            tmp.forcestop = true;
            results = jt_tmc_cv(data, tmp, classifier.cfg.nfolds);
            classifier.accuracy.p = mean(results.p);
            classifier.accuracy.t = mean(results.t);
            classifier.accuracy.d = mean(results.d);
            classifier.accuracy.itr = jt_itr(size(classifier.stim.Mus, 3), classifier.accuracy.p, classifier.accuracy.t + classifier.cfg.intertrialtime);
    end
    
end

%--------------------------------------------------------------------------
% View

if classifier.cfg.verbosity > 0
    classifier = jt_tmc_view(classifier);
end