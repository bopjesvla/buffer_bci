function [x2d,y2d] = xyz2xy2D(xyz)
% converts xyz coordinates to xy coordinates to be used for 2D plotting
%%% Electrode info
X = xyz(:,1);
Y = xyz(:,2);
Z = xyz(:,3);

% define polar cap coordinates and
% phi: spherical orientation, radial direction (moving from the top of the head downwards)
% theta: radial orientation, spherical direction (moving horizontally around the head)
theta = atan2(Y,X) - 270/180*pi;
phi   =	atan2(Z, sqrt(X.^2 + Y.^2));
% stretch phi in order to get a better view of all channels if watching
% the head from top view
% correction = booglengte over schedel tov Cz (=A1)
phi2D = 1-(2*(phi'))/pi;
% Convert stretched (better viewable) 2D electrode coordinates back to cartesian
[x2d,y2d] = pol2cart(theta,phi2D');

