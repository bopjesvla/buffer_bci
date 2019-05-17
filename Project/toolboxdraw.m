% Clear the workspace and the screen


% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 1);

% Get the screen numbers
screens = Screen('Screens');

% Draw to the external screen if avaliable
screenNumber = max(screens);

% Define black and white
black = BlackIndex(screenNumber);
white = WhiteIndex(screenNumber);
grey = white / 2;

% Open an on screen window
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey);
ifi = Screen('GetFlipInterval', window)
DrawFormattedText(window, 'Press a key to begin...', 'center', 'center', black); 

% Flip to the screen
Screen('Flip', window);

% Wait for a key press
KbStrokeWait;

% Get the size of the on screen window
[screenXpixels, screenYpixels] = Screen('WindowSize', window);
screenYpixels = screenYpixels - 1;

% Make a base Rect of 200 by 200 pixels
outerxborder = 100; 
outeryborder = 100;
xborder = 50; 
yborder = 50; 

xlen = (screenXpixels-2*outerxborder)/5 - 2*xborder; 
ylen = (screenYpixels-2*outeryborder)/3 - 2*yborder; 

amountrects = 15;

allrects = zeros(4,amountrects); 
rectCenters = zeros(2, amountrects); 

actions={'pause', 'up', 'tvOff', 'tv1', 'food', 'left', 'down', 'right', 'tv2','toilet', 'call1','call2','call3', 'tv3', 'pain'};
Screen('TextSize', window, 60);
Screen('TextFont', window, 'Arial');

textoffset = [20 125]; 

for i=1:amountrects
    x = mod(i,5);
    y = mod(i,3);
    startx = outerxborder + xborder + x*(xlen+2*xborder); 
    starty = outeryborder + yborder + y*(ylen+2*yborder); 
    endx = startx + xlen; 
    endy = starty + ylen;   
    rect = [startx, starty, endx, endy]; 
    allrects(:,i) = rect;
end

startcolors = ones(3, amountrects); 

% Draw the rects to the screen
Screen('FillRect', window, startcolors, allrects);

% Draw the text
for i = 1:15
    rect = allrects(:,i);
    DrawFormattedText(window, actions{i}, rect(1)+textoffset(1), rect(2)+textoffset(2), grey); 
end

% Flip to the screen
Screen('Flip', window);



% % Wait for a key press
KbStrokeWait;
% 
% % Clear the screen
sca;