function result=volume_mounted(file)
parts=parse_parts(file);
if length(parts)>=2 & strcmp(parts{1},'Volumes')
   result=exist(['/Volumes/' parts{2} '/'], 'dir');
else 
    result = 1;
end

function result=parse_parts(file)
[pathstr,name,ext,versn] = fileparts(file);
if strcmp(pathstr, '/') | isempty(pathstr)
   result=name;
else result = [parse_parts(pathstr) {name}];
end