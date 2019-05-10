function [str]=log(job)
% print the execution log of a reval'ed job
%
% [str]=log(job)
%
% Inputs:
%  job -- [struct] reval job structure
% Outupts:
%  str -- [str] string containing the log info
if ( iscell(job) ) job=job{1}; end;
if ( isempty(job.conf.log_program) )
   fid=fopen(fullfile(job.conf.jobrootdir,job.conf.logfile),'r');
   str=fscanf(fid,'%c');
   fclose(fid);
else
   [status,str]=system(sprintf('%s %s %s',job.conf.log_program,...
                               sprintf(job.opts.optsstr.log,job.conf.jobid)));
end