function []=startup();
%feature accel off
%help
%matlabpath(pathdef)
dbstop if error
format long g
format compact
global PLOTLEVEL; global DEBUGLEVEL;
warning('off','MATLAB:dispatcher:nameConflict');
% add all our sub-directories...
sourcedir='~/source/matfiles';
excludeDirs={'CVS','.svn','.git','__MACOSX','MacOS','private'};
N=genpath(sourcedir); 
dirIdx=[0 find(N==':')];
curpath = path;
curpath(curpath(1:end-1)=='/' & curpath(2:end)=='/')=[]; % strip double '/'
for i=1:numel(dirIdx)-1;
   dname=N(dirIdx(i)+1:dirIdx(i+1)-1);
   if ( isempty(strfind(curpath,dname(2:end))) )
      excluded=false;
      for i=1:numel(excludeDirs); 
         if ( ~isempty(strfind(dname,excludeDirs{i})) ) excluded=true;break;end
      end
      if( ~excluded ) 
         addpath(dname); curpath=[curpath ':' dname];
      end
   end;
end

% Add any path which has 'matlab' as its final directory part
sourcedir='~/source';
N=genpath(sourcedir); 
dirIdx=[0 find(N==':')];
curpath = path;
curpath(curpath(1:end-1)=='/' & curpath(2:end)=='/')=[]; % strip double '/'
for i=1:numel(dirIdx)-1;
   dname=N(dirIdx(i)+1:dirIdx(i+1)-1);
   if( isempty(strfind(curpath,dname(2:end))) && isequal(dname(find(dname==filesep,1,'last')+1:end),'matlab') )
       addpath(dname); curpath=[curpath ':' dname];
   end
end

global bciroot;
bciroot={'~/data/bci','/media/JASON_BACKU/data/bci','/Volumes/BCI_data'};
