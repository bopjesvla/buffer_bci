sca;
close all;
clear;

try; cd(fileparts(mfilename('fullpath')));catch; end;
try;
   run ../matlab/utilities/initPaths.m
catch
   msgbox({'Please change to the directory where this file is saved before running the rest of this code'},'Change directory'); 
end

buffhost='localhost';buffport=1972;
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

trigsocket=javaObject('java.net.DatagramSocket'); trigsocket.connect(javaObject('java.net.InetSocketAddress','localhost' ,8300));

load('mgold_61_6521.mat')

actions={'pause', 'up', 'tvOff', 'tv1', 'food'; 'left', 'down', 'right', 'tv2','toilet'; 'call1','call2','call3', 'tv3', 'pain'};
% actions={'Pause', 'up', 'tvOff', 'tv01', 'Food', 'left', 'down', 'right', 'tv02','toilet', 'call01','call02','call03', 'tv03', 'pain'};
textoffset = [20 125]; 
grey = 0.5;
[allrects, window] = initalizeGrid(actions);

ifi = Screen('GetFlipInterval', window);
%practice block focus 1 keer op elke actie (laat dit voor 4
%goldcodesequences runnen. Doe dit 2 keer.
%randomize the action to focus to
targeton = false;
% for action=1:15
%     set(hpanel(action),'BackgroundColor',[0,0,0]);
%     set(htext(action),'BackgroundColor',[0,0,0]);
% 
% end
% drawnow;
% msg=msgbox({'Press OK to start'},'Continue?');while ishandle(msg); pause(.2); end;
sendEvent('Stimulus.start', 'start');

for seq=1:2
    x = randperm(15);
    for target=1:length(x)
        sendEvent('Stimulus.showcue', x(target));
        for action=1:15
            if x(target)==action
                setRect(window, allrects(:,action), actions{action},0,[0,1,0]);
            else
                setRect(window, allrects(:,action), actions{action},0,grey);
            end
        end
        Screen('Flip', window);
        sleepSec(2);  
        for action=1:15
            setRect(window, allrects(:,action), actions{action},0,grey);
        end
        Screen('Flip', window);
        sleepSec(1);
        ev=sendEvent('Stimulus.action',x(target));
        for codereps=1:4
            for i=1:126
                %update alle actions
                for action=1:15
                    if(codes(i,action) == 0)
                        setRect(window, allrects(:,action), actions{action},0,grey);
                    else
                        setRect(window, allrects(:,action), actions{action},1,grey);
                    end
                end
                Screen('Flip', window);
                Screen('WaitBlanking', window);
                %1 keer hele goldcode sequence = 1.05 sec, net als in thielen et al.
%                 sleepSec(0.01666667);
            end
        end
        %reset de basic grid
        for action=1:15
            setRect(window, allrects(:,action), actions{action},0,grey);
        end
        Screen('Flip', window);
        sleepSec(2);
    end
end
% sendEvent('Stimulus.action', 'end');
sendEvent('Stimulus.end'); 

DrawFormattedText(window, 'End of experiment, press a key...', 'center', 'center', black); 
KbStrokeWait;
% 
% % Clear the screen
sca;
