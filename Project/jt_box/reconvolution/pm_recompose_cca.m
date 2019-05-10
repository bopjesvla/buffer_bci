 function [model, Wxs, Wys] = pm_recompose_cca(X, M, model, cfg)
%[model, Wxs, Wys, r] = pm_recompose_cca(X, M, model, cfg, iCm)
%
% INPUT
%   X     = [c m]    data matrix of channels by samples by trials
%   M     = [e m n]  structure matrices of events by samples by trials
%   model = [struct] filtered covariance model
%       .avg   = [c+e n]     filtered mean of the data and structure matrixes
%       .cov   = [c+e c+e n] filtered sum of covariances (not normalized) of the data and structure matrixes
%       .count = [int]       count of datasamples that contributed to the mean and covsum
%   cfg   = [struct] configuration structure:
%       .L          = [1 r]  length of transient responses in samples (100)
%       .cca        = [str]  CCA method
%       .component  = [int]  CCA component to use (1)
%       .lx         = [flt]  regularization on data.X (1)
%                     [1 c]  regularization on data.X for each sample
%                     [str]  regularization on data.X with taper
%       .ly         = [flt]  regularization on Y (1)
%                     [1 e]  regularization on Y for each sample
%                     [str]  regularization on data.X with taper
%       .lxamp      = [flt]  amplifier for lx regularization penalties, i.e., maximum penalty (1)
%       .lyamp      = [flt]  amplifier for ly regularization penalties, i.e., maximum penalty (1)
%       .lyperc     = [flt]  relative parts of the taper that is regularized
%       .modelonset = [bool] whether or not to model the onset, uses L(end) as length (false)
%
% OUTPUT
%   model = [struct] updated covariance model
%   Wxs   = [c p]    coefficients for X for each class
%   Wys   = [e p]    coefficients for Y for each class

% Defaults
X = permute(X, [2 1]); % [m c]
M = permute(M, [2 1 3]); % [m e n]

% Initialize model
if isempty(model)
    model.c = size(X, 2);
    model.e = size(M, 2);
    model.n = size(M, 3);
    model.count = 0;
    if cfg.runcovariance
        model.avg = zeros(model.c+model.e, model.n);
        model.cov = zeros(model.c+model.e, model.c+model.e, model.n);
    else
        model.X = [];
        model.M = [];
    end
end

% Regularization parameters
lx = pm_regularization(cfg.lx, model.c, false, cfg.lxamp);
lm = pm_regularization(cfg.ly, model.e, cfg.modelonset, cfg.lyamp, cfg.lyperc);

% Apply CCA for each model separately
Wxs = zeros(model.c, model.n);
Wys = zeros(model.e, model.n);
tmpcount = zeros(1, model.n);
for i = 1:model.n
    
    if cfg.runcovariance
        
        % Update covariance given current model
        [model.avg(:, i), model.cov(:, :, i), tmpcount(i)] = jt_covariance_incremental(...
            [X M(:, :, i)], model.avg(:, i)', model.cov(:, :, i), model.count);
        
        % Invert data only once
        if i == 1
            Cxx = model.cov(1:model.c, 1:model.c) + diag(lx);
            iCx = real(Cxx^(-1/2));
        end

        % Decomposition
        [Wxs(:, i), Wys(:, i)] = jt_cca_cov(...
            model.cov(:, :, i), [], lx, lm, cfg.component, iCx);
    else
        % Stack zero mean current model
        sM = cat(1, model.M, M(:, :, i));
        sM = bsxfun(@minus, sM, mean(sM, 1));
        
        % Invert data only once
        if i == 1
            sX = cat(1, model.X, X);
            sX = bsxfun(@minus, sX, mean(sX, 1));
            Cxx = cov(sX) + diag(lx);
            iCx = real(Cxx^(-1/2));
        end
        
        % Decomposition 
        [Wxs(:, i), Wys(:, i)] = jt_cca_cov(...
            sX, sM, lx, lm, cfg.component, iCx);
    end
end

% Keep a data count
if cfg.runcovariance
    model.count = tmpcount(1);
else
    model.count = size(sX, 1);
end