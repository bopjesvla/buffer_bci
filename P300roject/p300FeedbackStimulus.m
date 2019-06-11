try; cd(fileparts(mfilename('fullpath')));catch; end;
try;
   run ../matlab/utilities/initPaths.m
catch
   msgbox({'Please change to the directory where this file is saved before running the rest of this code'},'Change directory'); 
end
try; cd(fileparts(mfilename('fullpath')));catch; end; %ARGH! fix bug with paths on Octave

buffhost='localhost';buffport=1972;
trigsocket=javaObject('java.net.DatagramSocket');
trigsocket.connect(javaObject('java.net.InetSocketAddress','localhost',8300));
% wait for the buffer to return valid header information
hdr=[];
while ( isempty(hdr) || ~isstruct(hdr) || (hdr.nchans==0) ) % wait for the buffer to contain valid data
  try 
    hdr=buffer('get_hdr',[],buffhost,buffport); 
  catch
    hdr=[];
    fprintf('Invalid header info... waiting.\n');
  end;
  pause(1);
end;

% set the real-time-clock to use
initgetwTime;
initsleepSec;

verb=0;
nSeq=15;
cueDuration=2;
stimDuration=.2; % the length a row/col is highlighted
feedbackDuration = 1;
interSeqDuration=2;
bgColor=[.5 .5 .5]; % background color (grey)
flashColor=[1 1 1]; % the 'flash' color (white)
tgtColor=[0 1 0]; % the target indication color (green)
fbColor = [0 0 1];



symbols={'pause', 'up', 'tvOff', 'tv1', 'food'; 'left', 'down', 'right', 'tv2','toilet'; 'call1','call2','call3', 'tv3', 'pain'};
numbers = [1 4 7 10 13; 2 5 8 11 14; 3 6 9 12 15];
commands_columns = ["pause", "navigate.up", "tv.end", "tv.1", "sos.food"; "navigate.left", "navigate.down", "navigate.right", "tv.2", "sos.toilet"; "call.1", "call.2", "call.3", "tv.3", "sos.pain"];
s = struct('action',{},'p',{});
bool = true;
% make the stimulus
clf;
[h]=initGrid(symbols);

tgtSeq = repmat([2:numel(symbols)]',ceil(nSeq/numel(symbols)));
tgtSeq = tgtSeq(randperm(nSeq-1));

flashseqsmall = [1 2 3 4 5 6 7 8];
flashseq = [flashseqsmall flashseqsmall flashseqsmall];
x = flashseq(randperm(length(flashseq)));
% x=flashseqsmall;

% play the stimulus
% reset the cue and fixation point to indicate trial has finished  
set(h(:),'color',[.5 .5 .5]);
msg=msgbox({'Press OK to start'},'OK');while ishandle(msg); pause(.2); end;
sendEvent('stimulus.training','start');
for si=1:nSeq;

  sleepSec(interSeqDuration);
  sendEvent('stimulus.sequence','start');
  set(h(:),'color',bgColor); % rest all symbols to background color

  % initialize the buffer_newevents state so that will catch all predictions after this time
  [ans,state]=buffer_newevents(buffhost,buffport,[],[],[],0);

  stimSeqrow=zeros(size(symbols,1),3*size(symbols,1));
  stimSeqcol=zeros(size(symbols,2),3*size(symbols,2)); % [nSyb x nFlash] used record what flashed when
  nFlashcol=0;
  nFlashrow=0;
  tgtIdx = tgtSeq(si);
  for ri=1:numel(x); % reps
      
%     for ei=1:numel(symbols); % symbs
      set(h(:),'color',bgColor);
      if x(ri) > 5
        rowflashed = x(ri)-5;
        nFlashrow = nFlashrow+1;
        set(h(rowflashed,:),'color',flashColor);
        for i = 1:15
            if ismember(i,numbers(rowflashed,:))
               stimSeqrow(rowflashed,nFlashrow) = true;
            end
        end
       
        drawnow;
        ev=sendEvent('stimulus.rowFlash',numbers(rowflashed,:)); % indicate this row is 'flashed'
%         sendEvent('stimulus.rowtgtFlash',ismember(tgtIdx, numbers(rowflashed,:)),ev.sample); % indicate 'target' flashs
%         if ismember(tgtIdx, numbers(rowflashed,:))
%             trigsocket.send(javaObject('java.net.DatagramPacket',int8([1 0]),1));
%         end
      else
        colflashed = x(ri);
        nFlashcol = nFlashcol + 1;
        set(h(:,colflashed),'color',flashColor);
        for i = 1:15
            if ismember(i,numbers(:,colflashed))
               stimSeqcol(colflashed,nFlashcol) = true;
            end
        end
        drawnow;
        ev=sendEvent('stimulus.colFlash',numbers(:,colflashed));
%         sendEvent('stimulus.coltgtFlash',ismember(tgtIdx, numbers(:,colflashed)),ev.sample); % indicate 'target' flashs
%         if ismember(tgtIdx, numbers(:,colflashed))
%             trigsocket.send(javaObject('java.net.DatagramPacket',int8([1 0]),1));
%         end
      end
      
%       flashIdx=ei;
%       % flash

      
      sleepSec(stimDuration);
      % reset
      set(h(:),'color',bgColor);
      drawnow;      
%     end
  end

  % combine the classifier predictions with the stimulus used
  % wait for the signal processing pipeline to return the set of predictions
  if( verb>0 ) fprintf(1,'Waiting for predictions\n'); end;
  [rowdevents,~]=buffer_newevents(buffhost,buffport,state,'classifier.prediction.row',[],500);

  [coldevents,state]=buffer_newevents(buffhost,buffport,state,'classifier.prediction.col',[],500);
  if ( ~isempty(coldevents) ) 
    % correlate the stimulus sequence with the classifier predictions to identify the most likely letter
    pred =[coldevents.value]; % get all the classifier predictions in order
    nPred=numel(pred);
    sscol   = reshape(stimSeqcol(:,1:nFlashcol),[size(symbols,2) nFlashcol]);
    corrcol = sscol(:,1:nPred)*pred(:)/3;  % N.B. guard for missing predictions!
    [ans,predTgtcol] = max(corrcol); % predicted target is highest correlation
    
  end
  if ( ~isempty(rowdevents) ) 
    % correlate the stimulus sequence with the classifier predictions to identify the most likely letter
    pred =[rowdevents.value]; % get all the classifier predictions in order
    nPred=numel(pred);
    ssrow   = reshape(stimSeqrow(:,1:nFlashrow),[size(symbols,1) nFlashrow]);
    corrrow = (ssrow(:,1:nPred)*pred(:))/3;  % N.B. guard for missing predictions!
    [ans,predTgtrow] = max(corrrow); % predicted target is highest correlation
    
  end
  temp = 1;
  string = "";
  for i=1:numel(corrcol)
      for j=1:numel(corrrow)
          string = string + commands_columns{temp} + "," + corrrow(j)*corrcol(i) + newline;
          temp = temp+1;
      end
  end
  sendEvent('p300preds', string);  
  
  while bool
      [prediction,state]=buffer_newevents(buffhost,buffport,state,'finalprediction',[],500);
      if(~isempty(prediction))
          bool = false;
            
        % show the classifier prediction
          [row, col] = find(commands_columns == prediction.value);
          set(h(row,col),'color',fbColor);
          drawnow;
          sleepSec(feedbackDuration);
      end
  end
  bool = true;
%   predictions(si) = numbers(row,col);
end % sequences
% end training marker
sendEvent('stimulus.feedback','end');
