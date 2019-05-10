function [hdlspanel,hdlstext,symbols,opts]=initGrid(symbols,varargin)
% layout a set of symbols in a figure axes in the shape the input symbols
%
% [hdls]=initGrid(symbols,varargin)
%
% Inputs:
%  symbols - {cell nRow x nCols} cell array of strings to layout
% Options:
%  fontSize
%  fig - [1 x 1] handle to the figure to draw in
% Outputs:
%  hdls -- [nRow x nCols] set of handles to the text elements
opts=struct('fontSize',.1,'fig',[],'interBoxGap',.01);
opts=parseOpts(opts,varargin);
% prepare figure
if ( ~isempty(opts.fig) ) figure(opts.fig); else opts.fig=gcf; end;
% set the axes to invisible
set(gcf,'color',[0.5 0.5 0.5]); 
set(gca,'visible','off');
set(gca,'YDir','reverse');
set(gca,'xlim',[0 1],'ylim',[0 1]);

% compute the fontsize in pixels
set(opts.fig,'Units','pixel');
wSize=get(opts.fig,'position');
fontSize = opts.fontSize*wSize(4);
% init the symbols
hdlspanel   =zeros([size(symbols),1]);
hdlstext   =zeros([size(symbols),1]);
h = 1/(size(symbols,1)+1); w=1/(size(symbols,2)+1);
main = uipanel('Position',[0.05 0.1 .9 .81], 'BackgroundColor',[0.5, 0.5, 0.5], 'BorderType', 'none')
for i = 1:size(symbols,1)
  for j = 1:size(symbols,2)
    x=j*w; y=i*h;
    rect = [x-.5*w+opts.interBoxGap,y-.5*h+opts.interBoxGap,w-2*opts.interBoxGap,h-2*opts.interBoxGap];
    hdlspanel(i,j,1) = ...
        uipanel('Parent', main, 'Position',[(j-1)/5, (i-1)/3, 0.2, 0.334], 'BackgroundColor',[0, 0, 0], 'BorderType', 'line',...
            'BorderWidth', 25, 'HighlightColor', [.5, .5, .5]);
    hdlstext(i,j,1) = ...
        uicontrol('Parent', hdlspanel(i,j,1), 'Style', 'text', ...
        'String', symbols{i,j}, 'Units', 'normalized', 'Position', [0.2, 0.1, 0.6, 0.6],...
        'FontSize', fontSize, 'HorizontalAlignment','center','FontWeight',...
        'bold','ForegroundColor',[.5 .5 .5]);
  end
end
drawnow;
return;
function testCase()
grid=initGrid({'1' '2';'3' '4'});
grid=initGrid({'alpha' 'beta';'gamma' 'delta'});
