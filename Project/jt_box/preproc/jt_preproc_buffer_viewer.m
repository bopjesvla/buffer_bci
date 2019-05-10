function [state,dat,hdr,evt] = jt_preproc_buffer_viewer(state,dat,hdr,evt)
%[state,dat,hdr,evt] = jt_preproc_buffer(state,dat,hdr,evt)
% Preprocessing pipeline directly on the buffer. Follows: linear detrend, 
% CAR, spectral filter and downsample.

% Initalise filter states
if state.init
    state.flt1 = [];
    state.flt2 = [];
%    state.rawstate = state;
end

% Detrend
[state,dat] = rjv_detrend(state,dat,hdr);

% also plot bcd figures for raw data (only detrended)
%state.rawstate.detrend = state.detrend;
%[state.rawstate, ~] = rjv_bcd(state.rawstate,dat,hdr,[]);
%[state.rawstate]   = rjv_bcd_plot_biosemi_active2(state.rawstate,hdr);
%state.rawstate.init = 0;

% Re-reference
%[state,dat] = rjv_car(state,dat);

% Spectral filter
% Set parameters to empty if they are not defined, they will then be set to the default
if ~isfield(state.filter,'hptype')
   state.filter.hptype = [];
end
if ~isfield(state.filter,'lptype')
   state.filter.lptype = [];
end
if ~isfield(state.filter,'hporder')
   state.filter.hporder = [];
end
if ~isfield(state.filter,'lporder')
   state.filter.lporder = [];
end
if ~isfield(state.filter,'lpstopbandattenuation')
   state.filter.lpstopbandattenuation = [];
end
if ~isfield(state.filter,'hpstopbandattenuation')
   state.filter.hpstopbandattenuation = [];
end
[state.flt1,dat(state.eegchans,:)] = rjv_filter(state.flt1,dat(state.eegchans,:),'hpf',hdr.Fs,state.filter.hpf,state.filter.hporder,state.filter.hptype,1,2);
[state.flt2,dat(state.eegchans,:)] = rjv_filter(state.flt2,dat(state.eegchans,:),'lpf',hdr.Fs,state.filter.lpf,state.filter.lporder,state.filter.lptype,1,2,state.filter.lpstopbandattenuation);

[state evt]         = rjv_bcd(state,dat,hdr,evt);
[state]             = rjv_bcd_plot_biosemi_active2(state,hdr);

% Downsample
[state,dat,hdr,evt] = rjv_downsample(state,dat,hdr,evt);