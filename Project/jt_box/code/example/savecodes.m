function savecodes(tofile,codes)
[~,~,e] = fileparts(tofile);
switch e(2:end)
    case 'txt'
        dlmwrite(tofile,codes,'delimiter','\t');
    case 'mat'
        save(tofile,'codes');
    otherwise
        error('Unsupported file extension: %s',e);
end