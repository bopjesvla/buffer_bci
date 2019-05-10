function savetri(fn,VER,ITRI);
% savetri stores vertices and triangles from a MBFYS triangulation in file
% savetri(VER,ITRI,fn);

% inverse of loadtri

f = fopen(fn, 'w');
[nver dim]=size(VER);
fprintf(f,'%d\n ',nver);
for i=1:nver;
      fprintf(f,'%d %8.4f %8.4f %8.4f\n',i,VER(i,1:3));
end

[ntri dim]=size(ITRI);
fprintf(f,'%d\n ',ntri);
for i=1:ntri;
      fprintf(f,'%d %d %d %d\n',i,ITRI(i,1:3));
end
fprintf('\ntriangle specs written to file: %s\n',fn); 
fclose(f);
