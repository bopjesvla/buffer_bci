function [mf, newdata] = ReadMemBDFFile(mf,offset)
%memfile: memory mapped file object
%offset: file position from where to start reading data

% set file read start position
mf.file.Offset = offset;

% % % add extra 4th zero byte to change 3-byte (24bit) to 4-byte (32bit) sequence
bytebuffer = zeros(mf.buffersize,'uint8'); % temporary buffer used to change from 24bit to 32bit data
% put bdf 3-bytes data on its proper place to complete 32-bits data
bytebuffer(2:end,:)=mf.file.Data(1).raw;

% if running on mac (powerpc) reverse byte ordering
if mf.lowendian
	bytebuffer = bytebuffer([4 3 2 1],:);
end

% - typecast/convert to int32,
% - reshape to  nchan x nsaples matrix
% - calibrate the data
% - convert to singles
%   ( inbetween doubles required for sparse matrix )
epochlength = mf.hdr.orig.SPR(1);
newdata = single(mf.calib * ...
	double(reshape((typecast((uint8(bytebuffer(:))),'int32'))/256, ...
	epochlength, length(mf.chanindx)))');

% copy to buffer if enabled
% update tells where to copy this record in the Nrec length buffer
mf.buf.update = mf.buf.update + 1;
mf.buf.update = mod(mf.buf.update-1,mf.buf.Nrec)+1;
% update the list to remember which bdf records are currently backuped
if mf.buf.Nrec % check if buffering is used
	mf.buf.data(mf.buf.update).recindex = mf.rec;
	mf.buf.data(mf.buf.update).data = newdata;
end
