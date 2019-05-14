function B = bitrate(V,N,P)
% B = BITRATE(V,N,P)   Calculate the bitrate
%
% Calculates the bitrate acording to the Wolpaw definition. More
% information about the bitrate and its background can be found in:
%
% Kronegg, J., Alecu, T., & Pun, T. (2003). Information theoretic bit-rate
% optimization for average trial protocol Brain Computer Interfaces. In HCI
% International.
%
% Output: B - The bit rate in bits per second(!).
%
% Inputs:   V - Number of classifications per second.
%           N - Number of classes.
%           P - Mean accuracy.


if(P == 1)
    R = log2(N) + P * log2(P);
else
    R = log2(N) + P * log2(P) + (1-P) * log2((1-P)/(N-1));
end

B = V * R;