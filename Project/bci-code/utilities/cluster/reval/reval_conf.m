function [varargout]=reval_conf(varargin)
opts=struct('memUse',1000,'timeUse',24*3,'coreUse',1,'express',[],'hold',[],'priority',[],'rerun',[],...
            'verb',0,'globals',1,'smartpath',1,'optsstr',[]);
conf.nodeshell_program = '/bin/bash'; % program used to execute the commands remotely
conf.node_preflight_cmd = '';          % command to execute before running script
conf.matlab_preflight_cmd ='';
conf.matlab_program='matlab';
conf.matlab_options='-nodisplay -nojvm';
conf.userprefix='';
opts.template.mastermfile='mastermfile.template';
opts.template.nodescript='nodescript.template';

% various file locations
conf.clusterhome='/home/'; % location of home directory on a cluster node
conf.clusteruser='jasfar'; % user name on the cluster
if isunix
	user = getenv('USER');
   conf.home = getenv('HOME');
	[ans,host] = system('hostname'); host=deblank(host);
end
if ( strfind(host,'socsci') )
   conf.jobrootdir = '/Volumes/jasfar'; % local directory for the jobs scripts to be saved
elseif ( strfind(host,'frant') )
   conf.jobrootdir = '/run/user/1000/gvfs/smb-share:server=dcc-srv.science.ru.nl,share=jasfar/'; % local directory for the jobs scripts to be saved
else % if in doubt fall-back on using the same directory as here
   conf.jobrootdir = conf.home;
end

% % single machine testing
% conf.clusterhome='/home'; % location of home directory on a cluster node
% conf.clusteruser='jdrf';
% conf.jobrootdir = '/home/jdrf'; % local directory for the jobs scripts to be saved

conf.jobdir='jobs';
conf.cwd  = '';

% setup where we save stuff
conf.mastermfile = 'mastermfile.m';
conf.nodescript  = 'nodescript.sh';
conf.inputmatfile = 'varargin.mat';
conf.outputmatfile = 'varargout.mat';
conf.objectmatfile = 'subobj.mat';
conf.logfile = 'log';
conf.statusfile = 'status.m';
conf.globalfile = 'globals.mat';

conf.nargout    = []; % so can specify this with job opts
conf.description= '';

% Job submission conf options -- change for different job submission systems
% % Xgrid
% conf.sub_program='/usr/bin/xgrid';  % program to submit a job
% conf.sub_options='-h mmmxserver.nici.ru.nl -auth Kerberos'; % fixed options for submission
% conf.sub_agent  ='ssh mmmxserver.nici.ru.nl';
% opts.optsstr.submit    =' -job submit'; % submit a job
% opts.optsstr.getjobid  ='{\n%*s=%n;\n}'; % strread format spec to extract jobId
% opts.optsstr.delete    =' -job delete -id %d'; % delete job from the system
% opts.optsstr.log       =' -job results -id %d'; % get log info for job
% % sprintf strings to say how to put different job-options info into the sub-command
% opts.optsstr.memUse='';  % specify a required amount of memory
% opts.optsstr.timeUse=''; % spec required run-time
% opts.optsstr.express=''; % spec we want to jup to start of queue
% opts.optsstr.hold   =''; % don't run quite yet
% opts.optsstr.rerun  =''; % re-run if failed
% opts.optsstr.priority=''; % set job priority
% opts.optsstr.logfile =''; % file to log the std-out to
% opts.optsstr.nodescript=' %s'; % script to run

% Sun-Grid-Engine  / Torque
%conf.sub_program='/usr/bin/qsub';  % program to submit a job
conf.sub_program='/usr/local/torque/bin/qsub';  % program to submit a job
conf.sub_options=''; % fixed options for submission
conf.sub_agent  ='ssh hub.science.ru.nl';
conf.log_program = '';
conf.del_program = '/usr/local/torque/bin/qdel';
% opts strings to specify operations to perform on the jobs
opts.optsstr.submit    =''; % submit a job
opts.optsstr.getjobid  ='%c'; % strread format spec to extract jobId
opts.optsstr.delete    ='%s'; % delete job from the system
opts.optsstr.log       =''; % get log info for job
% sprintf strings to say how to put different job-options info into the sub-command
opts.optsstr.memUse=' -l pmem=%imb';
opts.optsstr.timeUse=' -l walltime=%i:00:00';
opts.optsstr.coreUse= ' -l nodes=1:ppn=%i';
opts.optsstr.express=' -hard -l express=true';
opts.optsstr.hold   =' -h';
opts.optsstr.rerun  =' -r y';
opts.optsstr.priority=' -p %i';
opts.optsstr.logfile =' -d ''%s'' ';
opts.optsstr.nodescript=' %s';


% parse the user-spacific overrides
[conf,opts]=parseOpts({conf,opts},varargin);

% user-specific config
user = conf.clusteruser;
if ( isempty(user) )
if isunix
	user = getenv('USER');
%	[ans,host] = system('hostname'); host=deblank(host);
else
	user = getenv('USERNAME');
%	host = lower(getenv('COMPUTERNAME'));
end
end

conf.clusterhome=fullfile(conf.clusterhome,user);
%if ( strcmp(host,'mirsky') ) conf.clusterhome=fullfile('/tmp',user); end
%conf.jobrootdir =fullfile(conf.clusterhome,conf.jobrootdir);
% if isunix
%    owd=cd(); cd(conf.home); conf.home=cd; conf.home=cd(); cd(owd); % get the current home
%    conf.sub_agent = 'ssh mmmxserver.nici.ru.nl env SGE_ROOT=/usr/local/sge';
% else % windows config
%    conf.home='H:';
%    conf.sub_agent = sprintf('plink %s@neckar env SGE_ROOT=/usr/local/sge',getenv('USERNAME'));
% end

% generate the output
if ( nargout==1 ) varargout={struct('conf',conf,'opts',opts)}; 
else              varargout={conf,opts};
end