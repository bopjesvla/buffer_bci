function codes = test_code_frequency(L,C)

% L: first dimension is length of codebook for each noisetag
% C: second dimension is number of noisetags
codes = ones(L,C);
for c = 1 : C;
    s = mod(c-1,4)+1;
    s=1;
    codes(s:4:end,c)=0;
    codes(s+1:4:end,c)=0;
end