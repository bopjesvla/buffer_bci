function [cov]=taucov(X,dim,taus,varargin);
% compute set of time-shifted covariance matrices
%
%  [cov]=taucov(X,dim,taus,...)
%
%  For each tau compute the covariance between all the input channels and there time-lagged versions:
%  i.e. cov(:,:,tau) = \sum_d x(t) x(t-tau)'
%
% Input:
%  
% Inputs:
%  X   -- [n-d] data to compute the lagged covariances of
%  dim -- spec of the dimensions to compute covariances matrices
%         dim(1)=dimension to compute covariance over
%         dim(2)=dimension to sum along + compute delayed covariance, i.e. time-dim
%         dim(3:end)=dimensions to average covariance matrices over
%  taus-- [nTau x 1] set of sample offsets to compute cross covariance for
% Options:
%  type-- type of covariance to compute, one-of                ('real')
%          'real' - pure real, 'complex' - complex, 'imag2cart' - complex converted to real
%  shape-- shape of output covariance to compute   ('3d')
%         one-of; '3da' - [d x d x nTau] non-symetric, 
%                 '3ds'/'3d' - [d x d x nTau] symetric (fixs some numerical problems)
%                 '2d' - [d*nTau x d*nTau]
%  normalize -- one of 'none','mean','unbiased'
% Output:
%  cov -- [as defined by shape].  For each tau we get a [dxd] matrix cov_tau = 
opts=struct('type','real','shape','3ds','normalize','mean');
opts=parseOpts(opts,varargin);
if ( nargin<3 || isempty(taus) ) taus=0; end;

szX=size(X); nd=ndims(X);
% Map to co-variances, i.e. outer-product over the channel dimension
didx1=1:max([ndims(X);dim(:)+1]); 
% insert extra dim for OP and squeeze out accum dims
shifts=zeros(size(didx1)); shifts(dim(2:end))=-1; % squeeze out accum
shifts(dim(1)+1)=shifts(dim(1)+1)+2; % insert for OP, and for taus
didx1=didx1 + cumsum(shifts);
didx1(dim(2:end))=-dim(2:end);  % mark accum'd
didx2=didx1; didx2(dim(1))=didx2(dim(1))+1;

idx={}; for d=1:ndims(X); idx{d}=1:szX(d); end; idx2=idx; % index into X with offset tau
cov=[]; % sould really pre-allocate....
for ti=1:numel(taus);
  tau=taus(ti); % current offset
  idx{dim(2)} =1:szX(dim(2))-tau; % shift pts in cov-comp
  idx2{dim(2)}=tau+1:szX(dim(2));  
  if ( isreal(X) ) % include the complex part if necessary
    %covtau = tprod(real(X(idx{:})),didx1,X(idx2{:}),didx2);
    % avoid a double sub-set, uses less ram + faster...
    X2=X; if ( tau~=0 ) X2=cat(dim(2),X(idx2{:}),zeros([szX(1:dim(2)-1) tau szX(dim(2)+1:end)])); end;
    covtau = tprod(real(X),didx1,X2,didx2,'n');
  else
    switch (opts.type);
     case 'real';    % pure real output
      X2=X; if ( tau~=0 ) X2=cat(dim(2),X(idx2{:}),zeros([szX(1:dim(2)-1) tau szX(dim(2)+1:end)])); end;      
      covtau = tprod(real(X),didx1,real(X2),didx2,'n') + tprod(imag(X),didx1,imag(X2),didx2,'n');
     case {'complex','imag2cart'} % pure complex, N.B. need complex conjugate!
      %covtau = tprod(real(X),didx1,cat(dim(2),X(idx2{:}),zeros([szX(1:dim(2)-1) tau szX(dim(2)+1:end)])),didx2);
      X2=X; if ( tau~=0 ) X2=cat(dim(2),X(idx2{:}),complex(zeros([szX(1:dim(2)-1) tau szX(dim(2)+1:end)]))); end;
      covtau = tprod(X,didx1,conj(X2),didx2,'n');
      if ( strcmp(opts.type,'imag2cart') ) % map into equivalent pure-real covMx
        rcovtau=real(covtau); 
        icovtau=imag(covtau); if(isempty(icovtau)) icovtau=zeros(size(covtau),class(covtau)); end;
        covtau = cat(dim(1)+1,cat(dim(1),rcovtau,icovtau),cat(dim(1),-icovtau,rcovtau));% unfold to double size
        clear rcovtau icovtau;
      end
     otherwise; error('Unrecognised type of covariance to compute');
    end
  end
  clear X2;
  if ( numel(dim)>1 ) 
    switch ( opts.normalize )
     case 'mean';      covtau=covtau/prod(szX(dim(2:end))); 
     case 'unbiased';  covtau=covtau.*szX(dim(2))./(szX(dim(2))-tau);
     case 'none';
      otherwise; error('Unrec normalize type: %s',opts.normalize);
    end
  end
  cov=cat(dim(1)+2,cov,covtau); % accumulate the cov mxs
end
switch (opts.shape);
 case '3da';  % do nothing
 case {'3d','3ds'}; % symetrize the delayed versions
  idx={}; for d=1:ndims(cov); idx{d}=1:size(cov,d); end;
  for ti=1:numel(taus);
    idx{dim(1)+2}=ti;
    covtau = cov(idx{:})/2;
    cov(idx{:}) = covtau + permute(covtau,[1:dim(1)-1 dim(1)+1 dim(1) dim(1)+2:ndims(covtau)]);
  end
  clear covtau;
 case '2d'; % un-fold into 2d matrix equivalent
  if ( dim(1) ~= 1 ) error('Not supported for dim(1)~=1 yet!, sorry'); end;
  szcov=[size(cov) 1 1];
  szBlk=szcov(1); iis=1:szBlk; % block indices
  nBlk =szcov(3); % num blocks = num taus

  tcov=cov; % copy the 3d version to fill in from
  cov =zeros([szBlk*nBlk,szBlk*nBlk,prod(szcov(4:end))],class(tcov));
  % fill in block diag structure
  for ti=1:nBlk; % horz blocks
    for tj=1:ti-1; % vert blocks > above main diag
      taui=abs(ti-tj)+1; % what tau goes in this place
      cov((ti-1)*szBlk+(iis),(tj-1)*szBlk+(iis),:)=tcov(:,:,taui,:);
    end;
    taui=1; cov((ti-1)*szBlk+(iis),(ti-1)*szBlk+(iis),:)=squeeze(tcov(:,:,taui,:)); % main diag
    for tj=ti+1:nBlk; % vert blocks, below main diag -> transposed
      taui=abs(ti-tj)+1; % what tau goes in this place
      for k=1:size(cov,3);
        cov((ti-1)*szBlk+(iis),(tj-1)*szBlk+(iis),k)=tcov(:,:,taui,k)';
      end
    end
  end
  cov=reshape(cov,[szBlk*nBlk,szBlk*nBlk,szcov(4:end)]);
  clear tcov;
end
return;
%-----------------------------------------------------------------------
function testCase()
X=randn(10,100,100);
C=taucov(X,[1 2 3],[0 1 2])

clf;jplot([z.di(1).extra.pos2d],shiftdim(mdiag(sum(t.X,4),[1 2])))