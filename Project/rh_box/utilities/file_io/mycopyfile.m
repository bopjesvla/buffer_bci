function data = mycopyfile(from, to)
[pathstr,name,ext,versn] = fileparts(to);
if exist(pathstr) == 0
   mkdir('/.', pathstr);
end
copyfile(from, to);
