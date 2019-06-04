try; cd(fileparts(mfilename('fullpath')));catch; end;
try;
   run ../../matlab/utilities/initPaths.m
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
nSeq=1;
nRepetitions=5;  % the number of complete row/col stimulus before sequence is finished
cueDuration=2;
stimDuration=.2; % the length a row/col is highlighted
interSeqDuration=2;
bgColor=[.5 .5 .5]; % background color (grey)
flashColor=[1 1 1]; % the 'flash' color (white)
tgtColor=[0 1 0]; % the target indication color (green)

% the set of options the user will pick from
% symbols={'A' 'B'; 'C' 'D'};
symbols={'pause', 'up', 'tvOff', 'tv1', 'food'; 'left', 'down', 'right', 'tv2','toilet'; 'call1','call2','call3', 'tv3', 'pain'};
numbers = [1 4 7 10 13; 2 5 8 11 14; 3 6 9 12 15];

% make the stimulus
clf;
[h]=initGrid(symbols);

tgtSeq = repmat([1:numel(symbols)]',ceil(nSeq/numel(symbols)));
tgtSeq = tgtSeq(randperm(nSeq))

flashseqsmall = [1 2 3 4 5 6 7 8];
flashseq = [flashseqsmall flashseqsmall flashseqsmall];
x = flashseq(randperm(length(flashseq)));
% x=flashseqsmall;

% play the stimulus
% reset the cue and fixation point to indicate trial has finished  
set(h(:),'color',[.5 .5 .5]);
sendEvent('stimulus.training','start');
for si=1:nSeq;

  sleepSec(interSeqDuration);
  sendEvent('stimulus.sequence','start');
  % show the subject cue where to attend
  tgtIdx=tgtSeq(si);
  set(h(tgtIdx),'color',tgtColor);
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  sendEvent('stimulus.targetSymbol',symbols{tgtIdx});
  fprintf('%d) tgt=%s : ',si,symbols{tgtSeq(si)}); % debug info
  sleepSec(cueDuration);  
  set(h(:),'color',bgColor); % rest all symbols to background color
  drawnow;
  sleepSec(1); 
  for ri=1:numel(x); % reps
%     for ei=1:numel(symbols); % symbs
      set(h(:),'color',bgColor);
      if x(ri) > 5
        rowflashed = x(ri)-5;
        set(h(rowflashed,:),'color',flashColor);
        drawnow;
        ev=sendEvent('stimulus.rowflash',numbers(rowflashed,:)); % indicate this row is 'flashed'
        sendEvent('stimulus.rowtgtFlash',ismember(tgtIdx, numbers(rowflashed,:)),ev.sample); % indicate 'target' flashs
        if ismember(tgtIdx, numbers(rowflashed,:))
            trigsocket.send(javaObject('java.net.DatagramPacket',int8([1 0]),1));
        end
      else
        colflashed = x(ri);
        set(h(:,colflashed),'color',flashColor);
        drawnow;
        ev=sendEvent('stimulus.colflash',numbers(:,colflashed));
        sendEvent('stimulus.coltgtFlash',ismember(tgtIdx, numbers(:,colflashed)),ev.sample); % indicate 'target' flashs
        if ismember(tgtIdx, numbers(:,colflashed))
            trigsocket.send(javaObject('java.net.DatagramPacket',int8([1 0]),1));
        end
      end
      
%       flashIdx=ei;
%       % flash

      
      sleepSec(stimDuration);
      % reset
      set(h(:),'color',bgColor);
      drawnow;      
%     end
  end
   
  % reset the cue and fixation point to indicate trial has finished  
  set(h(:),'color',bgColor);
  drawnow;
  sendEvent('stimulus.sequence','end');
  fprintf('\n');
end % sequences
% end training marker
sendEvent('stimulus.training','end');
