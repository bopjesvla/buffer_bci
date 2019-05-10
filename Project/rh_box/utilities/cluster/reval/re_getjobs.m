function [jobInfo]=re_getJobs(method,varargin)
% get all job info by searching through the job-directory
%
% [jobInfo]=re_getJobs(method,varargin)
[conf,opts]=reval_conf(varargin);
if ( nargin < 1 ) method=''; end;

jobdir=fullfile(conf.jobrootdir,conf.jobdir);
if ( ~exist(jobdir,'dir') ) error('job directory not found'); end;
fprintf('Getting job directory listing...');
if ( ~isempty(method) && exist(fullfile(jobdir,method),'dir') )
   jobdir=fullfile(jobdir,method);
   jobdirs=dir(jobdir); jobdirs(~[jobdirs.isdir])=[]; jobdirs([1 2])=[]; jobdirs={jobdirs.name};
   % select only jobs with correct method
   mi=strmatch(method,jobdirs);
   jobdirs=jobdirs(mi);
   fprintf('done.\n');
else
   rjobdirs=dir(jobdir); rjobdirs(~[rjobdirs.isdir])=[]; rjobdirs([1 2])=[]; rjobdirs={rjobdirs.name};
   jobdirs={};
   for i=1:numel(rjobdirs);
      jobdirsi=dir(fullfile(jobdir,rjobdirs{i})); jobdirsi(~[jobdirsi.isdir])=[]; jobdirsi([1 2])=[]; jobdirsi={jobdirsi.name};
      for j=1:numel(jobdirsi); jobdirsi{j}=fullfile(rjobdirs{i},jobdirsi{j}); end;
      jobdirs={jobdirs{:} jobdirsi{:}};
   end
end


% sort them by the jobnum
jobnum=zeros(size(jobdirs));
for ij=1:numel(jobdirs);
   tmp=find(jobdirs{ij}=='_',1,'last');
   if ( isempty(tmp) ) jobnum(ij)=-1; continue; end;
   tmp = str2num(jobdirs{ij}(tmp+1:end)); 
   if ( ~isempty(tmp) ) jobnum(ij)=tmp; else jobnum(ij)=-1; end;
end
jobdirs(jobnum==0)=[]; jobnum(jobnum==0)=[];
[ans,si]=sort(jobnum,'ascend');
jobdirs=jobdirs(si); jobnum=jobnum(si);

jobInfo=[];
fprintf('%d jobdirs to search\ngetjobs:',numel(jobdirs));
for ji=1:numel(jobdirs);
   jobobjfile=fullfile(jobdir,jobdirs{ji},conf.objectmatfile);
   if ( ~exist(jobobjfile,'file') ) 
      warning('Couldnt open object mat file : %s\n',jobobjfile); continue; 
   end;
   if ( isempty(jobInfo) ) jobInfo=load(jobobjfile); else jobInfo(end+1)=load(jobobjfile); end;
   textprogressbar(ji,numel(jobdirs));
end
fprintf('\n');
return;