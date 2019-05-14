function labels = readLabels(labelfile)
%reads a standard labelfile
%use as readLabels(labelfile)

setNames={};
setNumber=0;
labelNames={};
labelNumber=1;

file=fopen(labelfile,'r');
read=' ';
while(read~=-1)  
    read=fgetl(file); 
    if(read~=-1)
        firstchar=substring(read,0,0);
        if strcmp(firstchar,'%')
            setNumber=setNumber+1;
            setNames{setNumber}=substring(read,1);
            labelNumber=1;            
        else        
            labelNames{setNumber}(labelNumber)={read};
            labelNumber=labelNumber+1;
        end
    end
end
fclose(file);

labels.groups=setNames;
labels.labels=labelNames;




