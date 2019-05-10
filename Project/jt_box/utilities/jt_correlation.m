function [rho,state] = jt_correlation(v, w, cfg, state)
%[rho,state] = jt_correlation(v,w,cfg,state)
%
% INPUT
%   v     = [m p]    data of m samples and p variables, only new segment if running correlation
%   w     = [m q]    data of m samples and q variables, only new segment if running correlation
%   cfg   = [struct] configuration structure
%       .method = [str]  method for correlation: fix|fwd|bwd|fwdbwd|shift (fix)
%       .runcor = [bool] whether or not to use running correlation (false)
%       .lenseg = [int]  length of a segment (1)
%       .minfwd = [int]  minimum number of forward segments (1)
%       .maxfwd = [int]  maximum number of forward segments (m/lensegments)
%       .minbwd = [int]  minimum number of backward segments (1)
%       .maxbwd = [int]  maximum number of backward segments (m/lensegments)
%   state = [struct] structure with running correlation statistics, empty at first cal ([])
%       .c     = [int]     number of segments, counter
%       .n     = [int]     maximum number of segments
%       .m     = [int]     number of samples in a segment
%       .p     = [int]     number of variables in v
%       .q     = [int]     number variables in q
%       .stats = [n p q 5] summed statistics
%
% OUTPUT
%   rho   = [p q]     cross-correlations fix: [p q]
%         = [p q f]   cross-correlations fwd: [p q forward] smallest first
%         = [p q b]   cross-correlations bwd: [p q backward] smallest first
%         = [p q f b] cross-correlations fwdbwf: [p q forward backward] smallest first
%         = [p q s]   cross-correlations shift: [p q shift] zero first, shift rightward
%   state = [struct] structure with running correlation statistics, updated with new segment
%       .c     = [int]     number of segments, counter
%       .n     = [int]     maximum number of segments
%       .m     = [int]     number of samples in a segment
%       .p     = [int]     number of variables in v
%       .q     = [int]     number variables in q
%       .stats = [n p q 5] summed statistics

% Make sure input is double precision
v = double(v);
w = double(w);

% Make sure the number of samples in v and w is equal
assert(size(v, 1) == size(w, 1));

% Some variables
[m, p] = size(v);
q = size(w, 2);

% Defaults
if nargin<3||isempty(cfg); cfg = []; end
if nargin<4||isempty(state); state = []; end
method = jt_parse_cfg(cfg, 'method', 'fix');
runcor = jt_parse_cfg(cfg, 'runcor', false);
lenseg = jt_parse_cfg(cfg, 'lenseg', 1);
maxseg = floor(m / lenseg);
minfwd = jt_parse_cfg(cfg, 'minfwd', 1);
maxfwd = jt_parse_cfg(cfg, 'maxfwd', maxseg);
minbwd = jt_parse_cfg(cfg, 'minbwd', 1);
maxbwd = jt_parse_cfg(cfg, 'maxbwd', maxseg);

% Estimate correlation
switch method
    
    % Directly correlate v with w
    % rho = [p, q]
    case 'fix'
        if runcor
            [rho, state] = correlation_incremental(v, w, state, numseg);
        else
            rho = simple_correlation(v, w);
        end
        
    % Correlate v and w with increasing forward lengths (minfwd:maxfwd)
    % rho = [p, q, f]
    case 'fwd'
        
        rho = nan(p, q, 1 + maxfwd - minfwd);
        
        if runcor
            % Note: running correlation needs to perform all steps to keep
            % track of the running statistics
            state = [];
            for f = 1:maxfwd
                idx = 1 + (f - 1) * lenseg:f * lenseg;
                [corrs, state] = correlation_incremental(v(idx, :), w(idx, :), state, numseg);
                rho(:, :, f) = corrs(:, :, f);
            end
            rho = rho(:, :, minfwd:end);
        else
            f_idx = minfwd:maxfwd;
            for f = 1:numel(f_idx);
                idx = 1:f_idx(f) * lenseg;
                rho(:, :, f) = simple_correlation(v(idx, :), w(idx, :));
            end
        end
        
    % Correlate v and w with increasing backward lengths (minbwd:maxbwd)
    % rho = [p, q, b]
    case 'bwd'
        
        rho = nan(p, q, 1 + maxbwd - minbwd);
        
        if runcor
            % Note: running correlation needs to perform all steps to keep
            % track of the running statistics
            state = [];
            for f = 1:maxseg
                idx = 1 + (f - 1) * lenseg:f * lenseg;
                [corrs, state] = correlation_incremental(v(idx, :), w(idx, :), state, numseg);
            end
            rho = corrs(:, :, minbwd:maxbwd);
        else
            b_idx = minbwd:maxbwd;
            for b = 1:numel(b_idx)
                idx = 1 + (maxseg - b_idx(b)) * lenseg:m;
                rho(:, :, b) = simple_correlation(v(idx, :), w(idx, :));
            end
        end
        
    % Correlate v and w with increasing forward and backward lengths (b:f)
    % rho = [p, q, f, b]
    case 'fwdbwd'
        
        if runcor 
            rho = nan(p, q, numseg, numseg);
            % Note: running correlation needs to perform all steps to keep
            % track of the running statistics
            state = [];
            for f = 1:maxfwd
                idx = 1 + (f - 1) * lenseg:f * lenseg;
                [rho(:, :, :, f), state] = correlation_incremental(v(idx, :), w(idx, :), state, numseg);
            end
            rho = permute(rho, [1 2 4 3]);
            rho = rho(:, :, minfwd:end, minbwd:maxbwd);
        else
            rho = nan(p, q, 1 + maxfwd - minfwd, 1 + maxbwd - minbwd);
            f_idx = minfwd:maxfwd;
            for f = 1:numel(f_idx)
                b_idx = minbwd:min(f_idx(f), maxbwd);
                for b = numel(b_idx)
                    idx = 1 + (f_idx(f) - b_idx(b)) * lenseg:f_idx(f) * lenseg;
                    rho(:, :, f, b) = simple_correlation(v(idx, :), w(idx, :));
                end
            end
        end
        
    % Correlate v and w by shifting one of the two over the other
    % rho = [p, q, s]
    case 'shift'
        
        if runcor; error('Not implementd yet.'); end
        rho = nan(p, q, maxseg);
        for s = 0:maxseg - 1
            w = circshift(w, m);
            rho(:, :, s) = simple_correlation(v, w);
        end
end

%--------------------------------------------------------------------------
function [rho] = simple_correlation(v,w)
%[rho,state] = simple_correlation(v,w)
%
% INPUT
%   v = [m p]    new segment of m samples and p variables
%   w = [m q]    new segment of m samples and q variables
%
% OUTPUT
%   rho = [p q]  correlations values starting with short segments

    % Subtract mean
    v = bsxfun(@minus, v, mean(v, 1));
    w = bsxfun(@minus, w, mean(w, 1));

    % Compute correlation
    rho = v' * w ./ sqrt(sum(v.^2)' * sum(w.^2));
    
%--------------------------------------------------------------------------
function [rho,state] = correlation_incremental(v,w,state,maxn)
%[rho,state] = correlation_incremental(v,w,state,n)
%
% INPUT
%   v     = [m p]    new segment of m samples and p variables
%   w     = [m q]    new segment of m samples and q variables
%   state = [struct] structure with running correlation statistics, empty at first cal ([])
%   maxn  = [int]    maximum number of segments (1)
%
% OUTPUT
%   rho   = [p q n]  correlations values starting with short segments
%   state = [struct] structure with running correlation statistics, updated with newest segment
%       .c     = [int]     number of segments, counter
%       .n     = [int]     maximum number of segments
%       .m     = [int]     number of samples in a segment
%       .p     = [int]     number of variables in v
%       .q     = [int]     number variables in q
%       .stats = [n p q 5] summed statistics

    % Defaults
    if nargin<3||isempty(state); state = []; end
    if nargin<4||isempty(maxn); maxn = 1; end

    % Initialize state
    if isempty(state)
        state = [];
        state.c = 0;            % Segment counter 
        state.n = maxn;         % Maximum number of segments
        state.m = size(v,1);    % Number of samples in segment
        state.p = size(v,2);    % Number of variables in v
        state.q = size(w,2);    % Number of variables in w
        state.stats = zeros(state.p,state.q,maxn,5); % statistics
    end

    % Stats of new segment
    stats = cat(3,...
        repmat(sum(v, 1)',   [1 state.q]), ... % sum of v 
        repmat(sum(w, 1),    [state.p 1]), ... % sum of w
        repmat(sum(v.^2, 1)',[1 state.q]), ... % sum of v squared
        repmat(sum(w.^2, 1), [state.p 1]), ... % sum of w squared
        v' * w);                               % cross-products v and w

    % Move stats up in duration
    state.stats = circshift(state.stats, [0 0 1 0]);
    state.stats(:, :, 1, :) = 0;

    % Push new stats
    state.c = min(state.c+1, state.n);
    state.stats(:, :, 1:state.c, :) = state.stats(:, :, 1:state.c, :) + permute(repmat(stats, [1 1 1 state.c]), [1 2 4 3]);

    % Update corrs
    k  = state.m*repmat(permute(1:state.n,[1 3 2]),[state.p state.q 1]);
    v  = state.stats(:, :, :, 1); % v
    w  = state.stats(:, :, :, 2); % w
    v2 = state.stats(:, :, :, 3); % v squared
    w2 = state.stats(:, :, :, 4); % w squared
    vw = state.stats(:, :, :, 5); % cross products
    rho = (k .* vw - v .* w) ./ ( (k .* v2 - v.^2) .* (k .* w2 - w.^2) ).^.5;
    rho(:, :, state.c+1:end) = nan;

%--------------------------------------------------------------------------
function testcase()

    % Parameters
    numseg = 60;    % Number of segments data
    lenseg = 180;   % Segment length
    p = 36;         % Number of classes
    q = 40;         % Number of trials

    % Data
    v = rand(numseg * lenseg, p);
    w = rand(numseg * lenseg, q);
    
    % Test running correlation versus normal fix
    % Full
    tic;
    r1 = jt_correlation(v, w, struct('method', 'fix', 'lenseg', lenseg*numseg, 'numseg', 1, 'runcor', false));
    toc;
    % Segmented
    tic;
    r2 = jt_correlation(v, w, struct('method', 'fix', 'lenseg', lenseg*numseg, 'numseg', 1, 'runcor', true));
    toc;
    % Max error
    disp(max(abs(r2(:)-r1(:))));
    
    % Test running correlation versus normal fwd
    % Full
    tic;
    r1 = jt_correlation(v, w, struct('method', 'fwd', 'lenseg', lenseg, 'numseg', numseg, 'runcor', false, 'minfwd', 10, 'minbwd', 5));
    toc;
    % Segmented
    tic;
    r2 = jt_correlation(v, w, struct('method', 'fwd', 'lenseg', lenseg, 'numseg', numseg, 'runcor', true, 'minfwd', 10, 'minbwd', 5));
    toc;
    % Max error
    disp(max(abs(r2(:)-r1(:))));
    
    % Test running correlation versus normal bwd
    % Full
    tic;
    r1 = jt_correlation(v, w, struct('method', 'bwd', 'lenseg', lenseg, 'numseg', numseg, 'runcor', false, 'minfwd', 10, 'minbwd', 5));
    toc;
    % Segmented
    tic;
    r2 = jt_correlation(v, w, struct('method', 'bwd', 'lenseg', lenseg, 'numseg', numseg, 'runcor', true, 'minfwd', 10, 'minbwd', 5));
    toc;
    % Max error
    disp(max(abs(r2(:)-r1(:))));
    
    % Test forward with and without minfwd fwdbwd
    % Full
    tic;
    r1 = jt_correlation(v, w, struct('method', 'fwdbwd', 'lenseg', lenseg, 'numseg', numseg, 'runcor', false, 'minfwd', 10, 'minbwd', 5));
    toc;
    % Segmented
    tic;
    r2 = jt_correlation(v, w, struct('method', 'fwdbwd', 'lenseg', lenseg, 'numseg', numseg, 'runcor', true, 'minfwd', 10, 'minbwd', 5));
    toc;
    % Max error
    disp(max(abs(r2(:)-r1(:))));
    
    % Test forward with and without minfwd
    % Full
    tic;
    r1 = jt_correlation(v, w, struct('method', 'bwd', 'lenseg', lenseg, 'numseg', numseg, 'minbwd', 10));
    toc;
    % Segmented
    tic;
    r2 = jt_correlation(v, w, struct('method', 'bwd', 'lenseg', lenseg, 'numseg', numseg, 'minbwd', 1));
    r2 = r2(:, :, 10:end);
    toc;
    % Max error
    disp(max(abs(r2(:)-r1(:))));
    
    % Test forward-backward with and without minfwd/minbwd
    % Full
    tic;
    r1 = jt_correlation(v, w, struct('method', 'fwdbwd', 'lenseg', lenseg, 'numseg', numseg, 'minfwd', 10, 'minbwd', 5));
    toc;
    % Segmented
    tic;
    r2 = jt_correlation(v, w, struct('method', 'fwdbwd', 'lenseg', lenseg, 'numseg', numseg, 'minfwd', 1, 'minbwd', 1));
    r2 = r2(:, :, 10:end, 5:end);
    toc;
    % Max error
    disp(max(abs(r2(:)-r1(:))));