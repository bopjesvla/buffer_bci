function [hdls,symbols,opts]=initGrid(symbols,varargin)
% Layout a set of symbols in a figure axes in the shape the input symbols
% Inputs:
%  symbols - {cell nRow x nCols} cell array of strings to layout
% Options:
%  fontSize
%  fig - [1 x 1] handle to the figure to draw in
% Outputs:
%  hdls -- [nRow x nCols] set of handles to the text elements

opts = struct('fontSize', .1, 'fig', [], 'interBoxGap', .01);
opts = parseOpts(opts, varargin);

% prepare figure
if ( ~isempty(opts.fig) ); figure(opts.fig); else; opts.fig = gcf; end

% Set the axes to invisible
set(gcf, 'color', [0 0 0]);
set(gca, 'visible', 'off');
set(gca, 'YDir', 'reverse');
set(gca, 'xlim', [0 1], 'ylim', [0 1]);

% Compute the fontsize in pixels
set(opts.fig, 'Units', 'pixel');
wSize = get(opts.fig, 'position');
fontSize = opts.fontSize * wSize(4);

% Initialize the symbols
hdls = zeros([size(symbols), 1]);
h = 1 / (size(symbols, 1) + 1); w = 1 / (size(symbols, 2) + 1);
for i = 1:size(symbols, 1)
    for j = 1:size(symbols, 2)
        x= j * w; y = i * h;
        hdls(i, j, 1) = text(x, y - h * .1, symbols{i, j}, 'fontunits','pixel',...
            'fontsize', fontSize, 'HorizontalAlignment', 'center', 'FontWeight',...
            'bold', 'Color' ,[.5 .5 .5]);
    end
end
drawnow; % Broadcast symbols to screen
return;
