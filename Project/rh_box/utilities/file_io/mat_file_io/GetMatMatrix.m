function data = GetMatMatrix(mmf,epoch)
% mmf shortcut for matmatrixfile 
if mmf.fid < 0
	error('Corrupt mat-file identifier');
end
if epoch > mmf.numberofepochs
	error('Epoch beyond matrix data size!');
end
numsamples = prod(mmf.datasize(1:end-1)); 
epochsize = numsamples*mmf.precsize;
% seek to beginning of actual matrix data in file
offset = mmf.matrixdatastartoffset + (epoch-1)*epochsize;
fseek(mmf.fid,offset,-1);
data = fread(mmf.fid,numsamples,mmf.precision);
data = reshape(data,mmf.datasize(1:end-1)');
