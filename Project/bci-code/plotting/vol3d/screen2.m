function screen2(type,fileName,figureNums)
% SCREEN2   The bigger better replacement for screen2*.
%   Saves the current figure to a specified file of type TYPE with file 
%   name FILENAME. FILENAME can also contain path information. If path
%   information is missing the present working directory is used. 
%     Possible types: 
%       'all','fig','bmp','emf','eps','epsc','jpg','jpeg','png','tiff'
%     Other Possible Types: 
%       Anything accepted by print.m for output type.
%           Example: '-dill', *.ill Adobe Illustrator
%
%     If TYPE='all' screen2 is recursivly called with to produce all the
%       following specified file extensions: 
%           fig, bmp, emf, eps, jpg, png, tiff
%
%     If TYPE={'eps','jpg'} screen2 is recursivly called to produce all of
%       the specified file extensions.
%
%     If FILENAME is a cell array and the length of the strings matches the
%       number of open figures the figures are ordered by figure number and
%       screen2 is called recursively for each figure corresponding to the
%       ordered open figures. 
%    
% Syntax: screen2(type,fileName)
%
% Input:
%   type - File extension of standard file types.
%   fileName - The file name (optionally including a path).
%   figureNums - Optional - Used only to specify the figure numbers
%       which are desired to be saved if multiple figures are open but 
%       not all open figures are desired to be saved.
%       The small caveat here is that these numbers do not correspond to
%       the actual figure numbers but rather the index of the figure
%       numbers if they were sorted. For example, if the open figures had
%       numbers 1,2,99 and FIGURENUMS was specified as [1 3] figures 1 and
%       99 would be saved as specified by TYPE.
%
% Output:
%   File(s) are created.
%
% Examples:
%   close all
%   figure(1)
%   plot(0:1)
%   screen2('emf','myFileName1');
%   screen2('all','myFileName2');
%   screen2({'eps','epsc'},'myFileName3');
%   screen2('-dill','myFileName4');
% 
%   figure(2)
%   plot(1:-1:0)
%   
%   figure(99)
%   plot([0 0])
% 
%   screen2('jpg',{'multiSave1','multiSave2','multiSave3'});
%   screen2('jpg',{'selectiveMultiSave1','selectiveMultiSave2'},[1 3]);
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% See also: print, hgsave

% Author: Kenneth Morton
%   Totally inspired by code by: Pete Torrione 
%       Which was inspired by: Sean P. McCarthy
%       The original code was: Copyright (c) 1984-98 by The MathWorks, Inc.
% Duke University, Department of Electrical and Computer Engineering
% Email Address: collinslab@gmail.com
% Created: 4-Dec-2006

if iscell(fileName)
    % We have multiple figures to save
    openFigs = findobj(0,'type','figure');
    openFigs = sort(openFigs);
    if nargin < 3 % Figure numbers were not provided
        selectedFigs = openFigs;
        if length(fileName) ~= length(openFigs)
            error('Length of fileName must match the number of open figures if figureNumbers is not provided.')
        end
    else % Figure numbers were provided
        if length(fileName) ~= length(figureNums)
            error('Length of fileName must match the number of open figures if figureNumbers is not provided.')
        end        
        selectedFigs = openFigs(figureNums);
    end
        
    for iFig = 1:length(selectedFigs)
        figure(selectedFigs(iFig))
        screen2(type,fileName{iFig})
    end
    return
end

if nargin > 2 % A figure number was provided for a single figure
    figure(figureNums)
    screen2(type,fileName)
    return
end
    
if iscell(type)
    for iType = 1:length(type)
        screen2(type{iType},fileName);
    end
    return
elseif ~isempty(type) && ~strcmpi(type(1),'-')
    printTypes = {'fig';
                  '-dbmp';
                  '-dmeta';
                  '-deps';
                  '-depsc';
                  '-djpeg';
                  '-djpeg';
                  '-dpng';
                  '-dtiff';
                  '-dtiff'};
    
    inTypes = {'fig'; % This one is just a place holder
               'bmp';
               'emf';
               'eps';
               'epsc';
               'jpg';
               'jpeg';
               'png';
               'tiff';
               'tif'};

    switch lower(type)
        case 'all'
            screen2(unique(printTypes),fileName);
            return
        case 'fig'
            hgsave(gcf,fileName);
            return
    end
        
    matchNum = strmatch(lower(type),inTypes);
    if isempty(matchNum)
        typeStr = type; % Let PRINT give you the error.
    else
        typeStr = printTypes{matchNum};
    end
else
    typeStr = type;
end

% This the original bit of code
oldscreenunits = get(gcf,'Units');
oldpaperunits = get(gcf,'PaperUnits');
oldpaperpos = get(gcf,'PaperPosition');
set(gcf,'Units','pixels');
scrpos = get(gcf,'Position');
newpos = scrpos/100;
set(gcf,'PaperUnits','inches','PaperPosition',newpos)
print(typeStr,fileName,'-r100')
drawnow
set(gcf,'Units',oldscreenunits,'PaperUnits',oldpaperunits,...
    'PaperPosition',oldpaperpos);