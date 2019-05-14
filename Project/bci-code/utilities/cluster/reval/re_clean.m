function [jobs]=re_clean(jobs,forcep,rmdirp)
% clean a reval job
%
% job=re_clean(job,rmdir,force)
%
% Inputs:
%  job   -- [struct] reval job structure
%  force -- [bool] force removal of non-collected jobs (0)
%  rmdir -- [bool] remove the job directory (1)
%
% N.B. use re_clean(job,0,0) to remove job from queue but keep for later re-submission
if ( nargin < 2 || isempty(forcep) ) forcep=0; end;
if ( nargin < 3 || isempty(rmdirp) ) rmdirp=1; end;
[conf,opts]=reval_conf(); % get local config for jobdir... not submission confi

% loop over jobs
if( numel(jobs)>1 ) fprintf('%d jobs to clean:',numel(jobs)); end;
for ij=1:numel(jobs);
   job=jobs(ij); if ( iscell(job) ) job=job{:}; end;
   stat=re_status(job);
   if ( ~isempty(stat) && ~forcep && isfield(stat,'finished') && stat.finished && job.job.nargout>0 && ~stat.collected )
      warning('%d) Job %d results not collected, not cleaning.  Use %s(job,1,1) to force.',...
              ij,job.conf.jobid,mfilename);
      return;
   end
   % delete the job from the submission system
   if ( ~isempty(stat) && isfield(stat,'finished') && stat.finished==0 && stat.failed==0 && ~isempty(job.conf.del_program) )
      jobdelcmd=sprintf('%s %s %s',job.conf.del_program,...
                        sprintf(job.opts.optsstr.delete,job.conf.jobid));
      if ( ~isempty(job.conf.sub_agent) )
         jobdelcmd=sprintf('%s %s',job.conf.sub_agent,jobdelcmd);
      end
      [status,res]=system(jobdelcmd);
      if ( status~= 0 ) 
         warning(sprintf('%d) job deletion from queue failed',ij));
      end
   end
   % delete the job-directory
   if ( rmdirp ) 
      if ( ~exist(fullfile(conf.jobrootdir,job.conf.jobdir),'dir') ) 
         fprintf('%d) Error job-directory not found! : %s\n',ij,fullfile(conf.jobrootdir,job.conf.jobdir));
      else
         if ( isunix() ) 
            jobdirdelcmd=sprintf('\\rm -rf %s',fullfile(conf.jobrootdir,job.conf.jobdir));
            [status,res]=system(jobdirdelcmd);
            if ( status~=0 ) 
               warning(sprintf('job directory deletion failed! %s',res));
            end
         else
            error('reval:nowindows','windows not supported yet');
         end
      end
   end
   textprogressbar(ij,numel(jobs));   
end
if ( numel(jobs)>1) fprintf('\n'); end;