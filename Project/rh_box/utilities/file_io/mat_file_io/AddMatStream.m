function matstream = AddMatStream(matstream,data)


if isempty(matstream)
	errmsg('Empty stream');
end
if ~isfield(matstream,'fid') || matstream.fid < 0
	errmsg('can not add data to stream');
end
if ~strcmpi(matstream.precision,class(data))
	errmsg(['Mismatch in data type, ' matstream.precision ' expected, however, ' class(data) ' presented']);
end
datasize = size(data);
if ~isequal(matstream.datasize,datasize)
	errmsg('Different data dimension(s)');
end
bytestoadd = numel(data)*matstream.precsize;
matrixsize = matstream.numelements + bytestoadd;
if matrixsize > 2^31-1
	errmsg('Size of matrix has reached its maximum (2Gb)');
end

num = matstream.precsize*fwrite(matstream.fid,data(:),matstream.precision); % data itself (stored column wise!!)
matstream.numelements = matstream.numelements + num;
matstream.lastdimsize = matstream.lastdimsize + 1;
matstream.numdatasize = matstream.numdatasize + num;

function errmsg(err)
	matstream = CloseMatStream(matstream);
	error(err);
end

end
