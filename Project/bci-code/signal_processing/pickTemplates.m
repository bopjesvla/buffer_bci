function [X]=pickTemplates(dat,N)
if ( nargin < 2 ) N=inf; end;
ci=1;
clf;plot(dat(:,ci)); hold on;
X=[];
while ( size(X,2)<N )
   [x,y,b]=ginput(1);
   if(isempty(b)) break; 
   elseif ( b > 3 ) % pressed a key?
      if ( b < 58 & b > 47 ) b=b-48; % convert number to class
      else % do something else?
         switch (b);
          case 8; % back-space? delete previous point.
           X(:,end)=[]; continue; 
          case {32,'n','N'}; % next dataset
           ci=min(ci+1,size(dat,2));
           clf; plot(dat(:,ci)); hold on;
           plot(X(:,X(:,3)==ci),'r*');
          case {'b','B'}; % next dataset
           ci=max(ci-1,1);
           clf; plot(dat(:,ci)); hold on;
           plot(X(:,X(:,3)==ci),'r*');
          case {'q','Q'}; % quit
           break;
          otherwise;
           fprintf('Unrecoginised key ignored!');
         end;
      end;
   elseif ( b>0 && b<3 ) 
      X(:,end+1)=[x;y;ci];
      plot(x,y,'r*');
   end
   fprintf('%d) %g %g %d\n',size(X,2),X(1,end),X(2,end),X(3,end));
end
