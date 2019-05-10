function [matchi,substrs]=regexpstrmatch(strs,vals,substrregexp)
% match 2 sets of strings or a sub-string defined by a regexp
%
% [matchi,substrs]=regexpstrmatch(strs,vals,substrregexp)
%
if ( nargin < 3 || isempty(substrregexp) ) substrregexp='(.*)'; end;
if ( iscell(vals) && isnumeric(vals{1}) ) vals=cat(1,vals{:}); end;
if ( isstr(vals) ) vals={vals}; end;
if ( isstr(strs) ) strs={strs}; end;
if ( isempty(vals) || iscell(vals) && numel(vals)==1 && isempty(vals{1}) ) 
   matchi=true(numel(strs),1); return; % no val matches everything
end; 
matchi=zeros(numel(strs),1);
substrs={};
for si=1:numel(strs);
   substr=regexp(strs{si},substrregexp,'tokens');
   if( isempty(substr) || numel(substr)>1 ) continue; end;
   substr=substr{1}{1};
   substrs{si}=substr;
   if( isnumeric(vals) )                     mi = find(str2num(substr)==vals);
   elseif ( iscell(vals) && isstr(vals{1}) ) mi = strmatch(substr,vals,'exact'); 
   end;
   if ( ~isempty(mi) && numel(mi)==1 ) matchi(si)=mi; end;
end
