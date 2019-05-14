function [R, d, s, rms] = challis(x, y, w);
%SODER least-squares fit of rigid body rotation & translation
%
% Syntax: [R, d, s, rms] = challis(x, y);
%
% the rigid body model is: y_i = s*[R]*x_i + d	(Challis eq 1)
%
% See: I. Soederqvist and P.A. Wedin (1993) Determining the movement of the
%	skeleton using well-configured markers. J. Biomech. 26, 1473-1477.
% J.H. Challis (1995) A prodecure for determining rigid body transformation
%   parameters, J. Biomech. 28, 733-737.
% The latter also includes possibilities for scaling, reflection, and
% weighting of marker data.
% For ohter methods see Horn et al (1988) Closed-form solution of absolute orientation using 
% orthonormal matrices 
%
% Input:x		N by 3  reference marker configuration
%					each row contains x y z coordinates for one marker
%					use NaN's for markers that are not observed
%		y		N by 3	transformed marker configuration (same format)
%		%hasn't been tested; weights between 0 and 1;
%       w       N by 1  weights-matrix
%Output:R		3 by 3	rotation matrix
%		d		3 by 1	translation vector
%		rms		1 by 1	root mean square fit error of rigid body model

% Version 1.0, 30 March 2009 by Brams.
%
% example: rotation over 90 deg around z-axis and translation by [1, 2, -1]
% X = [1, 1, 0; 1, -1, 0; -1, -1, 0; -1, 1, 0];
% Y = [X(2:4, :); X(1, :)] + [1*ones(4, 1), 2*ones(4, 1), -1*ones(4, 1)];
% [R, d, s, rms] = challis(X, Y + 0.1*randn(size(Y)),W)



% argument checking
[Nmar, Ndim] = size(x);

if nargin<3
    w=ones(Nmar,1); %building a weighting vector!
end
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

if nargout==3
    disp('use soder instead')
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

%make use of the weights; haven't tested them
wx=repop(w.^2,'*',x); 
wy=repop(w.^2,'*',y);
n=sum(w.^2);

% calculate mean
mx = sum(wx,1)./n; my = sum(wy,1)./n;			% Challis 6/30 & 7/31 (weighted) centers of mass

% subtract mean
X = repop(x, '-', mx);      % Challis 10
Y = repop(y, '-', my);		% Challis 11



sigmax=mean((sum(X.^2,2))); % compare Challis 26
sigmay=mean(sum(Y.^2,2)); 
% 
% 
% X1=s*X;
% x1=repop(X1,'+',mx);
% x2=R*x1';

s=(sqrt(sigmay/sigmax)); %*trace(R'*C); % own interpretation seems to work...
%s=1/sigmax*trace(R'*C); % Challis 27

%we can also add some weighting
C=Y'*X;

% core of algorithm, see Challis for explanation
[U, V, W] = svd(C);				% Challis 20
R = U*diag([1, 1, det(U*W')])*W';	% Challis 24



% translation vector from the centroid of all markers
d = my' - s*R*mx';					% Challis 28



% calculate RMS value of residuals, vectorized
sumsq = sum(sum((y' - s*R*x' - d(:, ones(1, Nmar)) ).^2));
rms = sqrt(sumsq/(3*Nmar));

% 
% figure; plot3(y(:,1),y(:,2),y(:,3),'.r')
% x1=(s*R*x'+d(:, ones(1, Nmar)))';
% hold on, plot3(x1(:,1),x1(:,2),x1(:,3),'.g')
% legend('y','xtransformed')

% %build a affine matrix, not finished yet
% % compute the rotation matrix
% rot = eye(4);
% rot(1:3,1:3) = R';
% rot=s*rot;
% % compute the translation matrix
% tra = eye(4);
% tra(1:4,4)   = [d(:); 1];
% % compute the full homogenous transformation matrix from these two
% h = rot * tra;

% % calculate RMS value of residuals, non-vectorized
% sumsq = 0;
% for i = 1:Nmar
%  	sumsq = sumsq + norm(y(i,:)' - R*x(i,:)' - d)^2;
% end
% rms = sqrt(sumsq/(3*Nmar));