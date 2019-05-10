function [cap] = cap2xyz(cap_in);
% converts the biosemi coordinates to carthesian coordianates
% cap_in can be a arrayed structure or a cell array which was returened
% from readCap

%make it a cell array so we don't need to loop:
if(~iscell(cap_in))
    cap_cell = struct2cell(cap_in)';
else
    cap_cell = cap_in;
end

%get lat and azi
lat = [cap_cell{:,2}];
azi = [cap_cell{:,3}];

%go to carthesian
x = sin(lat).*sin(azi);
y = - sin(lat).*cos(azi);
z = cos(lat);

%fill the cell array
cap_cell(:,4) = num2cell(x)';
cap_cell(:,5) = num2cell(y);
cap_cell(:,6) = num2cell(z);

%possible convert to struct
if(~iscell(cap_in))
    cap = cell2struct(cap_cell,{'label','latitude','azimuth','x','y','z'},2);
else
    cap = cap_cell;
end




