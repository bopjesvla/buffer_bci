function [] = setRect(window, rect, action, color, textcolor)
%SETRECTS Summary of this function goes here
%   Detailed explanation goes here
    Screen('TextSize', window, 60);
    Screen('TextFont', window, 'Arial');
    textoffset = [20 125]; 
    
    % Draw the rects to the screen
    Screen('FillRect', window, color, rect);

    % Draw the text
    DrawFormattedText(window, action, rect(1)+textoffset(1), rect(2)+textoffset(2), textcolor); 
end

