function codes=loadcodes(fromfile)
[~,~,e] = fileparts(fromfile);
switch e(2:end)
    case 'txt'
        codes = dlmread(fromfile,'\t');
    case 'mat'
        table=load(fromfile);
        codes=table.codes;
    otherwise
        error('Unsupported file extension: %s',e);
end