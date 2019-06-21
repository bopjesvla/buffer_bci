% This script manages the window and the stimuli during the calibration 
% phase. It also connects to the buffer to send events in order to indicate
% what is happening on the screen. Parameters are configurable to modify
% the experiment. 

% Setting paths and connecting to the buffer
try cd(fileparts(mfilename('fullpath'))); catch; end
try
   run ../matlab/utilities/initPaths.m
catch
   msgbox({'Please change to the directory where this file is saved'...
       'before running the rest of this code'}, 'Change directory'); 
end
try cd(fileparts(mfilename('fullpath'))); catch; end 

buffhost = 'localhost'; buffport = 1972;
% Wait for the buffer to return valid header information
hdr=[];
while ( isempty(hdr) || ~isstruct(hdr) || (hdr.nchans==0) ) 
  try 
    hdr=buffer('get_hdr', [], buffhost, buffport); 
  catch
    hdr=[];
    fprintf('Invalid header info... waiting.\n');
  end
  pause(1);
end

% Set the real-time-clock to use
initgetwTime;
initsleepSec;

% CONFIGURABLE PARAMETERS
verb = 1;               % Verb = 1 for debug information
nSeq = 30;          	% Amount of sequences. Multiple of 15
cueDuration = 2;        % Time in seconds a cue is displayed
afterCueDuration = 1;   % Time in seconds after a cue is displayed
stimDuration = .2;      % Time in seconds a row/col is highlighted
interSeqDuration = 2;   % Time in seconds after 1 sequence of stimulation
bgColor = [.5 .5 .5];   % Background color (grey)
flashColor = [1 1 1];   % Flash color (white)
tgtColor = [0 1 0];     % Target indication color (green)

% The grid in textual and numerical representation
symbols={'pause', 'up', 'tvOff', 'tv1', 'food';...
         'left', 'down', 'right', 'tv2','toilet';...
         'call1','call2','call3', 'tv3', 'pain'};
numbers = reshape(1:15, [3 5]);

% WINDOW INITIALIZATION
clf;
[h] = initGrid(symbols);

% Setting and shuffling targets
tgtSeq = repmat((1:numel(symbols))', ceil(nSeq/numel(symbols)));
tgtSeq = tgtSeq(randperm(nSeq));

% Setting and shuffling flash sequences
flashseq = repmat(1:8, [1 3]); 
% 1:5 are columns, 6:8 are rows
x = flashseq(randperm(length(flashseq)));

% Start the calibration after pressing OK
msg=msgbox({'Press OK to start'}, 'OK'); while ishandle(msg); pause(.2); end
sendEvent('stimulus.training', 'start');
for si = 1:nSeq % For every sequence
  sleepSec(interSeqDuration);
  sendEvent('stimulus.sequence', 'start');
  tgtIdx = tgtSeq(si);
  set(h(tgtIdx),'color',tgtColor);
  drawnow; % Show the cue
  sendEvent('stimulus.targetSymbol', symbols{tgtIdx});
  if verb; fprintf('%d) tgt=%s : ', si, symbols{tgtSeq(si)}); end
  sleepSec(cueDuration);  
  set(h(tgtIdx),'color',bgColor); 
  drawnow; % Remove the cue
  sleepSec(afterCueDuration); 
  for ri = 1:numel(x) % For every repetition
      set(h(:),'color',bgColor);
      if x(ri) > 5 % If a row should flash
        rowflashed = x(ri)-5;
        set(h(rowflashed,:),'color',flashColor);
        drawnow; % Initiate row flash
        ev = sendEvent('stimulus.rowflash', numbers(rowflashed, :)); 
        sendEvent('stimulus.rowtgtFlash', ismember(tgtIdx, ...
            numbers(rowflashed, :)), ev.sample); % True if target flashed
      else % A column should flash
        colflashed = x(ri);
        set(h(:,colflashed),'color',flashColor);
        drawnow; % Initiate column flash
        ev=sendEvent('stimulus.colflash',numbers(:,colflashed));
        sendEvent('stimulus.coltgtFlash',ismember(tgtIdx, ...
            numbers(:,colflashed)),ev.sample); % True if target flashed
      end
      sleepSec(stimDuration);
      set(h(:),'color',bgColor);
      drawnow; % Terminate flash
  end
  sendEvent('stimulus.sequence','end');
  if verb; fprintf('\n'); end
end
sendEvent('stimulus.training','end');