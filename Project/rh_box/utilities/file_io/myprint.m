function myprint(figuredir,name,enlarge,type)

h = gcf;
if nargin<3
    enlarge='on';
end
if nargin<4
    type='-djpeg90';

else
    type=['''-d',type,''''];
end

if strcmp(enlarge,'on')
    set(h,'Unit','Normalized')
    set(h, 'Position',[0 0 1 1],'PaperPositionMode', 'auto');
end
prname=[figuredir,name];
if exist(figuredir)==0
    mkdir(figuredir)
end
disp(['saving figure ',prname])
eval(['print -f',num2str(h),' ',type, ' ''',prname,'''']);
