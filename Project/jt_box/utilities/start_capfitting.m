function start_capfitting(src,blockfiles)
% start_capfitting(src,blockfiles)
% Start capfitting procedure
%
% INPUT
%   src = [str] source location of data ('buffer://localhost:1973:tmsi_mobita|rjv_basic_preproc_biosemi_active2')
%   blockfiles = {str} list of blockfiles to compile blocksettings

curdir = fileparts(mfilename('fullpath'));
bsdir = fullfile(curdir,'..','..','..','..','..','toolboxes','brainstream','core');

% Default source
if nargin<1||isempty(src)
    src = 'buffer://localhost:1973:tmsi_mobita|rjv_basic_preproc_biosemi_active2';
end
if nargin<2 || isempty(blockfiles)
    blockfiles = {'eeglab.blk'};
end

% Add brainstream to path
%cd('~/bci_code/toolboxes/brainstream/core/');
cd(bsdir);
bs_addpath;

% Start viewer
start_viewer(src,'eeg',blockfiles);