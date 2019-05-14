function [ss]=status(job,verb)
% get the status of (a set of) jobs
%
% [stat]=re_status(job,verb)
%
% Inputs:
%  job -- [struct] reval job structure
% Outputs:
%  stat -- [struct] job status structure
%     |.launched -- [int] time the job started execution on the cluster
%     |.started  -- [int] time the job started matlab execution on the cluster
%     |.finished -- [int] time job finished, i.e. successfully completed
%     |.failed   -- [int] time job failed, i.e. completed with error
%     |.landed   -- [int] time job completely finished on the node
%     |.host     -- [str] dns name of the machine the job is running on
%     |.collected-- [int] time the job results were collected
[conf,opts]=reval_conf();
if ( nargin<2 ) verb=1; end;
noinfo=struct('started',0,'finished',0,'landed',0,'failed',0,'host','','launched',0,'collected',0);
if( numel(job)>10 && verb>0 ) fprintf('re_status:'); end;
for ji=1:numel(job);
   if ( iscell(job) ) jb=job{ji}; else jb=job(ji); end;
   if ( ~isfield(jb,'conf') ) 
      ss(ji)=noinfo;
   else
      fid=fopen(fullfile(conf.jobrootdir,jb.conf.statusfile));
      if ( fid > 0 ) 
         str=fscanf(fid,'%c'); fclose(fid); 
         evalc(str); 
         ss(ji)=s;
      else
         try; ss(ji)=noinfo; catch; end;
         fprintf('%d) couldnt open status file : %s\n',ji,fullfile(conf.jobrootdir,jb.conf.statusfile));
      end
   end
   if( numel(job)>10 && verb>0 ) textprogressbar(ji,numel(job)); end;
 end
 if( numel(job)>10 && verb>0 ) fprintf('\n'); end;
if ( nargout==0 ) tabDisp(ss); end;