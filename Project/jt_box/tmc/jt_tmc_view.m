function [classifier] = jt_tmc_view(classifier)
%[classifier] = jt_tmc_view(classifier)
% Plots the classifier: temporal filter, spatial filter, stopping margins,
% and estimated accuracy
%
% INPUT
%   classifier = [struct] classifier structure
%
% OUTPUT
%   classifier = [struct] classifier with (updated) handle

% Initialize figure
classifier.view = figure(8392);
set(classifier.view,...
    'name', sprintf('jt_tmc_view | %s', classifier.cfg.user),...
    'numbertitle', 'off', ...
    'toolbar', 'none', ...
    'menubar', 'none', ...
    'units', 'normalized', ...
    'position', [.2 .2 .6 .6], ...
    'color', [0.5 0.5 0.5], ...
    'visible', 'off');

% Transient responses
subplot(2, 3, 1:2);
cla(gca);
if jt_exists_in(classifier, 'transients')
    lengths = floor(classifier.cfg.L * classifier.cfg.fs);
    n_transients = numel(lengths);
    colors = hsv(n_transients);
    labels = cell(1, n_transients);
    hold on;
    for i_transient = 1:n_transients
        labels{i_transient} = num2str(i_transient);
        duration = 0:1 / classifier.cfg.fs:(lengths(i_transient) - 1) / classifier.cfg.fs;
        transient = classifier.transients(1 + sum(lengths(1:i_transient - 1)):sum(lengths(1:i_transient)), :);
        plot(duration, transient, 'color', colors(i_transient, :), 'linewidth', 1.5);
    end
    set(gca, 'xlim', [0 max(classifier.cfg.L)]);
    legend(labels, 'location', 'NorthEast');
end
xlabel('time [sec]');
ylabel('amplitude [a.u.]');
set(gca, 'color', [.75 .75 .75], 'xgrid', 'on', 'ygrid', 'on', 'box', 'on');
title('transient responses');

% Spatial filter
subplot(2, 3, 3);
cla(gca);
if jt_exists_in(classifier, 'filter')
    jt_topoplot(mean(classifier.filter, 2), struct('capfile', classifier.cfg.capfile, 'electrodes', 'numbers'));
end
set(gca, 'color', [.75 .75 .75], 'box', 'on');
title('spatial filter');

% Margins
subplot(2, 3, 4:5);
cla(gca);
if jt_exists_in(classifier, 'margins')
    duration = (1:numel(classifier.margins)) * classifier.cfg.segmenttime;
    plot(duration, classifier.margins, '-b', 'linewidth', 1.5);
    set(gca, 'xlim', [0 max(duration)], 'ylim', [0 1]);
end
xlabel('trial duration [sec]');
ylabel('margin [rho]');
set(gca, 'color', [.75 .75 .75], 'xgrid', 'on', 'ygrid', 'on', 'box', 'on');
title('stopping margins');

% Classification performance
subplot(2, 3, 6);
cla(gca);
set(gca, 'xlim', [0 1], 'ylim', [0 1]);
if jt_exists_in(classifier, 'accuracy') && jt_exists_in(classifier.accuracy, 'p')
    text(.1, .5, sprintf(...
        ['P = %.2f %% \n' ...
         'T = %.2f sec \n' ...
         'D = %.2f sec \n' ...
         'N = %d \n' ...
         'ITI = %.2f sec\n' ...
         'ITR = %.2f bits/min'], ...
        classifier.accuracy.p * 100, ...
        classifier.accuracy.t, ...
        classifier.accuracy.d, ...
        size(classifier.stim.Mus, 3), ...
        classifier.cfg.intertrialtime, ...
        classifier.accuracy.itr), ... 
        'fontsize', 16);
end
set(gca, 'color', [.75 .75 .75], 'xtick', [], 'ytick', [], 'box', 'on');
if classifier.cfg.verbosity == 2
    title('performance estimate (on train data)');
elseif classifier.cfg.verbosity == 3
    title(sprintf('performance estimate (%d-fold cv)', classifier.cfg.nfolds));
else
    title('performance estimate');
end

% Visualize figure
set(classifier.view, 'visible', 'on');
drawnow;