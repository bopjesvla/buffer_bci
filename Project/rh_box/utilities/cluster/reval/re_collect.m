function [varargout]=re_collect(job)
% collected the results of a reval'ed job
%
% [varargout]=re_collect(job)
%
% N.B. number of outputs equals number asked to save at job-submission time
%
% Inputs:
%  job -- [struct] reval job structure
% Ouputs:
%  [varargout{1:nargout}] -- output argument list
if ( numel(job)>1 )
   fprintf('Collect:');
   for ji=1:numel(job);
      try;
         varargout{1}{ji}=re_collect(job(ji));
         if ( ~isempty(varargout{1}{ji}) && isstruct(varargout{1}{ji}) && ~isfield(varargout{1}{ji},'alg') )
            if ( isstruct(job) ) alg=job(ji).conf.description.alg; else alg=job{ji}.conf.description.alg; end;
            varargout{1}{ji}.alg = alg;
         end
         textprogressbar(ji,numel(job));
      catch
         varargout{1}{ji}=[];
         le=lasterror;
         fprintf('%d) job collection failed:%s\n',ji,le.message);
      end
   end
   fprintf('\n');
   return;
end
varargout=cell(nargout,1);
[conf,opts]=reval_conf(); % get conf for the machine we're running on... not the submission machine
if ( iscell(job) ) job=job{:}; end;
if ( ~isfield(job,'job') ) return;  end  % only collect actual job structures
s=re_status(job);
if ( isempty(s) )
   error('reval:nonexistent','nonexistant job dir');
elseif ( s.finished && s.landed )
   if ( ~isempty(job.conf.outputmatfile) )
      try 
         t=load(fullfile(conf.jobrootdir,job.conf.outputmatfile),'varargout');
         varargout=t.varargout;
      catch
         warning('Couldnt read output file');
         % mark as failed job
         fid=fopen(fullfile(conf.jobrootdir,job.conf.statusfile),'a');
         fprintf(fid,'s.failed=%g\n;',now());fclose(fid);         
      end
   else
      warning('No output specified to collect');
   end
   fid=fopen(fullfile(conf.jobrootdir,job.conf.statusfile),'a'); fprintf(fid,'s.collected=%g\n;',now()); fclose(fid);
elseif ( s.failed ) 
   error('reval:failed','Cant collect failed job');
elseif ( ~s.finished )
   error('reval:notfinished','Can only collect finished jobs');
end