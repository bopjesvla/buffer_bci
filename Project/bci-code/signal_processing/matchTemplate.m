function [match,ip,ip2]=matchTemplate(X,temp,varargin);
% identify where template existing in the input data
opts=struct('dim',1,'thresh',.6,'absp',0,'centerp',1,'corr',1,'meanthresh',1);
opts=parseOpts(opts,varargin);
sz=size(X);
if ( opts.centerp ) X=repop(X,'-',mean(X,opts.dim)); end
ip=real(fftconv(X,temp,opts.dim)); % compute the inner product
% compute the local correlation
if ( opts.corr ) 
   varX= abs(real(fftconv(X.^2,ones(size(temp)),opts.dim)))./numel(temp); % local var
   nf  = (repop(sqrt(varX),'*',norm(temp))); nf(nf<eps)=1;
   ip=ip./nf;
end
if ( opts.absp ) ip=abs(ip); end;
% find the local max of correlation
% turning point of gradient? i.e. pos grad before, neg grad after
ip2=diff(real(ip),[],opts.dim);
ip2=cat(opts.dim,zeros([sz(1:opts.dim-1) 1 sz(opts.dim+1:end)]),ip2)>0 ...
    & cat(opts.dim,ip2,zeros([sz(1:opts.dim-1) 1 sz(opts.dim+1:end)]))<0;
% 2nd deriv less than zero?
%ip2=diff(ip,2,opts.dim); % 2nd deriv of ip
% add extra bit to 2nd deriv to line up with ip
%ip2=cat(opts.dim,zeros([sz(1:opts.dim-1) 1 sz(opts.dim+1:end)]),ip2,zeros([sz(1:opts.dim-1) 1 sz(opts.dim+1:end)]));
%ip2=fftconv(X,[0 -.5 1 -.5 0],opts.dim)./norm([-.5 1 -.5]); % find peaks
thresh=opts.thresh;
if( opts.meanthresh ) thresh=thresh+mean(ip(:)); end;
match=real(ip)>thresh & real(ip2)>0; % sufficient matchec and local max
return;
%----------------------------------------------------------------
function testCase()
art =[0 1 -1 0]'; % template artifact
sig =coloredNoise([100 80],[0 1 1./[1:15]],2);
mcplot(sig');
A   =mkSig(100,'gaussian',30)*3; % attenuation matrix
idx =find(randn(size(sig-numel(art)+1,2),1)>2); % idx where the artificate lives
X=sig;
for ii=1:numel(idx);
   X(:,idx(ii)+(0:numel(art)-1))=X(:,idx(ii)+(0:numel(art)-1))+repop(A,'*',art');
end
mcplot(X');

% compute the match
art=[zeros(1,10) .5 1 .5 zeros(1,10)]';
[match,ip]=matchTemplate(X,art,2,0);

% examine the detection quality
cmp(:,2*(1:size(Xtst,2))-1)=Xtst;
cmp(:,2*(1:size(Xtst,2)))  =match*15;
clf;mcplot(cmp(:,100+(1:20)))

% visualise the match quality
clf;image3ddi(double(match(:,:,1:10)),z.di,1,'ticklabs','sw','disptype','mcplot','plotopts',{'gap' 3 'minorTick' 0})

art=[zeros(1,10) .5 1 .5 zeros(1,10)]';
[match,ip,ip2]=matchTemplate(z.X,art,'dim',2,'absp',1,'meanthresh',1,'thresh',2,'corr',1);

% get the spike locations
[artIdx]=ind2subv(size(match),find(match));
mask=[false(1,9) true true true true true false(1,9)]';
fprintf('Detected %d artifacts',size(artIdx,1));
for ai=1:size(artIdx,1);
   idx=num2cell(artIdx(ai,:));
   idx{dim}=idx{dim}:min(idx{dim}+numel(art)-1,size(X,dim));
   ox = X(idx{:}); ox=ox(:); %get old
   ox(mask(1:numel(ox))) = mean(ox(~mask(1:numel(ox)))); % mask and mean remove artifact
   %ox = (ox'*art)*art./(art'*art); % remove artifact -- deflation
   X(idx{:})=ox;
end

