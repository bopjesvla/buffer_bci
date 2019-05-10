function c=readMRIRef(filename);
%Example:
%filename='D:\Bibliotheek\Stage\BCI data\00 Admin\Subjects\anat_MRI\desain\segmentation\mri\MRIreferences.txt';
%c=readMRIRef(filename)
%tree or four reference point as saved in a .txt document can be read and are returned in a structure
%c.el (ear-left) c.er (ear-right) c.ns (nasion) and if it exists c.fo (forehead)

%Update 10-10-2008 - Brams 
%added fourth reference point

reffile=fopen(filename,'r');
%read first 4 lines
line=fgetl(reffile);line=fgetl(reffile);line=fgetl(reffile);line=fgetl(reffile);
%read ear-left
line=fgetl(reffile);
el=sscanf(line,'%*s %f %f %f');
%read ear-right
line=fgetl(reffile);
er=sscanf(line,'%*s %f %f %f');
%read nasion
line=fgetl(reffile);
ns=sscanf(line,'%*s %f %f %f');
%read top of forehead-point (a point above the nasion)
c=[];
try
    line=fgetl(reffile);
    fo=sscanf(line,'%*s %f %f %f');
    c.fo=fo;
catch
    disp('no fourth reference')
end
fclose(reffile);
    

c.el=el;
c.er=er;
c.ns=ns;
