function [z]=re_resetstatus(z)
% reset the status info for this job
if(iscell(z)) z=z{:}; end;
if(isstr(z))                    statusfile=z; 
elseif(isfield(z,'statusfile')) statusfile=fullfile(z.jobrootdir,z.statusfile);
elseif(isfield(z,'conf'))       statusfile=fullfile(z.conf.jobrootdir,z.conf.statusfile); 
end
fid=fopen(statusfile,'w'); 
fprintf(fid,'%s\n','s.started=0;s.finished=0;s.landed=0;s.failed=0;s.host='''';s.launched=0;s.collected=0;');
fclose(fid);
return;
