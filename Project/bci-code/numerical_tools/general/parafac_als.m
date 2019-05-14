function [S,varargout]=parafac_als(A,varargin)
% Compute the "Parallel Factors" or Canonical Decomposition of an n-d array
%
% [S,U1,U2,...UN] = parafac_als(A,varargin)
% Compute the Parallel Factors (PARAFAC) Decompostion (also called the
% Canonical Decomposition CANDECOMP) of the input n-d matrix A.
% This provides a decomposition of an n-d matrix A as:
%
%  A_{i1,i2,...iN} = S^{M} U1_{i1,M} U2_{i2,M} ... UN_{iN,M}
%
% Where we use Einstein Summation Convention to indicate implicit
% summation over the repeated labels on the RHS.
%
% For more information see:
% See: "Tutorial on MATLAB for tensors and the Tucker
%  decomposition", T. G. Kolda, B. Bader, Workshop on Tensor
%  Decomposition and Applications
%  
% Inputs:
%  A       -- a n-d matrix
%  S  -- [1 x rank] seed higher-order eigen-value
%  U1 -- [size(A,1) x rank] starting value for A's 1st dimension
%  U2 -- [size(A,2) x rank] starting value for A's 2nd dimension
%  ...
%  UN -- [size(A,N) x rank] starting value for A's Nth dimension
% Options:
%  rank    -- the rank of the approximation to compute, i.e. M, (1)
%  C       -- ridge, size of the regularisation ridge to use    (norm(A(:))*1e-4)
%  maxIter -- maximum number of iterations to perform
%  tol--  [float} tolerance on change in U, to stop iteration (1e-3)
%  tol0-- [float] relative tolerance to the 1st step (1e-3)
%  objTol0 -- [float] error tolerance relative to the initial value
%  initType-- how to generate an initial solution, either  ('svd')
%             'svd' - svd based init
%             'rand'- pure random init
%  seed    -- {S U1 U2... Ud} seed solution
%  seedNoise -[float] percentage of seed solution strength to add as additional noise (0)
%  alg     -- one of 'ls' - least squares, 'nnls' - non-negative least squares
%  symDim  -- [2 x ...] pairs of dimensions for which solution should be symetric ([]) 
%  rewghtFn -- function to use to reweight for different losses.
%  wght    -- [size(A)] initial importance of each example, 
%              only points with wght>0 are used for model fitting
% Outputs:
%  S  -- [1 x rank] set of eigenvalues
%  U1 -- [size(A,1) x rank] matrix of orthogonal vectors
%  U2 -- [size(A,2) x rank] matrix of orthogonal vectors
%  ...
%  UN -- [size(A,N) x rank] matrix of orthogonal vectors
opts=struct('verb',0,'rank',1,'C',0,'C1',0,'pinvtol',1e-10,'priorC',0,'seed',[],'minVal',0,'minSeed',1e-6,'initType','hoPM','alg','ls','symDim',[],...
            'maxIter',1000,'tol',0,'objTol',0,'tol0',0,'objTol0',[1e-5 1e-4],'seedNoise',[],...
            'rewghtFn',[],'wght',[],'rewghtStep',5,'marate',.1,'lineSearchAccel',1,'ortho',1,'orthoPen',[],'orthoScale',0);
[opts,varargin]=parseOpts(opts,varargin);

origszA=size(A); A=squeeze(A); % remove annoying singelton dimensions

if ( isempty(opts.C) ) 
  % N.B. this can be *far* too small if the singular-value spect is very peaked
  %      and far too large if have very few components
  % tmp = sort(origszA,'descend'); nsv=tmp(min(end,2)); % bound on num singular values in A
  % Cscale=(A(:)'*A(:)).^(1/ndims(A));  % N.B. why this value?
  % opts.C=Cscale*5e-5; 
  C=5e-5;
end
if ( isempty(opts.C1) )
  C1=0;
end

printstep=1;
sizeA=size(A); nd=ndims(A);

% test Points = weight of 0
tstInd=[]; 
if ( ~isempty(opts.wght) )
  tstInd=opts.wght;
  if ( islogical(tstInd) )     tstInd=(tstInd==0); % points with 0-weight are test points
  elseif ( isnumeric(tstInd) && all(tstInd(:)==1 | tstInd(:)==0 | tstInd(:)==-1) )
    tstInd=tstInd>0;     % tst points have +1 label
  elseif ( isnumeric(tstInd) && all(tstInd(:)>=1) && all(tstInd(:))<=numel(A) ) 
    tstInd=false(size(A)); tstInd(int32(opts.wght))=true; % weight is list of test points
  else error('wght is of unsupported type'); 
  end
  if ( ~isequal(origszA,sizeA) ) tstInd=reshape(tstInd,sizeA); end % squeeze also
end

% Extract the provided seed values
if ( numel(varargin) >= ndims(A)+1 && ~isempty(varargin) ) 
   S = varargin{1};
   U = varargin(2:ndims(A)+1);
elseif ( numel(varargin)>0 )
  error('%d Unrec options',numel(varargin));
else
   S=[]; U=cell(1,ndims(A));
end
if( ~isempty(opts.seed) )
  if ( ~iscell(opts.seed) || numel(opts.seed)~=numel(origszA)+1 )
    error('bad seed value format');
  end
  S=opts.seed{1}; U=opts.seed(2:end);
  if ( ~isequal(sizeA,origszA) ) % remove singlention stuff
    U(origszA==1)=[];
  end
end

% ensure is non-negative if wanted
alg=opts.alg; if ( ~iscell(alg) ) alg={alg}; end; for i=1:numel(alg); if(isempty(alg{i}))alg{i}='ls'; end; end;
for d=1:numel(U); 
  if ( strcmpi(alg{min(end,d)},'nnls') )
    Ud=U{d}; U{d}(Ud<0)=(abs(Ud(Ud<0))); 
  end
end

% N.B. everyone from here on *must* use Ai to prevent testSet cheating!
Ai=A;
% If any form of weighting, ensure seed also ignores unavailable points
if ( ~isempty(tstInd) )
  A2 = [sum(A(~tstInd).^2); sum(A(tstInd).^2)];
  % set ignored points to have values estimated from a rank1 fit to the training set  points...
  Ai(tstInd)=0;
else
  A2 = A(:)'*A(:);
end

% Fill in the (rest of) the seed values
if ( isempty(S) || numel(S)<opts.rank ) 
  if ( ~isempty(S) && ~isempty(tstInd) ) % seed fit target with previously estimated solution
    Ae = parafac(S,U{:}); 
    Ai(tstInd)=Ae(tstInd);
    clear Ae;
  end
  if ( opts.verb >0 ) fprintf('Init soln comp...'); end
  switch lower( opts.initType );
   case 'svd'; 
    [S,U{1:nd}]=parafacSVDInit(Ai,opts.rank,tstInd,[],[],max(10,2e2./log2(prod(size(Ai)))),opts.verb-2); % N.B. ignores given seed!
   case 'rand';
    [S,U{1:nd}]=randInit(Ai,opts.rank,U{:});
   case 'hopm';
    [S,U{1:nd}]=parafac_als_inc(Ai,'rank',opts.rank,'verb',opts.verb-1,'alg',alg,'wght',~tstInd,'objTol0',1e-1);
   otherwise; error(fprintf('Unrecognised solution initialisation type: %s',opts.initType));
  end
  for d=1:numel(U); % add some randonmess to the all-0 components
    nrm  = S(:)'.*sqrt(sum(U{d}.^2,1)); sml=nrm<opts.minSeed; 
    if ( sum(sml)>0 ) 
      nVals= randn(size(U{d},1),sum(sml)); % new vals for the small ones
      U{d}(:,sml)=repop(nVals,'./',sqrt(sum(nVals.^2,1)))*opts.minSeed;
    end
  end
  if ( opts.verb >0 ) fprintf('done!\n'); end    
  
elseif ( ~isempty(tstInd) ) % use the given seed info to seed the tstSet points
  Ae = parafac(S,U{:}); % estimated solution
  Ai(tstInd)=Ae(tstInd);
  clear Ae;
end

% init the orthoganalisation penalty stuff
orthoPens=opts.orthoPen; 
if ( isempty(orthoPens) ) orthoPens=0; 
elseif ( numel(orthoPens)==1 )
  orthoPens=[orthoPens(1)/10*ones(5,1); orthoPens(1)];
else
  % pen = \sum_r \sum_(k \neq r} s_r s_k' (x_r*x_k).^2 (y_r*y_k).^2
  % this penalty has value :  0 if UU=I, i.e. if perfectly orthogonal
  %                           (s'*s)*rank if UU=1, i.e. if all perfectly parallel
  %                           (s'*s) if rank=1 fit of parallel components
  % Thus pen naturally lives on same scale as SSE so doesn't need much adjustment
  %opts.orthoScale=1;%
  %if ( isempty(opts.orthoScale) ) opts.orthoScale=1./numel(S); end;
end
orthoPen=orthoPens(end); 

if ( ~isempty(opts.seedNoise) && opts.seedNoise>0 ) % level of noise to add to seed solution
  for d=1:numel(U);
    nrm=sqrt(sum(U{d}.^2,1));
    % generate random noise of ave length=1, then scale by ave U len * seedNoise size
    U{d} = U{d}+randn(size(U{d}))./sqrt(size(U{d},1))*mean(nrm)*opts.seedNoise;
  end
end

% re-normalise the initial solution
if ( isempty(S) ) S=ones(opts.rank,1); end;
for d=1:numel(U);
  nrms  = sqrt(sum(U{d}.^2,1))'; 
  ok=nrms>eps & ~isinf(nrms) & ~isnan(nrms) & isreal(nrms);
  if ( any(ok) ) % guard for no valid components
    S(ok) = S(ok).*nrms(ok);
    U{d}(:,ok) = repop(U{d}(:,ok),'/',nrms(ok)');
  end
end

% ensure seed is symetric if wanted
if ( ~isempty(opts.symDim) ) [S,U{:}]=symetricParafac(opts.symDim,S,U{:}); end      

minVal=opts.minVal;
Ai2 = Ai(:)'*Ai(:);
if ( isempty(tstInd) )
  [sse,ssep,AU,UU]=parafacSSE(Ai,S,U{:});
else
  Ae = parafac(S,U{:}); % estimated solution
  Err= A-Ae; % estimate error     
  sse = [sum(Err(~tstInd).^2); sum(Err(tstInd).^2)]; % train/test perf
  clear Ae Err;
end
J=sse(1)+opts.C*sum(abs(S).^2)+opts.C1*sum(abs(S)); % the object we're implicitly minimising
if ( orthoPen>0 ) % convergence on the modified objective
  % pen = \sum_r \sum_(k \neq r} s_r s_k' (x_r*x_k).^2 (y_r*y_k).^2
  % this penalty has value :  0 if UU=I, i.e. if perfectly orthogonal
  %                           (s'*s)*rank if UU=1, i.e. if perfectly parallel
  UU=U{1}'*U{1}; for d=2:nd; UU=UU.*(U{d}'*U{d}); end; % compute the cross-component correlation
  UU(1:size(UU,1)+1:end)=0; 
  J=J+orthoPen*S'*(UU.^2)*S;  % penalty is sum squared correlation, scaled by component magnitude
end; 
if ( opts.verb>0 ) 
  if ( numel(sse)>1 ) % test set results also
    fprintf('%3d)\t|S|=%g\tsse=%8f/%8f\t%%sse=%5.3f/%5.3f\tJ=%8f\tdJ=%8f\tdeltaU=%8f\n',0,sum(abs(S)),sse,sse./A2,J,0,0);
  else
    fprintf('%3d)\t|S|=%g\tsse=%8f\t%%sse=%5.3f\tJ=%6f\tdJ=%8f\tdeltaU=%8f\n',0,sum(abs(S)),sse,sse./Ai2,J,0,0);
  end
end

% Loop over A's dimensions computing in individual SVD's
oU=U; oS=S; dU=U; odU=U; oJ=J; dJ=0; deltaU=0; osse=sse; Jopt=J; Sopt=S; Uopt=U;
for iter=1:opts.maxIter;
  if ( iter<=numel(orthoPens) )  orthoPeni=orthoPens(iter); end; 
   ooJ=oJ;    oJ=J; % convergence tests
   oosse=osse(1); osse=sse(1); 
   ooU=oU;    oU=U; 
   ooS=oS;    oS=S;
   odU=dU;    dU=U;
      
   AU = Ai;   % Temp store of: A^{1:N} \prod_{j < d} U_j^m
   UU = 1;   % Temp store of: \prod_{j < d} Uj^m U^j_m'
   deltaU=0;
   for d=1:nd;
      
      % Compute the full products, starting from the cached info
      tAU=AU;  % A^{1:N} \prod_{j neq d} U_j^m
      tUU=UU;  % \prod_{j \neq d} Uj^m U^j_m'
      for d2=[d+1:nd]; 
        tAU=tprod(tAU,[1:d2-1 -d2 d2+1:nd nd+1:ndims(tAU)],U{d2},[-d2 nd+1],'n'); 
        tUU=tUU.*(U{d2}'*U{d2});%tprod(U{d2},[-1 1],U{d2},[-1 2],'n'); % \prod_{j\neq d} Uj^m U^j_m'
      end
      otUU=tUU;% for performance computation
      
      % ALS to find the new values         
      % modify the parameters for the different regularisors/penalties
      % add a ridge if wanted
      if ( opts.C>0 ) 
        tUU(1:(size(tUU,1)+1):end)=tUU(1:(size(tUU,1)+1):end)+opts.C; 
      end;
      if ( opts.C1>0 ) 
        tUU(1:(size(tUU,1)+1):end)=tUU(1:(size(tUU,1)+1):end)+abs(opts.C1)*1./max(abs(S)',1e-5)/2; 
      end;
      if ( opts.priorC>0 ) % ~trust-region, scaled by size of the norms
        tUU(1:(size(tUU,1)+1):end)=tUU(1:(size(tUU,1)+1):end)+opts.priorC*mean(abs(S)); 
        tAU = tAU + opts.priorC*mean(abs(S))*reshape(repop(U{d},'*',S'),size(tAU));
      end;
      % include the effect of the orthogonalisation penalty
      if ( orthoPeni>0 ) 
        % N.B. this approx uses the previous values for the penalty.....
        % N.B. this penalty also only really works if solution is approx ortho & good to start with...
        %      if it is not then it causes degeneration of the solution.
        %  This is possibly because using the previous values assumes only small changes in direction
        %  which is *not* true for non-ortho solutions which need big changes to fix
        %  Also the use of old values means it *does not* have any affect when the new solution is 
        %  not in the same sub-space as the current one, hence doesn't prevent the new soln 
        %  becomming non-ortho
        UdUd=U{d}'*U{d};  UdUd(1:size(UdUd,1)+1:end)=0;
        % BODGE: approx L1 type penalty scaling... so it's effect automatically ramps up
        %        as the solution gets better
        tmp = ((tUU.^2).*UdUd);  
        if ( opts.orthoScale ) 
          P=S'*(tUU.*UdUd)*S; 
          if(P>1e-6) tmp=tmp./sqrt(P); end%(sum(abs(tUU(:).*UdUd(:)))); 
        end;
        tUU = tUU + orthoPeni*tmp;  
      end
            
      % N.B. no scaling information is used (helps numerical precision) but this means the norm is 
      % re-computed every time
      oUd =U{d}; oS=S;
      tAU =reshape(tAU,size(oUd));
      uUd =tAU*pinv(tUU);%pinv(tUU,opts.pinvtol); % Least squares solution
      % N.B. introduces a lot of noise in the convergence!!!
      if ( any(strcmp(lower(alg{min(numel(alg),d)}),{'nls','nnls'})) ) uUd=abs(uUd); end
        
      % re-normalise the direction vectors
      S=sqrt(sum(uUd.^2,1))'; S(S<eps | ~isfinite(S))=1;
      Ud=repop(uUd,'./',S');  

      % % upated sse 
      UdUd= Ud'*Ud;
      sse = Ai2 - 2*sum(tAU.*Ud,1)*S(:) + S(:)'*(otUU.*UdUd)*S(:); % normalised U{d}          
      %sse = Ai2 - 2*tAU(:)'*uUd(:) + otUU(:)'*vec(uUd'*uUd); % un-normalised U{d}
      J   = sse(1)+abs(opts.C)*sum(abs(S).^2)+abs(opts.C1)*sum(abs(S));      
      if ( orthoPen>0 )
        pen = otUU; pen=pen.*UdUd; pen(1:size(pen,1)+1:end)=0;
        J   = J+orthoPen*S'*(pen.^2)*S;
        if ( J > oJ ) 
          if ( opts.verb>1 )
            fprintf('%2d.%2d)\tsse=%8f\t%%sse=%6f\tJ=%8f\tdeltaU=%8f\tlinearity violated\n',iter,d,sse,sse./Ai2,J,deltaU);
          end
          Ud = oUd; S=oS; UdUd=Ud'*Ud;
          % switch to rank at a time version
          for r=1:size(Ud,2);
            ttUU    =otUU(:,r); ttUU(r)=0;
            Ud(:,r) =tAU(:,r) - Ud*(S.*ttUU);% Least squares solution
            S(r)    =sqrt(Ud(:,r)'*Ud(:,r))'; 
            if ( abs(S(r))>eps ) Ud(:,r) =Ud(:,r)./S(r); end; % normalise if not zero
            UdUd(:,r) = Ud(:,r)'*Ud; UdUd(r,:)=UdUd(:,r); % update UdUd with new value
            if( size(Ud,1)<size(Ud,2) ) % efficient when d>>rank
              Ud(:,r) = pinv(eye(size(Ud,1))+orthoPeni*Ud*repop(ttUU'.^2,'*',Ud)')*Ud(:,r);
            else % efficient when rank<<d - however messes up the estimate of s(r) when C>>
              %UdUd=Ud'*Ud;
              % N.B. the order of brackets here is important and makes a 10x difference to soln
              % quality at 20 iterations
              proj = pinv(eye(size(Ud,2))+2*orthoPeni*UdUd.*(ttUU*ttUU'))*(2*orthoPeni*(ttUU.^2).*UdUd(:,r));
              Ud(:,r) = Ud(:,r) - Ud*proj;
            end
            Sr = sqrt(Ud(:,r)'*Ud(:,r));
            if ( abs(Sr)>eps ) Ud(:,r) = Ud(:,r)./Sr; end;% normalise again
            UdUd(:,r) = Ud(:,r)'*Ud; UdUd(r,:)=UdUd(:,r); % update UdUd with new value
          end
          % update sse and J computation
          UdUd=Ud'*Ud;
          sse = Ai2 - 2*sum(tAU.*Ud,1)*S(:) + S(:)'*(otUU.*UdUd)*S(:);
          J = sse(1)+abs(opts.C)*sum(abs(S).^2)+abs(opts.C1)*sum(abs(S));
          if ( orthoPen>0 ) 
            pen = otUU; pen=pen.*UdUd; pen(1:size(pen,1)+1:end)=0;
            J=J+orthoPen*S'*(pen.^2)*S;
          end;         
        end
      end
      clear tAU tUU; % free up ram

      if ( opts.verb > 2 ) 
        fprintf('%2d.%2d)\tsse=%8f\t%%sse=%6f\tJ=%8f\tdeltaU=%8f\n',iter,d,sse,sse./Ai2,J,deltaU);
      end
      
      % save the new value
      U{d}=Ud;
      % info on rate of change of bits
      deltaU = deltaU+sum(abs(oU{d}(:)-Ud(:))); 
      % Update the cached info with this new value
      AU = tprod(AU,[1:d-1 -d d+1:nd nd+1:ndims(AU)],Ud,[-d nd+1],'n'); 
      UU = UU.*UdUd; % [rank x rank]
   end
   
   % compute the objective function value
   sse  = Ai2 - 2*shiftdim(AU)'*S(:) + S(:)'*UU*S(:);
   % the objective we're implicitly trying to minimise?
   J    = sse(1) + abs(opts.C)*sum(abs(S).^2)+abs(opts.C1)*sum(abs(S));
   if ( orthoPen>0 ) 
     pen = UU; pen(1:size(pen,1)+1:end)=0;
     J=J+orthoPen*S'*(pen.^2)*S;
   end; 
   % convergence on the modified objective
   clear AU; % free up the ram again

   % line search along the sum of the previous 2 steps directions
   if ( opts.lineSearchAccel && iter>3 ) 
     sse_in=sse; J_in=J;
     if( opts.verb > 2 ) 
       fprintf('%2d)\tsse=%8f\t%%sse=%6f\tJ=%8f\tdJ=%8f\tdeltaU=%8f\n',iter,sse,sse./Ai2,J,oJ-J,deltaU);
     end
     step=2.2;%(iter+1)^(1./acc_pow); % fixed prob step size
     dirS=S-ooS; for d=1:nd; dirU{d}=U{d}-ooU{d}; end;
     tS=abs(ooS+dirS*step); for d=1:nd; tU{d}=ooU{d}+dirU{d}*step;end;
     % BODGE: Line search should be using the true objective too!!!
     [tsse,tssep,tAU,tUU]=parafacSSE(Ai,tS,tU{:}); 
     tJ  =tsse(1) + abs(opts.C)*sum(abs(tS).^2)+abs(opts.C1)*sum(abs(tS));
     if ( orthoPen>0 ) 
       pen = tUU; pen(1:size(pen,1)+1:end)=0; %pen=pen.*(tS*tS');
       tJ=tJ+orthoPen*tS'*(pen.^2)*tS;
     end; 
     if ( opts.verb > 2 ) 
       fprintf('ACC: step=%g \tosse/J=%g/%g \tsse/J=%g/%g \tdSSE/J=%g/%g',step,sse_in,J_in,tsse,tJ,sse_in-tsse,sse_in-tJ);     
     end     
     if ( tJ<J_in ) % accept good accel       
       U=tU; S=tS; sse=tsse; J=tJ; UU=tUU;
       if( opts.verb>2 ) fprintf('\t success\n'); end;
     else % do nowt
       if( opts.verb>2 ) fprintf('\t failed\n'); end;
     end
     % do 2nd secant based line search
     [ss,Jss,a,b,c]=secantFit([0 1 step],[ooJ J_in tJ]);
     if ( ss>1.2 && (ss<step-.2 || ss>step+.2) && ss<2*step ) 
       tS=abs(ooS+dirS*ss); for d=1:nd; tU{d}=ooU{d}+dirU{d}*ss; end;
       [tsse2,tssep2,tAU2,tUU2]=parafacSSE(Ai,tS,tU{:}); 
       tJ2  =tsse2(1) + abs(opts.C)*sum(abs(tS).^2)+abs(opts.C1)*sum(abs(tS));
       if ( orthoPen>0 ) 
         pen = tUU2; pen(1:size(pen,1)+1:end)=0; %pen=pen.*(tS*tS');
         tJ2=tJ2+orthoPen*tS'*(pen.^2)*tS;
       end; % convergence on the modified objective
       if ( opts.verb > 2 ) 
         fprintf('ACC: s:%g=%g\t s:%g=%g\t s:%g=%g\t s:%g=%g',0,ooJ,1,J_in,step,tJ,ss,tJ2);
       end     
       if ( tJ2<tJ )
         if ( opts.verb>2 ) fprintf('\t ss succeeded'); end;
         U=tU; S=tS; sse=tsse2; J=tJ2; UU=tUU2;
       else
         if ( opts.verb>2 ) fprintf('\t ss failed'); end;
       end
       if ( opts.verb>2 ) fprintf('\n'); end;
     end
   end

   % re-normalize, so all length is in the S part
   for d=1:numel(U);
     nrms=sqrt(sum(U{d}.^2,1))'; ok=nrms>eps & ~isinf(nrms) & ~isnan(nrms);
     if( any(ok) )         
       S(ok)=S(ok).*nrms(ok);%S(ok).*nrms(ok); %
       U{d}(:,ok)=repop(U{d}(:,ok),'./',nrms(ok)');  
     end
   end
   % the objective we're implicitly trying to minimise?
   J    = sse(1) + abs(opts.C)*sum(abs(S).^2)+abs(opts.C1)*sum(abs(S));
   if ( orthoPen>0 ) % ortho penalty
     pen = UU; pen(1:size(pen,1)+1:end)=0; %pen=pen.*(S*S');
     J=J+orthoPen*S'*(pen.^2)*S;
   end; 
   
   % apply the non-negativity constraint if wanted
   for d=1:numel(U); 
     if ( strcmpi(alg{min(end,d)},'nnls') )
       Ud=U{d}; U{d}(Ud<0)=(abs(Ud(Ud<0))); 
     end
   end
   
   % re-weight the objective function, by updating the target values
   % N.B. also compute the new weighted objective function value
   if ( (mod(iter,opts.rewghtStep)==0 || iter < opts.rewghtStep*5) ...
        && ( ~isempty(opts.rewghtFn) || ~isempty(tstInd) ) ) % any form of re-weighting
     if ( opts.verb>1 && opts.rewghtStep>0 ) fprintf('Reweighting points...\n'); end;
     Ae = parafac(S,U{:}); % estimated solution
     Err= A-Ae; % estimate error     
     Ai = A; % start from orginal
     if ( ~isempty(opts.rewghtFn) ) % only if wanted
       switch lower(opts.rewghtFn)
        case 'l1'; 
         h=1;
         idx=(Err>h); Err(idx)= sqrt(Err(idx))*sqrt(h);  Ai(idx)=Ae(idx)+Err(idx);
         idx=(Err<-h);Err(idx)=-sqrt(-Err(idx))*sqrt(h); Ai(idx)=Ae(idx)+Err(idx);
        otherwise; error(sprintf('Unrecoginised rewght fn: %s',opts.rewghtFn)); 
       end;
     end
     if ( ~isempty(tstInd) ) % tst Points get their predicted values
       Ai(tstInd) = Ae(tstInd);
       sse = [sum(Err(~tstInd).^2); sum(Err(tstInd).^2)]; % train/test perf
     else
       sse = Err(:)'*Err(:); % update objective value
     end
     Ai2=Ai(:)'*Ai(:);
     clear Ae Err;
   end   

   
   if ( J<Jopt ) Jopt=J; Sopt=S; Uopt=U; end % track the best solution so far
   % logging info
   dJ=oJ(1)-J(1);
   if ( opts.verb > 0 ) 
     if ( numel(sse)>1 ) % test set results also
       fprintf('%3d)\t|S|=%g\tsse=%8f/%8f\t%%sse=%5.3f/%5.3f\tJ=%8f\tdJ=%8f\tdeltaU=%8f\r',iter,sum(abs(S)),sse,sse./A2,J,dJ,deltaU);
     else
       fprintf('%3d)\t|S|=%g\tsse=%8f\t%%sse=%5.3f\tJ=%8f\tdJ=%8f\tdeltaU=%8f\r',iter,sum(abs(S)),sse,sse./Ai2,J,dJ,deltaU);
     end
     if ( opts.verb>1 || mod(iter,printstep)==0 ) 
         fprintf('\n'); printstep=floor(printstep*1.5)+1; 
      end;
   end

   % convergence testing
   if ( iter==1 )   deltaU0=max(deltaU,opts.tol0);  dJ0=max(abs(dJ),opts.objTol0(1)); madJ=max(oJ,J)*2;
   elseif (iter<3 ) deltaU0=max(deltaU,opts.tol0);  dJ0=max(abs(dJ),opts.objTol0(1)); madJ=max(madJ,J*2);
   end;
   madJ=madJ*(1-opts.marate)+dJ(1)*(opts.marate); % move-ave obj est
   if ( deltaU < opts.tol   || deltaU < deltaU0*opts.tol0   || ... % parameter change test
        abs(dJ)<opts.objTol || abs(dJ)< dJ0*opts.objTol0(1) || ... % solution change test (short-term)
        (iter>20 && ( madJ < opts.objTol(min(2,end)) || madJ < dJ0*opts.objTol0(min(2,end)))) )%sol chg long-term
      break; 
   end;
   
   % re-symetrize the solution
   if ( ~isempty(opts.symDim) ) [S,U{:}]=symetricParafac(opts.symDim,S,U{:}); end      
   
 end
 % return best solution found
 S=Sopt; U=Uopt; 
 
 if ( opts.verb > -1 ) 
  if ( isempty(iter) ) iter=1; end;
  % final performance computation
  clear Ae Ai; % free up some space
  if ( ~isempty(tstInd) ) % tst Points get their predicted values
    Ae = parafac(S,U{:}); % estimated solution
    Err= A-Ae; % estimate error         
    sse= [sum(Err(~tstInd).^2); sum(Err(tstInd).^2)]; % train/test perf
    clear Ae Err;
  else
    [sse,ssep,AU,UU] = parafacSSE(A,S,U{:}); % low memory version
  end
  J = sse(1) + abs(opts.C)*sum(abs(S).^2)+abs(opts.C1)*sum(abs(S));
  if ( orthoPen>0 ) % ortho penalty
    pen = UU; pen(1:size(pen,1)+1:end)=0; %pen=pen.*(S*S');
    J=J+orthoPen*S'*(pen.^2)*S;
  end; 
  degen=UU-eye(size(UU));   % compute degeneracy  
  %imagesc(degen);set(gca,'clim',[-1 1]);colormap ikelvin
  if ( numel(sse)>1 ) % test set results also
    fprintf('%3d)\t|S|=%5.2f\tdgn=%5.3f\tsse=%6g/%6g\t%%sse=%5.3f/%5.3f\tJ=%8.4g\tdJ=%5.3f\tdeltaU=%5.3f\n',iter,sum(abs(S)),sum(abs(degen(:)))./size(degen,1),sse,sse./A2,J,dJ,deltaU);
  else
    fprintf('%3d)\t|S|=%5.2f\tdgn=%5.3f\tsse=%6g\t%%sse=%5.3f\tJ=%8.4f\tdJ=%5.3f\tdeltaU=%5.3f\n',iter,sum(abs(S)),sum(abs(degen(:)))./size(degen,1),sse,sse./A2,J,dJ,deltaU);
  end
end

% order the components by decreasing magnitude
[S,si]=sort(S,'descend'); for d=1:numel(U); U{d}=U{d}(:,si); end;
if ( ~isequal(origszA,sizeA) ) % put the singlentons back in
   U(find(origszA>1))=U; [U{find(origszA==1)}]=deal(ones(1,opts.rank));
end
% standardize the component sign to be mostly positive
sgn=1;
for d=1:numel(U)-1;
  sgnd=sign(sum(U{d},1));
  U{d}=repop(U{d},'.*',sgnd);
  sgn=sgn.*sgnd;
end
U{d+1}=repop(U{d+1},'.*',sgn); % left over sign info goes into last component

% single output or multiple
if ( nargout<=1 ) S={S U{:}}; else varargout=U; end;
return;
   
%------------------------------------------------------------------------------
function [A]=parafac(S,varargin);
U=varargin;
% Compute the full tensor specified by the input parallel-factors decomposition
nd=numel(U); A=shiftdim(S,-nd);  % [1 x 1 x ... x 1 x M]
for d=1:nd; A=tprod(A,[1:d-1 0 d+1:nd nd+1],U{d},[d nd+1],'n'); end
A=sum(A,nd+1); % Sum over the sub-factor tensors to get the final result


%------------------------------------------------------------------------------
function [S,varargout]=randInit(A,rank,varargin)
nd=ndims(A); sizeA=size(A);
U=varargin;
if ( numel(U) < nd ) U{end+1:nd}=cell(); end;
[idx{1:nd}]=deal(1); % build index expression to extract the bit we want from A
for d=1:nd;      
   idx{d}=1:sizeA(d);      
   Ud=shiftdim(A(idx{:}));  Ud=Ud./norm(Ud); % seed guess
   Ud=repmat(Ud,1,rank-size(U{d},2));  % scale up to our size
   Ud= Ud + randn(size(Ud))*norm(Ud(:,1))*1e-0;  % Add noise for symetry breaking
   U{d}=cat(2,U{d},Ud);
   idx{d}=1;
 end

 [S,U{:}]=parafacProj(A,0,U{:});
 %S=ones(rank,1);
 for d=1:nd;
   nrms=sqrt(sum(U{d}.^2,1))'; ok=nrms>eps & ~isinf(nrms) & ~isnan(nrms);
   if( any(ok) ) 
     S(ok)=S(ok).*nrms(ok); U{d}(:,ok)=repop(U{d}(:,ok),'./',nrms(ok)');  
   end;
 end
 if ( nargout==1 ) S={S U{:}}; else varargout=U; end;
return;

%------------------------------------------------------------------------------
function [ss,fss,a,b,c]=secantFit(s,f)
% do a quadratic fit to the input and return the postulated minimum point
a=(f(3)-f(1) - (f(2)-f(1))*s(3))/(s(3)*s(3)-s(3));
b=f(2)-f(1)-a;
c=f(1);
if ( abs(a)<eps ) 
  ss=0;
else
  ss=-b/abs(a)/2; 
end
fss=a*ss.^2+b*ss+c;
return;

%------------------------------------------------------------------------------
function [U]=nls(A,B)
% non-negative least squares solution to XA=B -> X=B(A^-1)
% Using the back projection technique
U=A*pinv(B);
U(U<0)=(abs(U(U<0))); % project back to positive only space - but avoid degenercy


%------------------------------------------------------------------------------
function testCase()
rank=3;
t={rand(rank,1) randn(10,rank) randn(9,rank) cumsum(randn(8,rank),1)};
clf;mimage(t{:},'disptype','plot');
A =parafac(t{:}); A=A+randn(size(A))*1e-1;
P=parafac_als(A,'rank',3,'verb',1);
clf;mimage(P{:},'disptype','plot');

% validate the orthogonality of the decomposition
[c,cc,cmx]=parafacCorr(P);

% Build a random seed
sizeA=size(A); nd=ndims(A); 
r=3;
S=ones(r,1); for d=1:nd; U{d}=randn(size(A,d),r); end
[S,U{1:ndims(A)}]=parafac_als(A,S,U{:},'verb',2);

% Visualise the solution
image3d(S); figure; mimage(U{:});

% Check the decomposition works
nd=numel(U); A=shiftdim(S,-nd);  % [1 x 1 x ... x 1 x M]
for d=1:nd; A=tprod(A,[1:d-1 0 d+1:nd nd+1],U{d},[d nd+1],'n'); end
A=sum(A,nd+1); % Sum over the sub-factor tensors to get the final result
max(abs(A(:)-A(:)))

image3d(A);figure;image3d(A2);

% Check the quality of the decomposition as we reduce the number of
% components we use.
figure(100);image3d(A);
for r=1:max(size(A));
   A2=S(1:min(r,end),1:min(r,end),1:min(r,end)); % The low ranks we want
   for d=1:numel(U); 
      A2=tprod(A2,[1:d-1 -d d+1:numel(U)],U{d}(:,1:size(A2,d)),[d -d],'n');
   end
   Alr{r}=A2;
   max(abs(A(:)-Alr{r}(:))),
   figure(r); image3d(Alr{r});
end

% try a symetric problem
A=randn(10,100,100); M=randn(10,10); X=tprod(M,[1 -1],A,[-1 2 3]);
C=tprod(X,[1 -2 3],[],[2 -2 3]);
[S,U{1:3}]=parafac_als(C,'rank',3,'verb',1);
clf;subplot(131);plot(U{1});subplot(132);plot(U{2});subplot(133);plot(U{3});
[Ss,Us{1:3}]=parafac_als(C,'rank',3,'symDim',[1 2],'verb',1)
clf;subplot(131);plot(Us{1});subplot(132);plot(Us{2});subplot(133);plot(Us{3});

% try non-negative
rank=5;
t={rand(rank,1) abs(randn(10,rank)) abs(randn(9,rank)) abs(cumsum(randn(8,rank),1))};
clf;mimage(t{:},'disptype','plot');
A =parafac(t); A=A+randn(size(A))*1e-2;
SU=parafac_als(A,'rank',3,'verb',1);
clf;mimage(SU{:},'disptype','plot');
parafacCorr(t,SU)
P=parafac_als(A,'rank',3,'verb',1,'alg','nnls');
clf;mimage(SU{:},'disptype','plot');

% try with per-dimension non-negativity
t={rand(rank,1) (randn(10,rank)) (randn(9,rank)) abs(cumsum(randn(8,rank),1))};
clf;mimage(t{:},'disptype','plot');
A =parafac(t); A=A+randn(size(A))*1e-2;
SU=parafac_als(A,'rank',3,'verb',1);
clf;mimage(SU{:},'disptype','plot');
parafacCorr(t,SU)
P=parafac_als(A,'rank',3,'verb',1,'alg','nnls');
clf;mimage(SU{:},'disptype','plot');
P=parafac_als(A,'rank',3,'verb',1,'alg',{[] [] 'nnls'});

% try with l1 loss
rank=8;
t={rand(rank,1) randn(10,rank) randn(9,rank) randn(100,rank).^2};
A =parafac(t{:}); oA=A;
A=A+randn(size(A))*1e-3;
% add some outliers
outIdx=randperm(numel(A))'; outIdx=outIdx(1:max(5,end/100)); A(outIdx)=A(outIdx)+5*mean(abs(A(:))).*sign(randn(size(outIdx)));
P=parafac_als(A,'rank',3,'verb',1,'rewghtFn','l1','rewghtStep',1);parafacSSE(oA,P{:})
P=parafac_als(A,'rank',3,'verb',1,'rewghtFn',[],'rewghtStep',1);parafacSSE(oA,P{:})
clf;mimage(P{:},'disptype','plot');

% try with test points
rank=3;
t={rand(rank,1) abs(randn(10,rank)) abs(randn(9,rank)) abs(cumsum(randn(8,rank),1))};
clf;mimage(t{:},'disptype','plot');
A =parafac(t{:}); oA=A; 
A=A+randn(size(A))*1e-4;
wght=rand(size(A))>.2; % 80% test points
P=parafac_als(A,'rank',3,'verb',1,'wght',wght);
clf;mimage(P{:},'disptype','plot');

% try with test points - to check that they are ignored
rank=3;
t1={rand(rank,1)*1 abs(randn(10,rank)) abs(randn(9,rank)) abs(cumsum(randn(8,rank),1))};
t2={rand(rank,1)*-1 abs(randn(10,rank)) abs(randn(9,rank)) abs(cumsum(randn(8,rank),1))};
A1=parafac(t1{:}); A2=parafac(t2{:});
fIdxs=sign(randn(size(A1)));
A=A1; A(fIdxs<0)=A2(fIdxs<0);
P=parafac_als(A,'rank',3,'verb',1,'wght',fIdxs<0);
[s,sp]=parafacSSE(A1,P);
[s,sp]=parafacSSE(A2,P);

% try with 5-d
t={rand(rank,1) abs(randn(10,rank)) abs(randn(9,rank)) abs(cumsum(randn(8,rank),1)) randn(7,rank) randn(6,rank)};
A =parafac(tS,tU{:}); A=A+randn(size(A))*1e-2;
[S,U{1:ndims(A)}]=parafac_als(A,'rank',3,'verb',1);

% try with known test problems, from http://www.models.life.ku.dk/nwaydata1
tmp=load('amino'); A=tmp.X; clear tmp; % [5 x 201 x 61] should be rank 3, also is non-negative
tmp=load('FIA');   A=tmp.FIA.data; % [] should be rank-6, local-minima problems
tmp=load('KojimaGirls'); A=tmp.KojimaGirls.data; % 2-factor degeneracy...
tmp=load('brood'); A=tmp.X; clear tmp; % [ 10 bread (rep) x 11 attributes x 8 judges ] - rank ?


% test with point weighting
rank=1;
t=parafacSVDInit(A,rank); % init soln
tic,parafac_als(A,t{:},'verb',2,'C',0,'wght',trnIdx,'objTol0',0,'tol0',0,'tol',0);toc


% test the various ways of trying to stabilise the iterations
tic,
rank=max(size(A))+1;
S=[];U={}; Ss=[]; sses=[]; degens=[];
rand('seed',0); randn('seed',0); % ensure replicability
for i=1:50; 
  [S,U{1:ndims(A)}]=parafac_als(A,'rank',rank,'C',0,'C1',1e-3,'priorC',1e-1,'verb',-1,'tol0',2e-3,'objTol0',0,'seedNoise',1e-2); 
  sse=parafacSSE(A,S,U{:});
  [cii,ccii,corrMx]=parafacCorr({S,U{:}}); degen=prod((corrMx),3)-eye(size(corrMx,1));
  fprintf('%2d) |S|=%5.3f sse=%10g degen=%5.3f\n',i,sum(S),sse,sum(abs(degen(:)))); 
  Ss(:,i)=S; sses(:,i)=sse; degens(:,i)=degen(:);
end;
t=toc;
fprintf('t=%5.1f : |S|=[%10g %10g %10g (%10g)]\n',t,min(sum(Ss,1)),mean(sum(Ss,1)),max(sum(Ss,1)),var(sum(Ss,1)));...
fprintf('        : sse=[%10g %10g %10g (%10g)]\n',  min(sses),     mean(sses),     max(sses),     var(sses));...
fprintf('        : dgn=[%10g %10g %10g (%10g)]\n',min(sum(abs(degens))),mean(sum(abs(degens))),max(sum(abs(degens))),var(sum(abs(degens))));
clf;hist([sum(oSs,1); sum(Ss,1)]',20);legend('oSS','Ss');
% visualise the degeneracy of the solution
[c,cc,cmx]=parafacCorr({S U{:}});clf;imagesc(prod(cmx,3));set(gca,'clim',[-1 1]);colormap ikelvin

