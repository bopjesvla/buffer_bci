function matmatrixfile = OpenMatMatrix(matfilename,varname)
% constants for reading mat-file
% array data types
%miINT8=1;
%miINT32=5;
%iUINT32=6;
miSINGLE = 7;
miDOUBLE=9;
miMATRIX = 14;
% matrix data types
mxDOUBLE = 6;
mxSINGLE = 7;

fid =  fopen(matfilename,'r','ieee-le');
if fid < 0
	error(['Opening file ' matfilename ' failed!']);
end
if nargin < 2, varname = []; end

% check internal written matfile
txt = 'MATLAB 5.0 MAT-file, Platform: MACI, Radboud Universtiy Nijmegen (NICI department)';
tagtxt = fread(fid,length(txt),'*char');
if ~strcmp(tagtxt',txt)
	fclose(fid);
	error('Reading of non-internal created mat-files is not supported!');
end
txt = fread(fid,128-length(txt),'*char');
vtxt = cell2mat(regexp(txt','\(v.*\)','match'));
vtxt(vtxt=='(' | vtxt==')' | vtxt=='v') = [];
try
	VERSION = str2double(vtxt); % for future use
catch
	VERSION = 1.0; % for files without a version number
end

% mat-file is internally created, thus version and endian indicator settings are always set correctly
num = 128; % set file position after header
fseek(fid,num,-1);

try
datatype = 0;
while datatype ~= miMATRIX,
	[datatype, nrd] = fread(fid,1,'uint32'); num = num + 4*nrd;
	[numberofbytes, nrd] = fread(fid,1,'uint32'); num = num + 4*nrd;
	if datatype == miMATRIX,
		matmatrixfile.numberofsubelementsbytes = numberofbytes;
		matmatrixfile.matrixdataelementstartoffset = ftell(fid);
		break;
	end
	fseek(fid,numberofbytes,0); % increase file position with <numberofbytes>
	num = num + numberofbytes; 
end
catch
	error('Matrix was not found!');
end

% check name of matrix variable
%%%%%%%%%%%%%%%%% Subelements %%%%%%%%%%%%%%%
%%% Array flags subelement
fread(fid,1,'uint32'); % data type: miUINT32=6 
fread(fid,1,'uint32'); % size
% data
mxprecision = fread(fid,1,'uint32');
if mxprecision ~= mxDOUBLE && mxprecision ~= mxSINGLE
	fclose(fid);
	error('Precision of matrix in mat-file not supported');
end
if mxprecision == mxDOUBLE, mxprecision = 'double'; end
if mxprecision == mxSINGLE, mxprecision = 'single'; end
fread(fid,1,'uint32'); %undefined

%%% Dimension Array subelement
fread(fid,1,'uint32'); % data type miINT32=5
% DON'T include padded values in size
numdimensions = fread(fid,1,'uint32')/4;
datasize = fread(fid,numdimensions,'int32');
if mod(numdimensions,2),
	fread(fid,1,'int32'); % skip PADDING
end

%%% Array Name subelement
fread(fid,1,'uint32'); % data type miINT8=1
len = fread(fid,1,'uint32'); % size (NB: check for sizes > 256!!!)
% data
name = fread(fid,len,'*char'); % data
padding = ceil(len/8)*8-len;
fseek(fid,padding,0); % skip PADDDING
if isempty(varname), varname = name'; end
if ~strcmp(name',varname)
	warning('MATLAB:OpenMatMatrix','Different name for the matrix found');
	varname = name;
end

%%% Data subelement
miprecision = fread(fid,1,'uint32');
if miprecision ~= miDOUBLE && miprecision ~= miSINGLE
	fclose(fid);
	error('Precision of array in mat-file not supported');
end
if miprecision == miDOUBLE, miprecision = 'double'; end
if miprecision == miSINGLE, miprecision = 'single'; end
if ~strcmp(miprecision,mxprecision)
	error('compressed formats not supported');
end
precision = miprecision;
if strcmpi(precision,'single')
	precsize = 4;
end
if strcmpi(precision,'double')
	precsize = 8;
end

numberofelementsbytes = fread(fid,1,'uint32'); % size
numberofsamples = numberofelementsbytes/precsize; 
matmatrixfile.matrixdatastartoffset = ftell(fid);

matmatrixfile.closed = 0;
matmatrixfile.fid = fid;
matmatrixfile.matrixdatastartoffset = ftell(fid);
matmatrixfile.precision = precision;
matmatrixfile.precsize = precsize;
matmatrixfile.numdimension = numdimensions;
matmatrixfile.datasize = datasize;
matmatrixfile.varname = varname;
matmatrixfile.numberofsamples = numberofsamples;
matmatrixfile.numberofepochs = datasize(end);

