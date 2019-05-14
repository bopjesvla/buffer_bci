function [corr,ccorr,corrMx,cmatch]=parafacCorr(P1,P2,varargin)
% compute the correlation between 2 parafac solutions
%
%  [corr,ccorr,corrMx,cmatch]=parafacCorr(P1,P2)
%
% Inputs:
%  P1,P2 - {S,U1,U2,...,UD} the 2 parafac solutions to compare as cell-array of matrices
%            S - [1xM] array of component singular values
%            U1- [d1xM] array of loading's for dimension 1
%            U2- [d2xM] ... etc
% Outputs:
%  corr  - [1x1] global correlation between the re-composed solution
%  ccorr - [1xM] correlation between the different components of the solutions
%  corrMx- [MxMxD] correlation between components for each dimension
%  cmatch- [1xM] matching between components used to compute ccorr

if ( nargin < 2 || isempty(P2) ) P2=P1; end;
% validate the size of the 2 inputs match
if ( numel(P1) ~= numel(P2) )
  error('Decomps must have the same number of dimensions');
end
for d=2:numel(P1);
  if ( ndims(P1{d})>2 || ndims(P2{d})>2 ) 
    error(sprintf('Decomp dim %d has more than 2 dimensions',d));
  end
  if ( size(P1{d},1) ~= size(P2{d},1) )
    error(sprintf('Decomps are different sizes in dimension %d, sz1 %d~= sz2 %d',d-1,size(P1{d},1),size(P2{d},1)));
  end
end

% compute the full set correlations, globally an d per dimension
nd = numel(P1)-1;
ncomp1=size(P1{1},1); ncomp2=size(P2{1},1);
P12=ones([ncomp1 ncomp1]); % P1 global cross-product
P22=ones([ncomp2 ncomp2]); % P2 global cross-product
P1P2=ones([ncomp1 ncomp2]); % global P1 P2 cross product
corrMx=zeros(ncomp1,ncomp2,nd); % [nComp x nComp x nDim] - per dim cross-correlation matrix
for d=2:numel(P1);
  % compute this dim's inner products
  p12d= P1{d}'*P1{d};
  p22d= P2{d}'*P2{d};
  p1p2d=P1{d}'*P2{d};
  % update the info for the full correlation
  P12 = P12 .* p12d;
  P22 = P22 .* p22d;
  P1P2= P1P2.* p1p2d;
  % update the info for the per-dimension cross-correlation matrices
  N1=diag(p12d);  N2=diag(p22d);
  corrd = p1p2d./sqrt(max(N1,eps)*max(N2,eps)'); % corr=x'*y./sqrt(x'*x*y'*y)
  for c1=find(N1==0); corrd(c1,N2==0)=1; end; % 0 correlates perfectly with 0
  corrMx(:,:,d-1) = corrd;
end
nrmP1 = P1{1}'*P12*P1{1}; if ( nrmP1<eps ) nrmP1=0; end;
nrmP2 = P2{1}'*P22*P2{1}; if ( nrmP2<eps ) nrmP2=0; end;
corr  = P1{1}'*P1P2*P2{1} ./ sqrt(nrmP1*nrmP2);

%2.b) solve the marriage problem to find the best matching between components
% N.B. should really include the component strenght in this computation - however
%   doing it like this introduces and implicit penalty for having too many components...
%   which is potentialluse useful anyway
%match=mean(abs(corrMx),3); % mean abs correlation is match quality
match=abs(prod(corrMx,3)); % abs product of correlations is match quality - 1 bad match is bad...
[cmatch,ccorr]=marriageAlgorithm(match);
mcorrMx = corrMx;
return;

function [wedIdx,wedQual]=marriageAlgorithm(pairQual)
% implementation of the Gale-Shapely algorithm for the marriage problem
% to find optimal matching between components
% Inputs:
%  pairQual- [nMen x nWomen] matrix of m->w matching qualities 
% Output:
%  wedIdx  - [nMen x 1] vector of weddings containing choosen woman for each man
%  wedQual - [nMen x 1] vector of qualities of each wedding
[nMen,nWomen]=size(pairQual);
transposep=0;if ( nMen > nWomen ) transposep=1; pairQual=pairQual'; tmp=nWomen; nWomen=nMen; nMen=tmp; end;
wedIdx=zeros(nMen,1);
wedQual=zeros(nMen,1);
while ( any(wedIdx==0) )
  mi=find(wedIdx==0,1); % get unmatched man
  pairQualmi = pairQual(mi,:);
  [ans,spQii]=sort(pairQualmi,'descend'); % get ordered list of possible pairings qualities
  for wi=spQii; % look through list of women looking for an available one    
    hubby = find(wedIdx==wi); % has this women already got husband?
    if( isempty(hubby) ) % not already married
      wedIdx(mi)=wi; wedQual(mi)=pairQual(mi,wi);  
      break;
    elseif ( pairQual(mi,wi) > pairQual(hubby,wi) ) % better match
      wedIdx(mi)=wi;   wedQual(mi)=pairQual(mi,wi); 
      wedIdx(hubby)=0; wedQual(hubby)=0; % we replace hubby
      break;
    end
  end
end
if ( transposep ) % invert the index expression
  tmp1=wedIdx; tmp2=wedQual;
  wedIdx=zeros(nWomen,1); wedQual=zeros(nWomen,1);
  for i=1:size(tmp1,1); wedIdx(tmp1(i))=i; wedQual(tmp1(i))=tmp2(i); end;
end
return;

%--------------------------------------------------------------------------
function testCase();
A=randn(10,9,8);
Cscale=sqrt(A(:)'*A(:));
C=[1e-4];
rank=3;
[P1{1:4}]=parafac_als(A,'rank',rank(min(end,1)),'C',C(min(end,1))*Cscale,'seedNoise',.1,'verb',1,'objTol0',1e-6);
[P2{1:4}]=parafac_als(A,'rank',rank(min(end,1)),'C',C(min(end,2))*Cscale,'seedNoise',.1,'verb',1,'objTol0',1e-6);

clf;
subplot(241);imagesc(P1{1});subplot(242);imagesc(P1{2});subplot(243);imagesc(P1{3});subplot(244);imagesc(P1{4});
subplot(245);imagesc(P2{1});subplot(246);imagesc(P2{2});subplot(247);imagesc(P2{3});subplot(248);imagesc(P2{4});

% check for degeneracy
[ans,ans,cMx1]=parafacCorr(P1,P1);
[ans,ans,cMx2]=parafacCorr(P2,P2);

[c,cc,cMx,cmtch]=parafacCorr(P1,P2);
