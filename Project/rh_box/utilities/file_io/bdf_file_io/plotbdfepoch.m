% rec: read one record (if zero, read all data records)
% ref: channels to be used for rereferencing (1:256 or 257:258)
% samples: number of samples to plot (if zero, plot all available)
% mf: memory map file structure
% usage:	mf = [];
%			mf = plotbdfepoch(filename,rec,ref,samples,mf);
function mf = plotbdfepoch(filename,rec,ref,samples,mf)
if samples < 0 
	error('Invalid number of samples  specified');
end
if isempty(mf)
	% set memory map file structure and select the number of channels to be read
	% at once for every record
	% only read the last=status channel
	mf = read_biosemi_bdf_memmap(filename);
	mf.handlecm = figure;
	title(filename);
	mf.handlesg = figure;
	title(filename);
end
if rec < 0 || rec > mf.hdr.orig.NRec
	error('Invalid epoch number specified');
end

conlabel={'conA','conB','conC','conD','conE','conF','conG','conH'};

nsamp = max(mf.hdr.orig.SPR);
sr = mf.hdr.Fs;

if rec == 0
	% get all data
	[mf, data] = read_biosemi_bdf_memmap(mf, 1, mf.hdr.orig.NRec*nsamp);
else
	[mf, data] = read_biosemi_bdf_memmap(mf, 1+(rec-1)*nsamp, rec*nsamp);
end
if samples == 0
	samples = size(data,2);
end
if samples > size(data,2)
	samples = size(data,2);
end

% take all channels
d=data(:,1:samples)';
% reference data
mn = mean(d(:,ref),2); % take mean over reference channels
num = size(d,2);
dr = d - repmat(mn,1,num);

% subtract mean
mn=mean(dr,1); 
dm=dr-repmat(mn,samples,1);

set(0,'CurrentFigure',mf.handlecm);
for c = 1 : 8,
	sb = subplot(4,2,c);
	plot((1:samples)./sr,d(1:samples,(c-1)*8+1:c*8)/1000)
	ylabel('EEG [mV]');
	xlabel('time [s]');
	title([char(conlabel(c)) ' (common mode)']);
end

set(0,'CurrentFigure',mf.handlesg);
for c = 1 : 8,
	sb = subplot(4,2,c);
	plot((1:samples)./sr,dm(1:samples,(c-1)*8+1:c*8))
	ylabel('EEG [uV]');
	xlabel('time [s]');
	title([char(conlabel(c)) ' eeg signal']);
end
