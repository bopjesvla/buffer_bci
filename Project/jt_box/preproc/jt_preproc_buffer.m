function [state,dat,hdr,evt] = jt_preproc_buffer(state,dat,hdr,evt)
%[state,dat,hdr,evt] = jt_preproc_buffer(state,dat,hdr,evt)
% Preprocessing pipeline directly on the buffer. Follows: linear detrend, 
% CAR, spectral filter and downsample.

% Initalise filter states
if state.init
    state.flt1 = [];
    state.flt2 = [];
end

% Detrend
[state,dat] = rjv_detrend(state,dat,hdr);

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

% Downsample
[state,dat,hdr,evt] = rjv_downsample(state,dat,hdr,evt);