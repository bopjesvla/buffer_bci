function [varargout]=orthoParafac(varargin);
% orthogonalise the input decomposition
%
%  [S,U{1} U{2} ...]=orthoParafac(S,U{1},U{2},...)
%
% N.B. the eculidean norm of a parafac tensor is given by:
%   <T,T> = <UVW...,UVW...> = sum_ij U'*U V'*V W'*W .... = sum_ij prod_d U{d}'*U{d}
%
%  Options:
%  C       - [float] ridge to add to regularise the solution
%  maxIter - [int] max number of iterations to use (1)
%  objTol  - [float] tolerance on convergence of the squared loss
%  objTol0 - [float] tolerance on change relative to initial objective value change
opts=struct('verb',0,'C',[],'minVal',0,'minSeed',1e-6,...
            'maxIter',1,'tol',1e-6,'objTol',0,'tol0',1e-4,'objTol0',1e-5);
[opts,varargin]=parseOpts(opts,varargin);
if ( numel(varargin)==1 && iscell(varargin{1}) ) varargin=varargin{1}; end;
if ( size(varargin{1},2)==1 ) % deal with S,U or U only inputs
   S=varargin{1}; U=varargin(2:end);
else
   U=varargin; S=ones(size(U{1},2),1);
end
% normalise the inputs
for id=1:numel(U); 
   nrm  = sqrt(sum(U{id}.^2,1)); ok=nrm>eps;
   if ( any(ok) )
      U{id}(:,ok) = repop(U{id}(:,ok),'./',nrm(ok));
      S(ok)      = S(ok).*nrm(ok)';
   end
   U{id}(:,~ok)= 0; S(~ok)     = 0; % zero out ignored
end
S=S(:);

% restrict to only the active components for speed
actComp = S>eps*max(S); 

% orthogonalise the inputs -- using a ALS algorithm
% init the bits we need
UU = zeros(sum(actComp),sum(actComp));
for d=1:numel(U);
   V{d}=U{d};
   UU(:,:,d)=U{d}(:,actComp)'*U{d}(:,actComp);   
   R   =S;
end
VV  =UU;   UV  =UU;

f=inf;
for iter=1:opts.maxIter;
   oV2=V; oR=R;
   deltaU=0; of=f; % convergence tests
   for d=1:numel(U);
      oV = V{d};
      % compute the parts we need
      % N.B. we have to put some/most of the norm into the fixed part to introduce some symetry breaking
      %      as otherwise in a min-norm solution the same direction multiple times will just get given equal weight 
      %      multiple times
      VVd = prod(VV(:,:,[1:d-1 d+1:end]),3).*(R(actComp)*R(actComp)');
      UVd = prod(UV(:,:,[1:d-1 d+1:end]),3).*(S(actComp)*R(actComp)');
      % solve the linear system, in min-norm fashion
      if ( ~isempty(opts.C) && opts.C>0 ) VVd(1:size(VVd,1)+1:end)=VVd(1:size(VVd,1)+1:end)+opts.C; end;
      V{d}(:,actComp) = (U{d}(:,actComp)*UVd)*pinv(VVd,mean(diag(VVd))*1e-7); % robust inversion if rank defficient
      % re-normalise the system to put the magnitude in the singular-value part
      % N.B. this is necessary to get the rank reduction! as otherwise the norm get's spread over all the 
      %      components and later dims can't move weight into fewer components
      nrm  = sqrt(sum(V{d}.^2,1))'; ok=abs(nrm)>eps & ~isinf(nrm) & ~isnan(nrm);
      if ( ~any(ok) ) warning('empty input!'); varargout={R V{:}}; return; end;
      V{d}(:,ok) = repop(V{d}(:,ok),'./',nrm(ok)');
      R(ok)      = R(ok).*nrm(ok);
      % record convergence info -- inner product between the component directions
      deltaU = deltaU + abs(1-sum(oV.*V{d}));
      
      % update cached info with new solution
      VV(:,:,d)= V{d}(:,actComp)'*V{d}(:,actComp);
      UV(:,:,d)= U{d}(:,actComp)'*V{d}(:,actComp);
   end
   deltaU = deltaU*R;
   
   % compute the objective function estimate, i.e. sse
   nrmV= R(actComp)'*prod(VV,3)*R(actComp);
   nrmU= S(actComp)'*prod(UU,3)*S(actComp);
   nrmUV = S(actComp)'*prod(UV,3)*R(actComp); 
   f = nrmU - 2*nrmUV + nrmV;

   if ( opts.verb > 0 ) fprintf('%2d)f=%8g\trank=%d\tdeltaU=%8g\n',iter,f,sum(R>1e-4*max(R)),deltaU); end

   % convergence test
   df=of-f;
   if ( iter==1 ) deltaU0=max(deltaU,eps); df0=eps; 
   elseif (iter==2 ) df0=max(abs(df),eps); end;
   if ( deltaU < opts.tol || (of-f)<opts.objTol || ...
        deltaU./deltaU0 < opts.tol0 || abs(f-of)./df0 < opts.objTol0 ) 
      break; 
   end;
   
end
varargout={R V{:}};
return;
%------------------------------------------------------------------------------
function [A]=parafac(S,varargin);
U=varargin;
% Compute the full tensor specified by the input parallel-factors decomposition
nd=numel(U); A=shiftdim(S,-nd);  % [1 x 1 x ... x 1 x M]
for d=1:nd; A=tprod(A,[1:d-1 0 d+1:nd nd+1],U{d},[d nd+1],'n'); end
A=sum(A,nd+1); % Sum over the sub-factor tensors to get the final result
%--------------------------------------------------------------------------------------------
function testCase();
[S2,U2{1:2}]=orthoParafac(S0,U0{:});
clear C; for i=1:numel(U2); C(:,:,i)=U2{i}'*U2{i}; end;


U0{1}=[0 1 1;1 0 1];
U0{2}=[0 1 1;1 0 1];
S0=[1 1 1]';
A0=parafac(S0,U0{:});

[S,U{1:2}]=parfac_als_inc(A0);
[S,U{1:2}]=parfacStd(S0,U0{:}); % norm and dec order
A=parafac(S,U{:});
[S2,U2{1:2}]=orthoParafac(S0,U0{:});
A2=parafac(S2,U2{:});
[S3,U3{1:numel(U)}]=parfacProj(A,U2{:});

A3=parafac(S3,U3);
R2=A-A2; R2(:)'*R2(:)

% with negative values
[S,U{1:2}]=orthoParafac(S0.*[1 -1 1]',U0{:});