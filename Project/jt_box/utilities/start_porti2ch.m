function start_porti2ch(src,dst,num_forwarded_eeg_channels)
% start_porti(src,dst,numeegchannels)
% Start TMSi Porti local buffer from external buffer, with trigger functionality.
%
% INPUT
%   src = [str] source location of data ('buffer://131.174.111.215:1972')
%   dst = [str] destiny location of data ('buffer://localhost:1973')
%   num_forwarded_eeg_channels = number of channels to retain,
%       channels <total number of eeg channels> + 1 and further will be
%       discarded in forwarding
% 
% SETUP
%	?	Porti with trigger-header, connected to trigger interface
%	?	Trigger interface IN connected to OUT on MidiSport device
%	?	MidiSport device connected to main machine USB.
%	?	Windows machine with both ethernet and wifi
%	?	Buffer_BCI software
%	?	TMSi Fieldtrip Polybench
%	?	Main machine with ethernet
%	?	Matlab
%	?	Brainstream
% STARTUP
%	?	On Windows machine, double-click downloads/buffer_bci/buffer_bci/dataAcq/startBuffer?. Command window with buffer should appear.
%	?	On Windows machine, start Polybench (TSMi to Fieldtrip). In Polybench, set ?Front-end categ? to ?WiFi front-ends? and check sample frequency. Press ?Start?.? Buffer should start running data, Polybench should show data of first four channels.
%	?	On main machine, start Matlab, run this code. Make sure the src variable is set according to the Windows machine?s IP address (IPv4-address). ?The variable ?dst? specifies the location at which the buffer can be found (e.g., BrainStream project). Matlab should start running data.
% NOTES
%	?	Trigger pulse can be viewed using quick_buffer_viewer_raw at braintream/resources/start_scripts or StartBufferViewer at buffer_bci/dataAcq.

clean = onCleanup(@()cleanup()); % executes at cleanup of local variable clean

curdir = fileparts(mfilename('fullpath'));
bsdir = fullfile('..','..','..','..','..','toolboxes','brainstream','core');

% Default source
if nargin<1||isempty(src)
    src = [];
    fprintf('Trying noisetagging setup 1 ...\n');
    [ret,msg1] = system('ping -c1 -t1 169.254.26.40');
    if ~ret % source was found
        fprintf('Noisetagging acquisition computer found at 169.254.26.40\n');
        src = 'buffer://169.254.26.40:1972'; % setup 2
    else % try second noisetagging setup
        fprintf('Trying noisetagging setup 2 ...\n');
        [ret,msg2] = system('ping -c1 -t1 169.254.62.114');
        if ~ret % source was found
            fprintf('Noisetagging acquisition computer found at 169.254.62.114\n');
            src = 'buffer://169.254.62.114:1972'; % setup 2
        else
            fprintf('Trying noisetagging setup 3 ...\n');
            [ret,msg2] = system('ping -c1 -t1 169.254.34.46');
            if ~ret % source was found
                fprintf('Noisetagging acquisition computer found at 169.254.34.46\n');
                src = 'buffer://169.254.34.46:1972'; % setup 3
            end
        end
    end
    if isempty(src)
        fprintf('Failed connecting to data acquisition computer:\n');
        disp(msg1);
        disp(msg2);
        return
    end
end
% Default destiny
if nargin<2||isempty(dst)
    dst = 'buffer://localhost:1973';
end
if nargin<3 
    num_forwarded_eeg_channels = [];
end

% Add brainstream to path
%cd('~/bci_code/toolboxes/brainstream/core/');
cd(bsdir)
bs_addpath;

% Add trigger options
trigger = [];
trigger.fun = 'get_tmsi_mobita_triggers';
trigger.cfg.channel = 33;

% Start buffer
if isempty(num_forwarded_eeg_channels)
    ft2ft(src,dst,trigger);
else
    ft2ft(src,dst,trigger,num_forwarded_eeg_channels+1:32);
end


end

function cleanup
% make sure to set folder back to where this function resides
cd(fileparts(mfilename('fullpath')))
end
