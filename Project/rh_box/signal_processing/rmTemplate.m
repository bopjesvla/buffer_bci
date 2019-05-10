function [X]=rmTemplate(X,temp,dim)
% remove template signal from the input matrix
% 
% [X]=rmTemplate(X,temp,dim)
ip = tprod(X,[1:dim-1 -dim dim+1:ndims(X)],temp,[-dim dim])./(temp'*temp);% match between template and signal
X = X - repop(ip,'*',shiftdim(temp,-dim+1));    % subtract matched bit
%mimage(X,repop(ip,'*',shiftdim(temp,-dim+1)),'diff',1)
return;
%---------------------------------------------------------------
function testCase();
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

Z=X;
for ii=1:numel(idx);
   Z(:,idx(ii)+(0:numel(art)-1))=rmTemplate(X(:,idx(ii)+(0:numel(art)-1)),art,2);
end