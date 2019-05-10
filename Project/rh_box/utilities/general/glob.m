function [ofn]=glob(fn)
% glob expand the input file name
% Warning: doesn't work with spaces in file names!
if ( iscell(fn) )    fn = strvcat(fn{:}); end; % deal with cell arrays
if ( isunix ) 
   ofn={};
   for i=1:size(fn,1);
      [ans nfn]=system(['echo ' fn(i,:)]); nfn(nfn==10)=[]; 
      nlIdx = [0 find(nfn==32) numel(nfn)+1];
      for j=1:numel(nlIdx)-1;
         tfn{j} = nfn(nlIdx(j)+1:nlIdx(j+1)-1);
      end
      ofn = {ofn{:} tfn{:}};
   end
   if ( max(size(ofn))==1 ) ofn=ofn{:}; end;
else
   ofn=fn;
   
   ; % do nothing as globbing isn't defined?
end