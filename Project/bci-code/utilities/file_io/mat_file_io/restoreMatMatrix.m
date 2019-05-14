% Fixes non-readable mat-file saved with previous version of AddMatStream
% which didn't properly padd the end of the matrix to a 64-bit boundary. If
% the number of data points is not an even number, this bug prevented you
% from reading the saved mat-file at once using native Matlab load function.
% Use this function to save the data again ('_restored' is added to the
% name of the file) in order to allow Matlab to load it correctly.
% The data is anyway readable from the original file using the GetMatMatrix
% function (only on epoch basis).
%
% Use: restoreMatMatrix('myfile.mat')
% to make 'myfile_restored.mat', which is then readable by Matlab 
function restoreMatMatrix(file)

stream = OpenMatMatrix(file,[]);
fclose(stream.fid);

if mod(stream.numberofsubelementsbytes,8)
	disp('Restore required');
	% since only single or doubles, always multiple of 4 bytes
	paddBytes = 8-mod(stream.numberofsubelementsbytes,8);

	% padding required, make restored copy of the data
	[p,f,e] = fileparts(file);
	fn = fullfile(p,[f '_restored' e]);
	success = copyfile(file,fn);
	if ~success
		error('Failed copying original file before restore could be executed');
	end
	% open copied file and overwrite number of bytes in data element
	pos = stream.matrixdataelementstartoffset-4; % position in file of spec. # bytes in data element
	fid = fopen(fn,'r+','ieee-le');
	if fid < 0
		error('Restore failed: opening copied mat-file failed');
	end
	fseek(fid,pos,'bof');
	fwrite(fid,stream.numberofsubelementsbytes+paddBytes,'int32');
	% add the padding bytes
	fseek(fid,0,'eof'); % to end of file
	padd = zeros(1,paddBytes,'uint8');
	fwrite(fid,padd(:),'uint8');
	fclose(fid);
	disp(['Restored file: ' fn])
else
	disp('File doesn''t need to be restored, should be readable by Matlab load command');
end
