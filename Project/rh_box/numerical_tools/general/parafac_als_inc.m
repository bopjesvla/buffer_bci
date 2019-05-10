function [S,varargout]=parfac_als_inc(X,varargin)
% Compute the "Parallel Factors" or Canonical Decomposition of an n-d array
% extract any seed directions
Us=[];
if ( ~isempty(varargin) && iscell(varargin{1}) && numel(varargin{1})==ndims(X) )
   szok=1; for d=1:ndims(X); if ( size(varargin{1}{d},1)~=size(X,d) ) szok=false; break; end; end;
   if ( szok ) Us=varargin{1}; varargin(1)=[]; end;
end
% parse any left over options
opts=struct('verb',0,'tol',0,'tol0',.001,'rank',inf);
[opts,varargin]=parseOpts(opts,varargin);

% Use a fitting the residuals approach to find the decomposition.
R=X; % residual
oR2 = sqrt(R(:)'*R(:));
for r=1:opts.rank;
   if ( ~isempty(Us) && r<size(Us{1},2) ) % compute the next direction
      for d=1:ndims(X); Ur{d}=Us{d}(:,r); end;
   else
      [Sr,Ur{1:ndims(R)}]=parfac_als(R,'rank',1,'verb',opts.verb,varargin{:}); % fit rank 1 decomp
   end
   
   % ensure orthogonality
   if ( r > 1 )
      clear C; for i=1:numel(U); C(:,i)=U{i}'*Ur{i}; end;
      nonOrtho = abs(prod(C,2))>1e-2;
      for i=1:numel(nonOrtho);
         
      end
   end
   
   % Compute the decomposition
   A=parafac(1,Ur);
   Sr = R(:)'*A(:); % compute the weighting for this component
   % Compute the new residuls
   R  = R - Sr*A;   % deflate
   R2=sqrt(R(:)'*R(:));
   
   % update the recorded solution
   if ( r==1 ) 
      S=Sr; U=Ur; 
   else   
      S=cat(1,S,Sr); for d=1:numel(Ur); U{d}=cat(2,U{d},Ur{d}); end;
   end
      
   % Report the error etc..
   if ( opts.verb>0 ) fprintf('%3d Factors)\tsse=%8g\t%%sse=%g\n',r,R2,R2/oR2); end;

   % convergence test
   if ( R2 < opts.tol || R2/oR2 < opts.tol0 ) break; end;
   
end
if ( opts.verb >= 0 )
   fprintf('\n%3d Factors)\tsse=%8g\t%%sse=%g\n',r,R2,R2/oR2);
end

varargout=U;
return;

%------------------------------------------------------------------------------
function A=parafac(S,varargin);
U=varargin;
if ( numel(U)==1 && iscell(U{1}) ) U=U{1}; end;
nd=numel(U); A=shiftdim(S,-nd);  % [1 x 1 x ... x 1 x M]
for d=1:nd; A=tprod(A,[1:d-1 0 d+1:nd nd+1],U{d},[d nd+1],'n'); end
A=sum(A,nd+1); % Sum over the sub-factor tensors to get the final result
return;

%--------------------------------------------------------------------------------------------
function testCase()

[S,U{1:ndims(X)}]=parfac_als_inc(X,100); 
[S,U{1:ndims(X)}]=parfac_als_inc(X,100,U);


% validate the orthogonality of the decomposition
clear A;for i=1:size(U{1},2); A(:,:,:,i)=parafac(1,U{1}(:,i),U{2}(:,i),U{3}(:,i)); end;
C = reshape(A,[],size(U{1},2)); C=C'*C;
imagesc(C);

% alt way of testing orthogonality, i.e. each direction should be ortho
clear C; for i=1:numel(U); C(:,:,i)=U{i}'*U{i}; end;
