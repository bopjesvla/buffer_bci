function savepnt(fn,VER);
% savepnt stores vertices from a MBFYS triangulation in file
% savepnt(VER,fn);

% inverse of loadpnt

f = fopen(fn, 'w');
[nver dim]=size(VER);
fprintf(f,'%d\n ',nver);
for i=1:nver;
      fprintf(f,'%d %8.4f %8.4f %8.4f\n',i,VER(i,1:3));
end

fprintf('\nPoint specs written to file: %s\n',fn); 
fclose(f);
