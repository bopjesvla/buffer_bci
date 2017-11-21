run ../../utilities/initPaths
datasets_brainfly();
%dataRootDir = '~/data/bci'; % main directory the data is saved relative to in sub-dirs
dataRootDir = '/Volumes/Wrkgrp/STD-Donders-ai-BCI_shared'; % main directory the data is saved relative to in sub-dirs
label   ='movement_crosssess'; % generic label for this slice/analysis type
analysisType='ersp';  % type of pre-processing / analsysi to do

% get the set of algorithms to run
algorithms_brainfly();
% list of default arguments to always use
% N.B. Basicially this is a standard ERSP analysis setup
default_args={,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','none','freqband',[6 8 80 90],'width_ms',250,'aveType','abs'};

% summary results storage.  Format is 2-d cell array.  
% Each row is an algorithm run with 4 columns: {subj session algorithm_label performance}
resultsfn=fullfile(dataRootDir,expt,sprintf('analyse_%s',label));
try % load the previously saved results if possible..
   if ( ~exist('results','var') ) 
      load(resultsfn);
   end
catch
   results=cell(0,4);
end

% run the given analysis
si=1; sessi=3;
for si=1:numel(datasets);
   if ( isempty(datasets{si}) ) continue; end;
   subj  = datasets{si}{1};
   dname = fullfile(dataRootDir,expt,subj,sprintf('%s_%s_sliced',subj,label(1:find(label=='_'))));

   if( ~(exist(dname,'file') || exist([dname '.mat'],'file')) )
     warning('Couldnt find sliced data for : %s.  skipping',dname);
     continue;
   end
   fprintf('Loading: %s\n',dname);
   load(dname);
   fprintf('Loaded %d events\n',numel(devents));
   if ( numel(devents)==0 ) continue; end;

                                % run the set of algorithms to test
   for ai=1:numel(algorithms)
     alg=algorithms{ai}{1};

                                % check if already been run
     mi=strcmp(subj,results(:,1)) &strcmp(saveDir,results(:,2)) &strcmp(alg,results(:,3));
     if( any(mi) ) 
       fprintf('Skipping prev run analysis: %s\n',alg);
       continue;
     end

     fprintf('Trying: %s %s\n',subj,alg);
     for sessi=1:numel(alldata); % leave session out algorithm
       d=alldata(sessi);
       if( strcmp(lower(analysisType),'ersp') )
         [clsfr,res]=buffer_train_ersp_clsfr(d.data,d.devents,d.hdr,default_args{:},algorithms{ai}{2:end},'visualize',0);
       elseif( strcmp(lower(analysisType),'erp') )
         [clsfr,res]=buffer_train_erp_clsfr(d.data,d.devents,d.hdr,default_args{:},algorithms{ai}{2:end},'visualize',0);
       else
         error('Unrecognised analysis type: %s',analysisType)
       end% save the summary results
       
       fprintf('%d) %4.2f/',sessi,res.opt.tst);
                                % test on the rest of the data
       tstsess=[];
       for tstd=1:numel(alldata);
         if(tstd==sessi); fprintf(' N/A  '); continue; end;
         d=alldata(sessi);
         f = buffer_apply_clsfr(clsfr,d.data,d.hdr); % predictions
         y = lab2ind({d.devents.value},clsfr.spKey,clsfr.spMx); % true-labels
         conf      = dv2conf(y,f); % confusion matrix
         tstsess(tstd) = conf2loss(conf,'bal'); % performance
         fprintf(' %4.2f ',tstses(tstd));
       end
                                % summary performance
       tst(sessi)=sum(tstsess)./(numel(alldata)-1);
       fprintf(' | %4.2f\n',tst(sessi));
     end
     results(end+1,:)={subj saveDir alg mean(tst)};
     fprintf('%d) %s %s %s = %f\n',ai,results{end,:});
   end
   
                                    % save the updated summary results
   results=sortrows(results,1:3); % canonical order... subj, session, alg
   fprintf('Saving results to : %s\n',resultsfn);
   save(resultsfn,'results');   
   fid=fopen([resultsfn '.txt'],'w'); rr=results'; fprintf(fid,'%8s,\t%30s,\t%40s,\t%4.2f\n',rr{:}); fclose(fid);
   
   
end % subjects
% show the final results set
results

% some simple algorithm summary info
algs=unique(results(:,3));
for ai=1:numel(algs);
   mi=strcmp(results(:,3),algs{ai});
   resai = [results{mi,4}];
   fprintf('%2d) %40s = %5.3f (%5.3f)\n',ai,algs{ai},mean(resai),std(resai));
end

