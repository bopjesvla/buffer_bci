function codes = test_code_transition(L,C)

% L: first dimension is length of codebook for each noisetag
% C: second dimension is number of noisetags
codes = zeros(L,C);
% code with all zeros, except at the end and start:
% end with ... 0 1 1 0
% start with   0 1 1 0 ... 
%                                      :  
% The transition wil make: ... 0 1 1 0 : 0 1 1 0 ....
%                                      :

for c = 1 : C;
%    codes(1:4,c)=[0 1 1 0];
%    codes(end-3:end,c)=[0 1 1 0];
    codes(1:4,c)=[1 0 1 0];
    codes(end-5:end,c)=[1 1 0 1 1 0];
end