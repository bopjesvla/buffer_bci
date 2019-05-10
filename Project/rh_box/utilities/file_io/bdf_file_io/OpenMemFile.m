function memfile = OpenMemFile(filename,format)
if isempty(filename) || ~exist(filename,'file')
	error('Filename not found!');
end
memfile = memmapfile(filename,'Format',format,'Offset',0,'Repeat',1);



