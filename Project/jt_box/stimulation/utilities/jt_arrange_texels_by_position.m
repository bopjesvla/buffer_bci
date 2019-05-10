function [loc] = jt_arrange_texels_by_position(cfg)
%[locations] = jt_arrange_texels_equal(cfg)
%Distributes texels by position and size.
%
% INPUT
%   cfg = [struct]
%       .N         = [int] number of texels vertical (2)
%       .M         = [int] number of texels horizontal (1)
%       .viewport  = [1 4] viewport of texels ([0 0 1 1])
%       .texelsize = [1 2] texel's spacing (.33)
%       .texelpos  = [N*M 2] texel's position ([.33 0 ; .33 .66])
%
% OUTPUT
%   loc = [4 M*N] locations of all M*N texels

% Defaults
if nargin<1||isempty(cfg); cfg=[]; end
N = jt_parse_cfg(cfg,'N',2);
M = jt_parse_cfg(cfg,'M',1);
viewport = jt_parse_cfg(cfg,'viewport',[0 0 1 1]);
texelsize = jt_parse_cfg(cfg,'texelsize',.33);
texelpos = jt_parse_cfg(cfg,'texelpos',[.33 0 ; .33 .66]);

% Frame sizes
max_width  = viewport(3) - viewport(1);
max_height = viewport(4) - viewport(2);

% Destribute texels
loc = zeros(4,M*N);
for i = 1:N*M
    loc(1,i) = viewport(1) + max_width*(texelpos(i,1));
    loc(2,i) = viewport(2) + max_height*(texelpos(i,2));
    loc(3,i) = viewport(1) + max_width*(texelpos(i,1)+texelsize);
    loc(4,i) = viewport(2) + max_height*(texelpos(i,2)+texelsize);
end