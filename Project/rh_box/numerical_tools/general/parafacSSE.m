function [sse,ssep]=parafacSSE(A,varargin);
% compute the sse for the given parafac fit to the tensor A
%
%  [sse,ssep]=parafacSSE(A,S,U1,U2,...,UN);
%
% 
if ( numel(varargin)==1 && iscell(varargin{1}) ) varargin=varargin{1}; end;
A2 = A(:)'*A(:);
S=varargin{1};
U=varargin(2:end);
nd=ndims(A);
if ( numel(U) ~= nd ) error('U has different nubmer of dims than A'); end;
% compute the inner products we need
UU=1; AU=A;
for d=1:nd;  % compute AU, and UU
  AU = tprod(AU,[1:d-1 -d d+1:nd nd+1:ndims(AU)],U{d},[-d nd+1],'n'); 
  UU = UU.*tprod(U{d},[-1 1],U{d},[-1 2],'n');
end   
sse = A2 - 2*sum(shiftdim(AU)'*S(:)) + S(:)'*UU*S(:); % N.B. include component scaling
ssep= sse./A2;
return;
%-----------------------------------------
function testCase()
A=randn(10,9,8);
[P{1:4}]=parafac_als(A,3);
parafacSSE(A,P{:})