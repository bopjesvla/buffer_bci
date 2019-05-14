function [X,dtm]=linDetrend(X,dim,wght,MAXEL)
% Linearly de-trend input, i.e. 0-mean and linear trends subtracted
%
% [X,dtm]=linDeTrend(X,[dim,wght,MAXEL])
%
% Inputs:
%  X     -- n-d input matrix
%  dim   -- dimension of X to detrend along
%  wght  -- [size(X,dim),1] weighting matrix for the points in X(dim)
%  MAXEL -- max-size before we start chunking for memory savings
% Outputs:
%  X     -- detrended X
%  dtm   -- linear matrix used to detrend X
if ( nargin < 2 || isempty(dim) ) dim=find(size(X)>1,1,'first'); end;
if ( dim < 0 ) dim=ndims(X)+dim+1; end;
if ( nargin < 3 || isempty(wght) ) wght=1; end; wght=wght(:);
if ( nargin < 4 || isempty(MAXEL) ) MAXEL=2e6; end;

% Compute a linear detrending matrix
xb  = [(1:size(X,dim))' ones(size(X,dim),1)];
xbw = repop(xb,'.*',wght); % include weighting effect
dtm = inv([ xbw(:,1:end-1)'*xb(:,1:end-1) xbw(:,1:end-1)'*xb(:,end);
            xbw(:,end)'*xb(:,1:end-1)     xbw(:,end)'*xb(:,end)])*xbw';

szX=size(X);
[idx,chkStrides,nchks]=nextChunk([],szX,dim,MAXEL);
while ( ~isempty(idx) ) 
   % comp scale and bias
   ab  = tprod(double(X(idx{:})),[1:dim-1 -dim dim+1:ndims(X)],dtm,[dim -dim],'n'); 
   % comp linear trend
   Xest= tprod(xb,[dim -dim],ab,[1:dim-1 -dim dim+1:ndims(X)],'n');
   X(idx{:})=X(idx{:})-Xest; % remove linear trend
      
   idx=nextChunk(idx,szX,chkStrides);
end   

return;

%-----------------------------------------------------------------------------
function testCase()
f=cumsum(randn(1000,100)); dim=1;

clf; plot(f(:,1),'b'); hold on;

ff=linDetrend(f,1); % normal

ff=linDetrend(f,1,[1 zeros(1,size(f,1)-2) 1]); % weighted

ff=linDetrend(f,1,[1 ones(1,size(f,1)-2)*5e-2 1]); % weighted

ff=linDetrend(f,1,[1 zeros(1,size(f,1)-2) 1],2000); % chunked

plot(ff(:,1),linecol());