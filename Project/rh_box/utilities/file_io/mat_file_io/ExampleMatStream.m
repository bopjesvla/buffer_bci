% test subsequently writing of data blocks (of arbitrary size) to matfile
% which in the end contains a matrix with an extra dimension compared to
% the fixed sized data blocks.
% For instance writing 10 data blocks of size (M x N x P x Q x R) will
% result in a matrix sized: (M x N x P x Q x R x 10)
addpath(fileparts(mfilename('fullpath')));

% set dimensions (just take 3 in this example)
M=7;
N=5;
P=3;
% create two different data blocks for testing
a=single(rand(M,N,P));
b=-a;

% mat filename
fn_mat = [pwd filesep 'mymatrix.mat'];
% name of the variable stored in the mat file
varname = 'mymatrix';

% Initialize a stream for writing the data
stream = InitMatStream(fn_mat,varname,[M,N,P],'single',1);
% add the first data block
stream = AddMatStream(stream,a);
% add the second data block
stream = AddMatStream(stream,b);
% add as many as you like (up to a maximum of 2GByte!)
%   :
%   :

% close the stream
stream=CloseMatStream(stream);

% read the matrix from the matfile completely at once using native Matlab load function
load(fn_mat) % matrix variable now available

% read the matfile block-wise fashion using custom developed directly matrix access function
% get a file structure for reading the matfile
matmatrixfile = OpenMatMatrix(fn_mat,varname);
numepochs = matmatrixfile.numberofepochs;
% create an empty matrix and fill it with data from the mat-file
data=zeros(M,N,P,numepochs,'single');
for n = 1 : numepochs,
	data(:,:,:,n) = GetMatMatrix(matmatrixfile,n);
end
% compare both reading options
equal = eval(['isequal(' varname ',data)']);
if equal
	disp('test successful!');
else
	disp('error: different results for both reading options!');
end
matmatrixfile = CloseMatMatrix(matmatrixfile);

