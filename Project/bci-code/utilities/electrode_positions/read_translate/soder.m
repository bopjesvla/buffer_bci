function [R, d, rms] = soder(x, y);
%SODER least-squares fit of rigid body rotation & translation
%
% Syntax: [R, d, rms] = soder(x, y);
%
% the rigid body model is: y_i = R*x_i + d	(Challis eq 1)
%
% See: I. Soederqvist and P.A. Wedin (1993) Determining the movement of the
%	skeleton using well-configured markers. J. Biomech. 26, 1473-1477.
% J.H. Challis (1995) A prodecure for determining rigid body transformation
%   parameters, J. Biomech. 28, 733-737.
% The latter also includes possibilities for scaling, reflection, and
% weighting of marker data.
%
% Input:x		N by 3  reference marker configuration
%					each row contains x y z coordinates for one marker
%					use NaN's for markers that are not observed
%		y		N by 3	transformed marker configuration (same format)
%Output:R		3 by 3	rotation matrix
%		d		3 by 1	translation vector
%		rms		1 by 1	root mean square fit error of rigid body model

% Version 1.0, 7 September 2004 by Tjeerd Dijkstra.
% Tested with MATLAB 6.5.1 on a PowerMac B&W (G3@400 MHz) under OS X 10.3.4
% Original by Ron Jacobs (R.S. Dow Neurological Institute, Porland OR),
% adapted by Ton van den Bogert (University of Calgary).
%
% example: rotation over 90 deg around z-axis and translation by [1, 2, -1]
% X = [1, 1, 0; 1, -1, 0; -1, -1, 0; -1, 1, 0];
% Y = [X(2:4, :); X(1, :)] + [1*ones(4, 1), 2*ones(4, 1), -1*ones(4, 1)];
% [R, d, rms] = soder(X, Y + 0.1*randn(size(Y)))

% argument checking
[Nmar, Ndim] = size(x);
if Ndim ~= 3,
	error(sprintf('N columns of x is not 3 but %d', Ndim));
end
[Nmary, Ndim] = size(y);
if Ndim ~= 3,
	error(sprintf('N columns of y is not 3 but %d', Ndim));
end
if Nmar ~= Nmary,
	error(sprintf('N markers of x=%d does not equal N markers of y=%d', ...
					Nmar, Nmary));
end
if Nmar < 3,
	error(sprintf('N markers is %d, should be 3 or more', Nmar));
end

% get rid of NaN's (unobserved markers)
xy_nan = sum(isnan(x) + isnan(y), 2);
x = x(~xy_nan, :);
y = y(~xy_nan, :);

% check again if number of markers > 3
[Nmar, Ndim] = size(x);
if Nmar < 3,
%	warning(sprintf('N markers after removing NaNs is %d, should be 3 or more', Nmar));
	R = NaN*ones(3, 3); d = NaN*ones(3, 1); rms = NaN; return;
end

% calculate mean
mx = mean(x); my = mean(y);			% Challis 6 & 7

% subtract mean
X = x - mx(ones(Nmar, 1), :);		% Challis 10
Y = y - my(ones(Nmar, 1), :);		% Challis 11

% core of algorithm, see Challis for explanation
[U, V, W] = svd(Y'*X);				% Challis 20
R = U*diag([1, 1, det(U*W')])*W';	% Challis 24

% translation vector from the centroid of all markers
d = my' - R*mx';					% Challis 4

% calculate RMS value of residuals, vectorized
sumsq = sum(sum((y' - R*x' - d(:, ones(1, Nmar)) ).^2));
rms = sqrt(sumsq/(3*Nmar));

% % calculate RMS value of residuals, non-vectorized
% sumsq = 0;
% for i = 1:Nmar
%  	sumsq = sumsq + norm(y(i,:)' - R*x(i,:)' - d)^2;
% end
% rms = sqrt(sumsq/(3*Nmar));