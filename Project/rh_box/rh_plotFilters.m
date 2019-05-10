function [] = rh_plotFilters( results )
    %rh_plotFilters plots spatial filters for all conditions and all 
    %participants. Output is a figure with 5x4 subplots filled with 
    %spatial filters. 

    f = figure;
    p = uipanel('Parent',f,'BorderType','none'); 
    p.Title = 'Spatial filters'; 
    p.TitlePosition = 'centertop'; 
    p.FontSize = 12;
    p.FontWeight = 'bold';

    labels = {' black\_white', ' blue\_green', ' blue\_yellow', ' red\_green', ' red\_yellow'};
    participants = {'s01','s02','s03','s04'};

    for i = 1 : length(results) % loop over conditions
        for j = 1 : 4 % loop over participants
            subplot(5,4,4*i-4+j,'Parent',p)
            jt_topoplot(mean(results{1,i}(j).c(10).filter, 2),struct('capfile',results{1,i}(j).c(10).cfg.capfile,'electrodes','numbers'));
            title(strcat(participants(j),labels(i)));
        end
    end
    
    % code for creating average spatial filters. NOT FINISHED
    % % rearrange data for averages
    % for i = 1 : length(results) % loop over conditions
    %     for c = 1 : length(results{1,1}(1).c(10).filter) % loop over electrodes
    %         for j = 1 : length(results{1}) % loop over participants
    %             elektrodeAverages{i,c}(j) = results{1,i}(j).c(10).filter(c);
    %         end
    %         filterAverages(c) = mean(elektrodeAverages{i,c});
    %     end
    % end
end

