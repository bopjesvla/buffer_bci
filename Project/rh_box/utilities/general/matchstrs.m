function [x2y,y2x]=matchstrs(x,y,icase)
% compute a mapping between 2 sets of strings
%
% [x2y,y2x]=matchstrs(x,y,icase)
%
% Inputs:
%  x - 1st set of strings to match
%  y - 2nd set of strings to match
%  icase - [bool] case invarient (0)
% Outputs:
%  x2y - mapping from x -> y
%  y2x - mapping form y -> x
if ( nargin<3 || isempty(icase) ) icase=false; end;
if ( ~iscell(x) ) x={x}; end;
if ( ~iscell(y) ) y={y}; end;
if ( icase ) x=lower(x); y=lower(y); end;
x2y=zeros(numel(x),1); y2x=zeros(numel(y),1);
for i=1:numel(x); 
   mi=strmatch(x{i},y,'exact'); 
   if(~isempty(mi)) x2y(i)=mi; y2x(mi)=i; end;
end;
return;
%-------------------------------------------------------
function testCase();
s1={'hello' 'there' 'stupid'}
s2={'stupid' 'there' 'hello'}
[x2y,y2x]=matchstrs(s1,s2);