% RUN advbci.m first!

function plots(results, transients, topo)
    % Transients: 
    if transients 
        x = linspace(0,0.3,108); 
        figure;
        suptitle('Transient responses per cv fold')
        subplot(2,1,1)
        hold on
        for i = 1:numel(results.c) %per cv fold
            y = results.c(i).transients(1:108); %short flash
            xlabel('Time [sec]');
            ylabel('Amp [a.u.] \pm std');
            title('Short flash')
            set(gca,'color',[.75 .75 .75]);
            plot(x, y)
        end
        hold off

        subplot(2,1,2)
        hold on 
        for i = 1:numel(results.c) 
            y = results.c(i).transients(109:216); %long flash
            xlabel('Time [sec]');
            ylabel('Amp [a.u.] \pm std');
            title('Long flash')
            set(gca,'color',[.75 .75 .75]);
            plot(x, y)
        end
        hold off
    end
    
    % Topo
    if topo
        figure; 
        suptitle('Topo plots per cv fold')
        for i = 1:10
            subplot(2,5,i)
            jt_topoplot(results.c(i).filter,struct('capfile',results.c(i).cfg.capfile,'electrodes','numbers'));
        end
    end
end

