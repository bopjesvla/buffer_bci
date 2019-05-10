function savemat(name, matrix, extra);
% SAVEMAT	Save a MFBF matrix file.
%
%		Usage: savemat('file', m);
%		   or  savemat('file', m, extra);
%
%		SAVEMAT('file',m) saves matrix m into 'file' in MFBF
%		binary format. SAVEMAT('file',m, extra) appends the
%		string <extra> to the bottom of that file.
%
%		See also LOADMAT.
%
%		Thom Oostendorp, MF&BF University of Nijmegen, the Netherlands

matrix=matrix';
f=fopen(name, 'wb');

N=size(matrix);

fwrite(f, N(2), 'long');
fwrite(f, N(1), 'long');
fwrite(f, matrix, 'float');
if (exist('extra'))
  [M,N]=size(extra);
  for I=1:M,
    fwrite(f, extra(I,:));
    fwrite(f, char(10));
  end;
end


fclose(f);
