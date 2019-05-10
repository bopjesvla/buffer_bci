function coordinates=readpositions(labeldata,posfile)
%reads coordinates from file
%supports to different measured electrode files
%use as coordinates=readpositions(labeldata,posfile)
%with labeldata={'_EX1','_EX2'}; ,posfile=elcfile (the place where the electrodefile is stored;
%

% EXAMPLE:
% labeldata={'A27', 'A9'};
% labeldata=myload('/Volumes/BCI data/00 Admin/Caps/labels.mat')';
% posfile='/Volumes/BCI Data/00 Admin/Caps/glaskoppf8-6-6/Glaskoppf placement.txt';
% coordinates=readpositions(labeldata,posfile)

% 10-08-2008 - brams
% implementation of new positionfiles

% Read coordinates from file
for(j=1:length(labeldata))
    filePositions=fopen(posfile,'r');
    label{j}=' ';
    line=' ';
    while(~strcmp(lower(label{j}),lower(labeldata(j))))
        line=fgetl(filePositions);
        if(line==-1)
            error('Position of label %s is not defined in %s please choose another positionfile or remove this electrode from list',labeldata{j},posfile);
        end
        label{j} = sscanf(line,'%s',1);
    end
    
    if(line~=-1)
        try
                if(strcmp(lower(labeldata(j)),'_ex1') || strcmp(lower(labeldata(j)),'_ex2'))
                    x(j)=sscanf(line,'%*s %*s %*s %f',1);
                    y(j)=sscanf(line,'%*s %*s %*s %*f %f',1);
                    z(j)=sscanf(line,'%*s %*s %*s %*f %*f %f',1);
                else
                    x(j)=sscanf(line,'%*s %f',1);
                    y(j)=sscanf(line,'%*s %*f %f',1);
                    z(j)=sscanf(line,'%*s %*f %*f %f',1);
                end
        catch
                x(j)=sscanf(line,'%*s %f',1);
                y(j)=sscanf(line,'%*s %*f %f',1);
                z(j)=sscanf(line,'%*s %*f %*f %f',1);
                disp('new grouping in positionfile')
        end
    end   
    fclose(filePositions);
end;
coordinates=[x' y' z'];