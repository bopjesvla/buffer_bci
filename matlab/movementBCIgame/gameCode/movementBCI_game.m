% Game that evokes a spontaneous button press by the player. 
% Computer predictions are made based on action history.
% A keyboard needs to be connected to control the game.
% Independent of the buffer_bci framework.
function movementBCI_game(subject)
    
    % get game settings
    setGame(subject);
    try
        load(['gameSettings_subject_',num2str(subject)]);
    catch
        msgbox({'Could not find game settings!'},'Error');
    end
    
    % set the real-time-clock to use
    initgetwTime;
    initsleepSec;

    % circle: equation to compute the size of the circle, scale to fit full screen at trialDuration
    pilerfn=@(time,maxsize,startsize) time*(maxsize-0.1)*(0.8/trialDuration) + startsize;

    % make the stimuli
    [fixcross,msgh,scoreh,feedback,fig,pileh]=init_stim(neutralColor,textColor);

    % install listener for key-press mode change
    set(fig,'keypressfcn',@(src,ev) set(src,'userdata',char(ev.Character(:))));
    set(fig,'userdata',[]);
    
    % define instructions
    instruct=instructions();
    
    % show instructions
    set(scoreh,'visible','off');
    set(msgh,'string',instruct,'visible','on');drawnow;
    waitforbuttonpress;
    set(msgh,'string','');
    drawnow;
    
    % play the stimulus
    for b=1:nr_blocks % for all rounds
        score = [0 0];
        human_stats = struct('N',0,'sx',0,'sx2',0,'mu',0,'var',0);
         for si=1:nSeq; % for all trials in a round
            %------------------------------------- Initialize -----------------------------
            % baseline
            set(fixcross,'string','+','visible','on','color',[1 0 0]); drawnow;
            set(scoreh,'visible','on','string',sprintf('%d/%d    you=%3g   comp=%3g',si,nSeq,score)); % update the score
            sleepSec(baselineDuration);

            % initialize stimuli
            [maxsize, startsize] = calculate_maxminsize(max_range, start_range);
            pile_r = pilerfn(0,maxsize,startsize); 
            set(pileh,'position',[.5-pile_r/2 .5-pile_r/2 pile_r pile_r],'facecolor',neutralColor,'visible','on'); drawnow;
            t0 = getwTime(); % get time trial start
            
            % decide on the computer move time estimate
            t_computer=(.5+(1-.5)*rand(1))*trialDuration; % simple uniform rand for now..
            if( human_stats.mu > 3 && human_stats.var>1 ) % gaussian est
                % generate random sample from the 'probe' distribution
                t_computer = ( human_stats.mu - 1.5 ) + rand(1)*sqrt(human_stats.var);
                if t_computer < min_time
                    t_computer = min_time; 
                elseif t_computer > max_time 
                    t_computer = max_time; 
                end
            end
            fprintf('%d) t_comp = %g    (%g,%g)\n',si,t_computer,human_stats.mu,human_stats.var);
            planned_comp = [planned_comp t_computer];
            
            % initialize variables
            t_now = 0;
            t_human = inf;
            set(fig,'userdata',[]); % clear the key buffer
            computer_won = false;
            human_won = false;
            checkKeys = true; % listen for keypresses from the human
            
            %------------------------------------- Run the trial -----------------------------
            while (t_now < trialDuration)
                t_now = getwTime()-t0; % get current trial-time
                drawnow; % update 'userdata'

                if ( ~ishandle(fig) ) % check whether the Matlab window is still controllable
                    break
                end

                % process human key-presses
                if checkKeys % while human has not pressed a button yet
                    modekey=get(fig,'userdata');
                    if ( ~isempty(modekey) ) % if there is a key press
                        t_human = t_now; % save it
                        set(fig,'userdata',[]);
                        rthuman = [rthuman t_human];
                        checkKeys = false; % stop listening for keypresses from the human
                        trialDuration = t_human + (max_trial_dur-min_trial_dur).*rand(1,1) + min_trial_dur;
                        if trialDuration > max_time
                            trialDuration = max_time; 
                        end
                    end
                end

                if ~computer_won && ~human_won % while nobody has won yet
                    % update the circle
                    pile_r = pilerfn(t_now,maxsize,startsize);
                    set(pileh,'position',[.5-pile_r/2 .5-pile_r/2 pile_r pile_r],'visible','on');
                    current_score=round(pile_r*10,1); % update the score each time the oval size is updated
                    drawnow;

                    % update the color+score to reflect who-moved-first
                    if( t_computer < t_human && t_computer < t_now ) % computer won
                        score(2) = score(2) + current_score;
                        computerwon(current_score, t_computer,fig, pileh, msgh, fixcross, compWinsColor, feedbackColor);
                        rtcomputer = [rtcomputer t_computer];
                        drawnow;
                        set(scoreh,'visible','on','string',sprintf('%d/%d    you=%3g   comp=%3g',si,nSeq,score)); % update the score
                        drawnow;
                        computer_won = true;
                        trialDuration = t_computer + (max_trial_dur-min_trial_dur).*rand(1,1) + min_trial_dur;
                        if trialDuration > max_time 
                            trialDuration = max_time; 
                        end
                    end

                    if( t_human < t_computer && t_human < t_now ) % human won
                        score(1) = score(1) +  current_score;
                        humanwon(current_score, fig, pileh, msgh, fixcross, humanWinsColor, feedbackColor)
                        drawnow;
                        set(scoreh,'visible','on','string',sprintf('%d/%d    you=%3g   comp=%3g',si,nSeq,score)); % update the score
                        human_won = true;
                    end
                end
            end

            if ( ~ishandle(fig) ) break; end;
            
            %------------------------------------- Update human move stats -----------------------------
            % TODO [] : add a forgetting factor? moving-window estimate?

            if t_human == Inf; % simulate the human time if computer won (to slow down computer predictions)
                t_human = t_computer + sim_time;
            end;

            human_stats.N   = human_stats.N  + 1;
            human_stats.sx  = human_stats.sx + t_human;
            human_stats.sx2 = human_stats.sx2+ t_human.^2;
            human_stats.mu  = human_stats.sx ./ human_stats.N; % mean
            human_stats.var = (human_stats.sx2 - human_stats.sx.^2./human_stats.N)./human_stats.N; % variance
            
            %------------------------------------- End trial -----------------------------
            % reset the cue and fixation point to indicate trial has finished
            set(msgh,'string','+','visible','off');
            set(pileh,'visible','off');
            drawnow;
            
            % inter-trial interval
            sleepSec(interTrialDuration);
         end 
        
        %------------------------------------- End round -----------------------------
        % break with feedback on round performance
        set(pileh,'visible','off'); set(msgh,'visible','off');set(scoreh,'visible','off'); set(fixcross,'visible','off');set(feedback,'visible','on');drawnow;

        setFeedback(feedback,b,textColor,score,nr_blocks);
        pause(5);
        
        set(feedback,'visible','off');
        save(fullfile('logfiles',['practice_subject',num2str(subject),'_block',num2str(b)]), 'planned_comp','human_stats', 'rthuman', 'rtcomputer') ;
        
        if b < nr_blocks           
            set(msgh, 'string',{'press <space> to start a new round'},'Color', textColor,'visible','on');drawnow;
            waitforbuttonpress;
            set(msgh, 'visible','off');
        end
    end
    
    %------------------------------------- End game -----------------------------
    % show end message
    set(msgh,'string',{'Thank you for playing!'},'visible','on','Color',[1 1 1]);drawnow;
    pause(5);
    
    % go back to game menu
    close(figure(2));
    figure(1);
end
