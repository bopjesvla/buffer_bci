function [] = rh_plotTransients( results )
    %rh_plotTransients plots transient responses from results. 
    %   The output of this function is a figure with 5x2 subplots. These 
    % subplots are filled with the transient responses of all participants.
    % One plot contains four lines, one for each participant. On the left, 
    % the responses to the short stimulus are shown. On the right, to the 
    % long stimulus. 

    f = figure;
    p = uipanel('Parent',f,'BorderType','none'); 
    p.Title = 'Transient responses'; 
    p.TitlePosition = 'centertop'; 
    p.FontSize = 12;
    p.FontWeight = 'bold';

    labels = {'black\_white', 'blue\_green', 'blue\_yellow', 'red\_green', 'red\_yellow'};
    stim = {' long', ' short'};

    x = linspace(0,0.3,108); 

    for i = 1 : 5 

        subplot(5,2,i*2-1,'Parent',p) 
        for j = 1 : 4 
            y = results{1,i}(j).c(10).transients(1:108);
            hold on
            plot(x,y);
            hold off
            xlabel('Time [sec]');
            ylabel('Amp [a.u.] \pm std');
            set(gca,'color',[.75 .75 .75]);
            title(strcat(labels{1,i}, stim{1,2}));
        end

        subplot(5,2,i*2,'Parent',p)
        for j = 1 : 4 
            y = results{1,i}(j).c(10).transients(109:216);
            hold on
            plot(x,y);
            hold off
            xlabel('Time [sec]');
            ylabel('Amp [a.u.] \pm std');
            set(gca,'color',[.75 .75 .75]);
            title(strcat(labels{1,i}, stim{1,1}));
        end
    end
    hL = legend({'s01','s02','s03','s04'},'orientation','horizontal');
    newPosition = [0.5 0.1 0.2 0.1];
    set(hL,'Position', newPosition,'Units', 'normalized');
end

