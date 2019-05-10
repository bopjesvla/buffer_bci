function result = sizestr(data)
s = size(data);
bytes = 8;
for i=1:size(s,2)
    bytes = bytes * s(i);
end
divider = 1;
order = '';
if bytes>1000
    divider = 1000;
    order = 'K';
end
if bytes>1000000;
    divider = 1000000;
    order = 'M';
end
result = [num2str(round(bytes/divider)) order 'b'];
