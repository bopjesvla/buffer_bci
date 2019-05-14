function header = WriteToMatFile(data,matfilename)
% for instance chans x samples x sequences (trials)
datasize = size(data);

miINT8=1;
miINT32=5;
miUINT32=6;
miSINGLE = 7;
miDOUBLE=9;
miMATRIX = 14;

mxDOUBLE = 6;
mxSINGLE = 7;

[p,varfilename] = fileparts(matfilename);
fid = fopen([varfilename '.mat'],'w','ieee-le');
num = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% Header %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
header = zeros(1,128,'uint8');
header(1,1:116) = 32; % fill text with spaces
txt = ['MATLAB 5.0 MAT-file, Platform: MACI, Radboud Universtiy Nijmegen (NICI department), Created on: ' datestr(now)];
header(1:length(txt)) = uint8(txt);
header(1,125:126) = [0, 1];
header(1,127:128) = uint8('IM');
num=num+fwrite(fid,header(1:128),'uint8');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% Data element %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
num=num+4*fwrite(fid,miMATRIX,'uint32'); % type miMATRIX = 14
lenoffset = num;
fwrite(fid,0,'uint32'); %(133:136) = #bytes all subelements update this at end!!
% reset, start counting number of bytes in all subelements
num = 0; 

%%%%%%%%%%%%%%%%% Subelements %%%%%%%%%%%%%%%
%%% Array flags subelement
num=num+4*fwrite(fid,miUINT32,'uint32'); % data type: miUINT32=6 
num=num+4*fwrite(fid,8,'uint32'); % size
% data
num=num+4*fwrite(fid,mxDOUBLE,'uint32');
num=num+4*fwrite(fid,0,'uint32'); %undefined

%%% Dimension Array subelement
num=num+4*fwrite(fid,miINT32,'uint32'); % data type miINT32=5
numdimensions = length(datasize);
% DON'T include padded values in size
num=num+4*fwrite(fid,numdimensions*4,'uint32');
for n = 1 : numdimensions,
	num=num+4*fwrite(fid,datasize(n),'int32');
end
if mod(numdimensions,2),
	num=num+4*fwrite(fid,0,'int32'); % PADDING required
end

%%% Array Name subelement
len = length(varfilename);
num=num+4*fwrite(fid,miINT8,'uint32'); % data type miINT8=1
num=num+4*fwrite(fid,len,'uint32'); % size (NB: check for sizes > 256!!!)
% data
num=num+fwrite(fid,uint8(varfilename),'uint8'); % data
padding = ceil(len/8)*8-len;
num=num+fwrite(fid,zeros(1,padding,'uint8'),'uint8'); % PADDDING

%%% Data subelement
num=num+4*fwrite(fid,miDOUBLE,'uint32'); % % data type miDOUBLE=9 
num=num+4*fwrite(fid,numel(data)*8,'uint32'); % size
num=num+8*fwrite(fid,data(:),'double'); % data itself (stored column wise!!)
% num=num+8*fwrite(fid,data(:,:,1),'double'); % data itself (stored column wise!!)
% num=num+8*fwrite(fid,data(:,:,2),'double'); % data itself (stored column wise!!)


% write number of bytes to Data element
fseek(fid,lenoffset,-1);
fwrite(fid,num,'uint32');
fclose(fid);
header = char(header);
%fi = fopen('matrix.mat','r','ieee-le');
%res=fread(fi,inf,'uint8');

