function mysave(file, data, verbose)
if nargin == 2
   verbose = 1;
end
if verbose
    disp(['saving ' file ' ... ' sizestr(data) ' ' mat2str(size(data))]);
end
[pathstr,name,ext,versn] = fileparts(file);
if exist(pathstr) == 0 & volume_mounted(file)
   mkdir(pathstr);
end

if ext == '.mat'
   ftype = '-MAT';
else
   ftype = '-ASCII';
end

save(file, 'data', ftype);

% x = [1 2 3];
% mysave('/Projects/ERP/test/tst.mat', 'x')