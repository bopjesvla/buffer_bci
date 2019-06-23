% This script manages the window and stimuli for the feedback part of the
% experiment. It connects to the buffer in which it sends the annotations
% for which row/column flashed, waits for the classifier prediction and
% then shows feedback on the screen.

% Connecting to the buffer
try cd(fileparts(mfilename('fullpath'))); catch; end
try
    run ../matlab/utilities/initPaths.m
catch
    msgbox({'Please change to the directory where this file is saved'...
        'before running the rest of this code'},'Change directory');
end
try cd(fileparts(mfilename('fullpath'))); catch; end

buffhost = 'localhost'; buffport = 1972;

% wait for the buffer to return valid header information
hdr = [];
while ( isempty(hdr) || ~isstruct(hdr) || (hdr.nchans==0) ) % wait for the buffer to contain valid data
    try
        hdr=buffer('get_hdr', [], buffhost ,buffport);
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
verb = 1;               % Prints debug information
nSeq = 15;              % Length of the demo sequence
cueDuration = 2;        % Cue duration in seconds
stimDuration = .2;      % Flash duration in seconds
feedbackDuration = 1;   % Feedback duration in seconds
interSeqDuration = 2;   % Rest time after a sequence in seconds
bgColor = [.5 .5 .5];   % Background color (grey)
flashColor = [1 1 1];   % Flash color (white)
tgtColor = [0 1 0];     % Target indication color (green)
fbColor = [0 0 1];      % Feedback color (blue)
tgtSeq = [2 2 2 2 2 ...
    5 5 5 5 5 6 10 ...
    11 7 15]';          % Target sequence as in the demo

% The grid in textual, numerical and command representation
symbols = {'pause', 'up', 'tvOff', 'tv1', 'food'; ...
    'left', 'down', 'right', 'tv2','toilet'; ...
    'call1','call2','call3', 'tv3', 'pain'};
numbers = reshape(1:15, [3 5]);
commands_columns = ["pause", "navigate.up", "tv.end", "tv.1", "sos.food"; ...
    "navigate.left", "navigate.down", "navigate.right", "tv.2", "sos.toilet";...
    "call.1", "call.2", "call.3", "tv.3", "sos.pain"];
s = struct('action', {}, 'p', {});

% Initialize the window
clf;
[h] = initGrid(symbols);

% Setting and shuffling flash sequences
flashseq = repmat(1:8, [1 3]);
% 1:5 are columns, 6:8 are rows
x = flashseq(randperm(length(flashseq)));

% Start after pressing OK
msg=msgbox({'Press OK to start'}, 'OK'); while ishandle(msg); pause(.2); end
sendEvent('stimulus.training', 'start');

while true
    sleepSec(interSeqDuration);
    % initialize the buffer_newevents state so that will catch all predictions after this time
    [~,state] = buffer_newevents(buffhost, buffport, [], [], [], 0);
    
    stimSeqrow = zeros(size(symbols, 1), 3 * size(symbols, 1));
    stimSeqcol = zeros(size(symbols, 2), 3 * size(symbols, 2)); % [nSyb x nFlash] used record what flashed when
    nFlashcol = 0;
    nFlashrow = 0;
    
    for ri=1:numel(x)
        set(h(:),'color',bgColor);
        if x(ri) > 5 % If a row should flash
            rowflashed = x(ri) - 5;
            nFlashrow = nFlashrow + 1;
            set(h(rowflashed, :), 'color', flashColor);
            for i = 1:15
                if ismember(i, numbers(rowflashed, :))
                    stimSeqrow(rowflashed, nFlashrow) = true;
                end
            end
            drawnow; % Flash the row
            ev=sendEvent('stimulus.rowFlash', numbers(rowflashed, :));
        else
            colflashed = x(ri); % A column should flash
            nFlashcol = nFlashcol + 1;
            set(h(:, colflashed), 'color', flashColor);
            for i = 1:15
                if ismember(i,numbers(:, colflashed))
                    stimSeqcol(colflashed, nFlashcol) = true;
                end
            end
            drawnow; % Flash the column
            ev=sendEvent('stimulus.colFlash', numbers(:, colflashed));
        end
        sleepSec(stimDuration);
        set(h(:), 'color', bgColor);
        drawnow; % Reset
    end
    
    % combine the classifier predictions with the stimulus used
    % wait for the signal processing pipeline to return the set of predictions
    if( verb>0 ); fprintf(1, 'Waiting for predictions\n'); end
    % Don't save the state, it will remove coldevents
    [rowdevents,~] = buffer_newevents(buffhost, buffport, state, 'classifier.prediction.row', [], 500);
    % Now also save the state
    [coldevents, state] = buffer_newevents(buffhost, buffport, state, 'classifier.prediction.col', [], 500);
    if ( ~isempty(coldevents) )
        % correlate the stimulus sequence with the classifier predictions
        % to identify the most likely column
        pred = [coldevents.value]; % get all the classifier predictions in order
        nPred = numel(pred);
        sscol = reshape(stimSeqcol(:, 1:nFlashcol), [size(symbols, 2) nFlashcol]);
        corrcol = sscol(:, 1:nPred) * pred(:) / 3;  % N.B. guard for missing predictions!
        [~, predTgtcol] = max(corrcol); % predicted target is highest correlation
        
    end
    if ( ~isempty(rowdevents) )
        % correlate the stimulus sequence with the classifier predictions
        % to identify the most likely row
        pred = [rowdevents.value]; % get all the classifier predictions in order
        nPred = numel(pred);
        ssrow = reshape(stimSeqrow(:, 1:nFlashrow), [size(symbols, 1) nFlashrow]);
        corrrow = (ssrow(:, 1:nPred) * pred(:)) / 3;  % N.B. guard for missing predictions!
        [~, predTgtrow] = max(corrrow); % predicted target is highest correlation
        
    end
    
    % Send event to the buffer to process it with the priors
    index = 1;
    information = "";
    for i=1:numel(corrcol)
        for j=1:numel(corrrow)
            information = information + commands_columns{index} + "," + corrrow(j)*corrcol(i) + newline;
            index = index + 1;
        end
    end
    sendEvent('p300preds', information);
    
    % Wait for final prediction
    endmarker = false;
    while ~endmarker
        [prediction, ~] = buffer_newevents(buffhost, buffport, state, 'finalprediction', [], 500);
        if(~isempty(prediction))
            endmarker = true;
            
            % show the classifier prediction
            [row, col] = find(commands_columns == prediction.value);
            set(h(row, col), 'color', fbColor);
            drawnow; % Show the feedback
            sleepSec(feedbackDuration);
        end
    end
    endmarker = false;
end
% Only send ready event if ready. Because the demo only stops after
% issueing all the required commands (does not account for failing), the
% complete length is variable.
% sendEvent('stimulus.feedback','end');
