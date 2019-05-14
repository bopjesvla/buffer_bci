% Funcion for reading biosemi BDF data format
% Usage:
%	1) dat = read_biosemi_bdf_memmap(filename, chanidxs)
%	first call read_biosemi_bdf_memmap to specify filename and channels to
%	read (arbitrary number of channels can be specified, but inbetween gaps
%	in this range are not allowed
%	filename: bdf-datafile to read
%	chanidxs: selected channels (fixed for follow up data calls)
%	2) [mf dat] = read_biosemi_bdf_memmap(mf, begsample, endsample, dat)
%	in follow-up calls, data for the specified channels between specified
%	sample range will be returned
%	mf			: memory mapped file structure/object
%	begsample:	: index of first sample to read
%	endsample:	: index of last sample to read

function [mf, dat] = read_biosemi_bdf_memmap(varargin)
% varargin if nargin >= 3	: mf, begsample, endsample
% varargin if nargin < 3	: filename, chanidxs

% read bdf header and set memory maped file structure
if nargin < 3
	if nargin < 1
		error('MATLAB:read_biosemi_bdf_memmap','Missing arguments filename');
	end
	filename = varargin{1};
	% set memory mapped file structure
%	mf.hdr = read_biosemi_bdf(filename);
	mf.hdr = read_header(filename);
	fclose(mf.hdr.orig.FILE.FID);
	if nargin < 2
		channelidxs = 1:mf.hdr.orig.NS; % if not defined set to all channels
	else
		channelidxs = varargin{2};
	end
	if ischar(channelidxs)
		if strcmpi(channelidxs,'end')
			channelidxs = mf.hdr.orig.NS;
		end
	end
	if any(diff(channelidxs) ~= 1)
		error('MATLAB:read_biosemi_bdf_memmap','Only reading of subsequent channels is supported!');
	end
	mf.chanindx = channelidxs;
	if length(unique(mf.hdr.orig.SPR)) > 1
		error('MATLAB:read_biosemi_bdf_memmap','Only files with equal sample rates for all channels are supported!');
	end
	nsamp = max(mf.hdr.orig.SPR);
	nchan = mf.hdr.orig.NS;
	if max(mf.chanindx) > nchan || min(mf.chanindx) < 1
		error('MATLAB:read_biosemi_bdf_memmap','Wrong channel index found');
    end
    
    % low-endian and high-endian difference between powerpc en intel-macs
    % perhaps other platforms (unix/pc) also need to be figured out!
    mf.lowendian = 0; % set default
    if strcmpi(computer,'mac'), mf.lowendian = 1; end

	% initialize memory mapped file object
	nrdchan = length(mf.chanindx); % number of channels to read from every bdf record
	format = {'uint8', [3 nrdchan*nsamp], 'raw'};
	mf.file = OpenMemFile(filename,format);

	% set size of temporary buffer used in ReadMemBDFFile to make the change from 24bit to 32bit data
	mf.buffersize = [4,nrdchan*nsamp];
	% set to zero if buffering is not appreciated (prevents multple readings AND conversions)
	mf.buf.Nrec = 2; % mf.buf.Nrec seconds buffer (every record is 1 sec. long for biosemi data)
	for n = 1 : mf.buf.Nrec, 
		mf.buf.data(n).data= zeros(1,nrdchan*nsamp,'single'); % buffer to hold converted data
		mf.buf.data(n).recindex = [];
	end
	
	% intialize calibration matrix
	% Calibrate the data (dat=mf.calib*dat)
	if length(mf.chanindx)>1
		% using a sparse matrix speeds up the multiplication
		mf.calib = sparse(double(diag(mf.hdr.orig.Cal(mf.chanindx,:))));
	else
		% in case of one channel the calibration would result in a sparse array
		mf.calib = double(diag(mf.hdr.orig.Cal(mf.chanindx,:)));
	end
	
	% get number of bytes actually in file
	FileInfo = dir(mf.file.Filename);
	mf.Filesize = FileInfo.bytes; 

	mf.buf.update = 0; % points to data buffer that should be updated if new data is being read
	mf.rec = []; % current record index of data requested
	dat = [];
else
	% varargin if nargin >= 3
	% mf, begsample, endsample
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% read the data
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	mf = varargin{1};
	begsample = varargin{2};
	endsample = varargin{3};
	hdr = mf.hdr;
	if ~isfield(mf,'chanindx')
		error('MATLAB:read_biosemi_bdf_memmap','Channels to read not correctly initialized');
	end
	% determine the trial containing the begin and end sample
	epochlength = hdr.orig.SPR(1); %hdr.nSamples;
	%nr_channels=length(mf.chanindx);
	begepoch    = floor((begsample-1)/epochlength) + 1;
	endepoch    = floor((endsample-1)/epochlength) + 1;
	nepochs     = endepoch - begepoch + 1;
	dat         = zeros(length(mf.chanindx),nepochs*epochlength,'single');

	% read and concatenate all required data epochs
	for rec=begepoch:endepoch
		mf.rec = rec;
		% check if this bdf-record was already read before
		recidx = [];
		if mf.buf.Nrec % check only if buffering is used
			recidx = find([mf.buf.data.recindex] == rec,1);
		end
		if isempty(recidx) % buffering disabled or no buffered record found
			% not a buffered record, read from file
			offset = hdr.orig.HeadLen + ...
				(rec-1)*3*hdr.nChans*epochlength + ...
				3*(mf.chanindx(1)-1)*epochlength;
			
			% check for reading beyond filesize
			if offset + prod(mf.file.Format{2}) > mf.Filesize
				warning('MATLAB:read_biosemi_bdf_memmap','Reading data beyond file size!');
				dat = [];
			else			
				[mf, newdata] = ReadMemBDFFile(mf, offset);
				dat(:,((rec-begepoch)*epochlength+1):((rec-begepoch+1)*epochlength)) = newdata;
			end
		else
			dat(:,((rec-begepoch)*epochlength+1):((rec-begepoch+1)*epochlength)) = ...
				mf.buf.data(recidx).data;
		end
	end
	% check reading data succeeded
	if isempty(dat)
		return
	end
	
	% select the desired samples
	begsample = begsample - (begepoch-1)*epochlength;  % correct for the number of bytes that were skipped
	endsample = endsample - (begepoch-1)*epochlength;  % correct for the number of bytes that were skipped
	dat = dat(:, begsample:endsample);
end
