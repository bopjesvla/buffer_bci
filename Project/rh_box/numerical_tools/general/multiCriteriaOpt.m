function [varargout]=multiCriteriaOpt(obj,objFuzz,mins,verb)
% use the computed measures to pick the 'optimal' fitting parameters
% Use multi-criteria optimisation -> find a non-dominated best trade-off between sse and stability
% search for best point, using multi-objective optimisation
% we want a point which is within a certain distance of the optimal for every criteria
% objFuzz tell's us for each criteria what this distance should be
if ( nargin<3 || isempty(mins) )
  mins=[min(obj(:,1)) min(obj(:,2)) min(obj(:,3)+(obj(:,3)==0))];
end
if ( nargin<4 || isempty(verb) ) verb=1; end;
if ( ndims(obj)>1 ) 
  szObj=size(obj);
  obj=reshape(obj,[prod(szObj(1:end-1)) szObj(end)]);
end
step=1; t=1; bracket=false;
for i=1:100;
  pts=   obj(:,1)<mins(1)+t*objFuzz(1) ... % sse
      &  obj(:,2)<mins(2)+t*objFuzz(2) ... % stab
      &  obj(:,3)<mins(3)+t*objFuzz(3); % degen
  nPts=sum(pts(:));
  if ( verb>0 ) 
    fprintf('%2d)\t%5f\t%d\t[%s]\n',i,t,sum(pts(:)),sprintf('%d,',find(pts))); 
    if ( verb>1 )
      reshape(pts,szObj(1:end-1))
    end
  end;
  if ( nPts==1 ) break;
  elseif ( ~bracket && nPts==0 ) step=step*1.6; t=t+step; % forward until bracket
  elseif ( ~bracket && nPts>0 )  step=step*.62; t=t-step; bracket=true; 
  elseif ( bracket &&  nPts==0 ) step=step*.62; t=t+step; % golden ratio search
  elseif ( bracket &&  nPts>0  ) step=step*.62; t=t-step;
  end
end
optIdx=find(pts);
[is{1:numel(szObj)-1}]=ind2sub(szObj(1:end-1),optIdx(1));
% output in appropriate type
if ( nargout>1 ) varargout=is; else varargout={cat(1,is{:})}; end
return;
%------------------------------------
function testCase();
mins=[min(min(res.obj(:,:,1))) min(min(res.obj(:,:,2))) min(min(res.obj(:,:,3)+(res.obj(:,:,3)==0)))];
multiCriteriaOpt(res.obj,[.5 .05 .6],mins,1);