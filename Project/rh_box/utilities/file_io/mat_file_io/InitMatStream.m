function matstream = InitMatStream(matfilename,varname,datasize,precision,overwrite)
% Note: datasize doesn't include the additional dimension which will 
% dynamically grow by repeated calls to AddMatStream!!
% add this dimension to datasize:
VERSION = '1.0';

if nargin < 5
	overwrite = 0;
end
datasize = [datasize 1];

miINT8=1;
miINT32=5;
miUINT32=6;
miSINGLE = 7;
miDOUBLE=9;
miMATRIX = 14;

mxDOUBLE = 6;
mxSINGLE = 7;

datatype = [];
arraytype= [];
if strcmpi(precision,'single')
	datatype = miSINGLE;
	arraytype= mxSINGLE;
	precsize = 4;
end
if strcmpi(precision,'double')
	datatype = miDOUBLE;
	arraytype= mxDOUBLE;
	precsize = 8;
end
if isempty(arraytype) || isempty(datatype)
	error('MATLAB:InitMatStream','unsupported precision');
end

[p,matfilename] = fileparts(matfilename);
name = [p filesep matfilename '.mat']; 
if ~overwrite && exist(name,'file')
	error('MATLAB:InitMatStream','Mat-file already exists!');
end
makeoutfolder(p);
fid = fopen(name,'w','ieee-le');
if fid < 0
	error('MATLAB:InitMatStream','creation of mat-file failed');
end
num = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% Header %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
header = zeros(1,128,'uint8');
header(1,1:116) = 32; % fill text with spaces
txt = ['MATLAB 5.0 MAT-file, Platform: MACI, Radboud Universtiy Nijmegen (NICI department), Created on: ' datestr(now) ' (v' VERSION ')'];
header(1:length(txt)) = uint8(txt);
header(1,125:126) = [0, 1];
header(1,127:128) = uint8('IM');
num=num+fwrite(fid,header(1:128),'uint8');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% Data element %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
num=num+4*fwrite(fid,miMATRIX,'uint32'); % type miMATRIX = 14
lenoffset = num; % offset in mat-file where to put size of Data element
num =num+4*fwrite(fid,0,'uint32'); %(133:136) = #bytes all subelements update this at end!!
subelementsbytesoffset = num; % store file position where to put number of bytes in all subelements
%num = 0; 

%%%%%%%%%%%%%%%%% Subelements %%%%%%%%%%%%%%%
%%% Array flags subelement
num=num+4*fwrite(fid,miUINT32,'uint32'); % data type: miUINT32=6 
num=num+4*fwrite(fid,8,'uint32'); % size
% data
num=num+4*fwrite(fid,arraytype,'uint32'); % array data type: mxSingle or mxDouble
num=num+4*fwrite(fid,0,'uint32');

%%% Dimension Array subelement
num=num+4*fwrite(fid,miINT32,'uint32'); % data type miINT32=5
numdimensions = length(datasize);
% DON'T include padded values in size
num=num+4*fwrite(fid,numdimensions*4,'uint32');
for n = 1 : numdimensions,
	lastdimoffset = num; % store file position where to put size of last dimension (the one growing)
	num=num+4*fwrite(fid,datasize(n),'int32');
end
if mod(numdimensions,2),
	num=num+4*fwrite(fid,0,'int32'); % PADDING required
end

%%% Array Name subelement
len = length(varname);
num=num+4*fwrite(fid,miINT8,'uint32'); % data type miINT8=1
num=num+4*fwrite(fid,len,'uint32'); % size (NB: check for sizes > 256!!!)
% data
num=num+fwrite(fid,uint8(varname),'uint8'); % data
padding = ceil(len/8)*8-len;
num=num+fwrite(fid,zeros(1,padding,'uint8'),'uint8'); % PADDDING

%%% Data subelement
num=num+4*fwrite(fid,datatype,'uint32'); % % data type miDOUBLE or miSingle 
numdataoffset = num; % store file position where to put size of data element (i.e., the data matrix itself)
num=num+4*fwrite(fid,0,'uint32'); % size at init is zero, adapt at closing file

%num=num+4*fwrite(fid,numel(data)*8,'uint32'); % size

matstream.closed = false;
matstream.filename = [matfilename '.mat'];
matstream.varname = varname;
matstream.fid = fid;
matstream.datasize = datasize(1:end-1);
matstream.precision = precision;
matstream.precsize = precsize;
matstream.lenoffset = lenoffset;
matstream.lastdimoffset = lastdimoffset;
matstream.numdataoffset = numdataoffset;
matstream.numelements = num - subelementsbytesoffset;
matstream.lastdimsize = 0;
matstream.numdatasize = 0;
