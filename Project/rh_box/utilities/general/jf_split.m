function [res]=split(c,str) % used to turn string into sub-bits
tmpstr=str;
if (isempty(c))  c = num2cell(char([9:13 32])); end
if ( ~iscell(c) ) c={c}; end; 
di=[0 numel(str)+1];
for i=1:numel(c);
   starts=find(str(1:end-numel(c{i})+1)==c{i}(1));
   for j=2:numel(c{i}); % match the rest of the string
      starts(str(starts+1)~=c{i}(j))=[];
   end
   % find the unique matches -- N.B. unique sorts into ascending order
   di=[di,starts];                % match start
   de=[di,starts+numel(c{i})-1];  % match end
end
[di,si]=sort(di);de=de(si); % sort into ascending order
for i=1:numel(di)-1;        % split them out
   res{i}=tmpstr(de(i)+1:di(i+1)-1);
end
