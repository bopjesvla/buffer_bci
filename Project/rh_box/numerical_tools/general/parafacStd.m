function [S,varargout]=parafacStd(S,varargin);
% standardize the parafac, i.e. make the U's unit norm
U=varargin;
if ( numel(U)==1 && iscell(U{1}) ) U=U{1}; end;
if ( numel(S)==1 ) S=ones(size(U{1},2),1); end;
r=size(U{1},2);
for d=1:numel(U); 
   nrm  = sqrt(sum(U{d}(:,:).^2,1)); 
   ok   = nrm>eps;
   if ( any(ok) )
      U{d}(:,ok) = repop(U{d}(:,ok),'./',nrm(ok));
      S(ok)      = S(ok).*nrm(ok)';
   end
   U{d}(:,~ok)= 0; % zero out ignored
   S(~ok)     = 0; 
end;
% re-order by importance
[ans,si]=sort(abs(S),'descend'); 
S=S(si); for d=1:numel(U); U{d}=U{d}(:,si); end;
if ( nargout==1 )
  S={S U{:}};
else
  varargout=U;
end
return;
%--------------------------------------
function testCase()
U0{1}=[0 1 1;1 0 1];
U0{2}=[0 1 1;1 0 1];
S0=[1 1 1]';
[S,U]=parafacStd(S0,U0{:});
