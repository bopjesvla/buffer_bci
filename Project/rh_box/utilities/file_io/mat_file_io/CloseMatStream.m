function matstream = CloseMatStream(matstream)

% number of bytes must end on 64-bit boundary, check if padding is
% necessary
paddMatrix

fseek(matstream.fid,matstream.lenoffset,-1);
fwrite(matstream.fid,matstream.numelements,'uint32');

fseek(matstream.fid,matstream.lastdimoffset,-1);
fwrite(matstream.fid,matstream.lastdimsize,'int32');

fseek(matstream.fid,matstream.numdataoffset,-1);
fwrite(matstream.fid,matstream.numdatasize,'int32');

fclose(matstream.fid);
matstream.closed = true;
disp(['Streaming to mat-file: ' matstream.filename ' closed']);

	function paddMatrix
		paddBytes = 8-mod(matstream.numelements,8);
		% since only single or doubles, always multiple of 4 bytes
		if paddBytes ~= 8
			padd = zeros(1,paddBytes,'uint8');
			fwrite(matstream.fid,padd(:),'uint8');
		end
	end

end
