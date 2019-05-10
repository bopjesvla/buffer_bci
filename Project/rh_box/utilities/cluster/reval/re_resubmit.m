function [z]=resubmit(z,forcep)
% re-submit an already submitted job to the cluster
%
% [job]=re_resubmit(job,force)
%
% Inputs:
%  job -- [struct] reval job structure
%  force--[bool] force re-submission even if the job hasn't finished
% Outputs:
%  job -- [struct] reval job structure, *with new submission info*
if ( nargin<2 || isempty(forcep) ) forcep=0; end;
if ( numel(z)>1 ) % submit all the jobs
   for i=1:numel(z);
      zi=z(i); if( iscell(zi) ) zi=zi{:}; end;
      if ( ~isfield(zi,'job') ) fprintf('%d) Cant submit non-job.  Skipped\n',i); continue; end;
      try;
         zi=re_resubmit(zi,forcep);
         if ( iscell(z) ) z{i}=zi; else z(i)=zi; end;
      catch 
         le=lasterror();
         if ( ~isempty(strmatch('reval:',le.identifier)) )  fprintf('%d) %s',i,le.message);
         else rethrow(le);
         end
      end
   end
   return;
end

if (iscell(z)) z=z{:}; end;
stat=re_status(z);
if( isempty(stat) && ~exist(fullfile(z.conf.jobrootdir,z.conf.jobdir),'dir') ) 
   error('reval:nojobdir','can only re-submit jobs with job-dir still available')
elseif( ~forcep && ~isempty(stat) && stat.started && ~(stat.finished || stat.failed) ) 
   error('reval:notfinished','can only (re)submit finished jobs');
end

% remove it from the job queue
re_clean(z,1,0); % force removal but leave job-dir intact
% clear its status info
re_resetstatus(z);

if( z.opts.verb > 0 ) 
   fprintf('Submitting job with cmd:\n%s\n',z.conf.sub_cmd);
end
[status,res]=system(z.conf.sub_cmd);
if ( status~= 0 ) 
   warning('%s\nsubmission failed with error code: %d',res,status)
   % mark status as failed
   fid=fopen(fullfile(z.conf.jobrootdir,z.conf.statusfile),'a'); fprintf(fid,'s.failed=%g;\n',datenum(now)); fclose(fid);
end
z.conf.res=res;
if( status==0 && ~isempty(z.opts.optsstr.getjobid)) % extract jobId from the submission response
   nn=strfind(res,sprintf('\n')); if ( numel(nn)>1 ) z.conf.res=z.conf.res(nn(end-1):end); end;
   z.conf.jobid=strread(z.conf.res,z.opts.optsstr.getjobid);
else
   z.conf.jobid=[];
end
% save the object file
save(fullfile(z.conf.jobrootdir,z.conf.objectmatfile),'-struct','z');
% write the jobId to a text file
fid=fopen(fullfile(z.conf.jobrootdir,z.conf.jobdir,sprintf('jobId=%s',z.conf.jobid)),'w'); fprintf(fid,'%s',z.conf.jobid); fclose(fid);

if( z.opts.verb < 1 )
   fprintf('submitted. jobNum: %g, jobID : %s\n',z.conf.jobnum,z.conf.jobid);
else
	fprintf('\nsubmit info:\n');
   fprintf('  job num        = %g\n', z.conf.jobnum);
   fprintf('  job id         = %g\n', z.conf.jobid);
	fprintf('  job name       = %s\n', z.conf.jobname);
	fprintf('  job directory  = %s\n', z.conf.jobdir);
	fprintf('  sub args       = %s\n', z.conf.sub_optstr);
	fprintf('  function       = %s\n', z.job.method);
end
