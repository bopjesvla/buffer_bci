function [] = jt_set_paths(root, add_bs)
% [] = jt_set_paths(root, add_bs) 

if nargin<1||isempty(root); root = '~'; end
if nargin<2||isempty(add_bs); add_bs = true; end

% Noise-tagging
addpath(genpath(fullfile(root, 'bci_code','own_experiments','visual','noise_tagging','jt_box')));

% Math: tprod, repop
addpath(genpath(fullfile(root, 'bci_code','toolboxes','numerical_tools')));

% Plotting: ikelvin
addpath(genpath(fullfile(root, 'bci_code','toolboxes','plotting')));

% Signal proc: detrend
addpath(genpath(fullfile(root, 'bci_code','toolboxes','signal_processing')));
addpath(genpath(fullfile(root, 'bci_code','toolboxes','utilities')));

% BrainStream
if add_bs
    addpath(fullfile(root,'bci_code','toolboxes','brainstream','core'));
    bs_addpath;
end