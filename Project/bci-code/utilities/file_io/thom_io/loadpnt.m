function pnt = loadpnt(fn);

% LOADPNT reads vertices and triangles from a MBFYS triangulation file
%	pnt = loadpnt(filename)
%

fid = fopen(fn, 'rt');
if fid~=-1

  % read the vertex points
  Npnt = fscanf(fid, '%d', 1);
  pnt  = fscanf(fid, '%f', [4, Npnt]);
  pnt  = pnt(2:4,:)';
  fclose(fid);

else
  error('unable to open file');
end


