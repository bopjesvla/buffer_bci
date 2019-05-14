%function res = FindNeighbours(refel,CartesianCoordinates,slicedis,numnbsfromring)
% This function returns all neighbour electrodes of one specified reference electrode 
% refel: 
%		reference electrode's index number. Corresponding coordinates can 
%		be found using this number as index into <CartesianCoordinates> 
% CartesianCoordinates: (electrodes x coordinates)
%		Matrix holding the electrode's headcap positions. Only use theoretical 
%		composed positions: all electrodes on a radius 1 sphere, and Cz exact on top.	
%		The coordinates are translated to polar coordinates using theta and phi.
%		Angle phi defines on which slice level you are on the head. Think of the
%		head being divided in slices from the top of the head (Cz) in downward
%		direction.
% slicedis: 
%		distance between the spherical oriented electrodes measured in	radians
%		Example: BioSemi 256 electrodes cap has <slicedis> = 0.1606 rad; This angle
%		depends on the number of defined slices or rings around the head.
% numnbsfromring:
%		defines the maximum number of neighbours that will be searched for in
%		the surrounding slices. Tested values are 1, 2 or 3. 
%
% Algorithm apllied to find neighbours:
% Steps to find neighbours are as follows:
% 1) find neighbours from the two slices surrounding the reference
% electrode and from the slice of the reference electrode itself
% 2) Find from the surrounding slices and ref. slice the <numnbsfromring>
% respectively 2 (always take the two electrodes direct near the reference
% one as neighbours) closest to the reference.
% 3) Check for outliers based on both a distance and angle criterion
% There is one exception in the rules used below to find the neighbours.
% For Cz (exact on top of the head), the next first electrode ring are all
% neighbours of Cz

function res = FindNeighbours(refel,CartesianCoordinates,slicedis,numnbsfromring)
X = CartesianCoordinates(:,1)';
Y = CartesianCoordinates(:,2)';
Z = CartesianCoordinates(:,3)';

% phi: spherical orientation, radial direction (moving from the top of the head downwards)
% theta: radial orientation, spherical direction (moving horizontally around the head)
theta = atan2(Y,X);
phi=atan2(Z,sqrt(X.^2 + Y.^2));

% angle phi of the reference electrode.
refphi=phi(refel);
% which slice level?
slicelevel = 1+round((1.5708-phi(refel))/slicedis);
% total range of phi (top of head to neck level) is about 120 degrees (approx. 2.1 rad)
maxring = 1+round(2.1/slicedis);

% estimate how many electrodes there are in each slice level (from Cz until ear
% level). Below ear level, number of electrodes are set equal to the ear level value.
numinring = zeros(1,maxring);
rnr = 1; % start at ring number 1
for refph = pi/2 : -slicedis : 0  % Cz (pi/2 rad); ear level (approx. 0 rad)
	num = length(find((phi-refph) < 0.5*slicedis & (phi-refph) > -0.5*slicedis));
	numinring(1,rnr) = num;
	rnr = rnr + 1;
end
% Set number of last rings (below ear level) equal to the number of electrodes at ear level
numinring(1,rnr:maxring) = num;

% possible neighbours from the inner ring
nbsi = find((phi-refphi) > 0.5*slicedis & (phi-refphi) < 1.5*slicedis);
% ring itself, neighbour in line
nbsl = find((phi-refphi) < 0.5*slicedis & (phi-refphi) > -0.5*slicedis);
% remove reference electrode itself
nbsl(find(nbsl == refel)) = [];
% possible neighbours from the outer ring
nbso = find((phi-refphi) < -0.5*slicedis & (phi-refphi) > -1.5*slicedis);

% The first ring is equal to Cz and therefore all outer neighbours are true
% neighbours
if slicelevel == 1
	res = nbso';
	return;
end

% use relative Eucledian distance and absolute theta angle difference criterion
% to remove false neighbours.
% The ratio between the distance of two adjacent slices and the electrode
% distance on these slices changes going from top head downwards. To correct
% for this effect, the maximum allowed relative distance of the neighbours
% to the reference electrode increases going from top head downwards. The
% relative distance is taken by normalization with the mean distance of the
% surrounding electrodes
maxreldis = 1.1 + 0.2*slicelevel/maxring;
% With increasing phi, the number of electrodes per slicelevel increases,
% though, the range of theta remains 2*pi rad. To account for this effect,
% the maximum allowed theta angle difference between neigbours and the
% reference electrode decreases from top to neck level.
maxabsangle = 1.5 * 2*pi/numinring(slicelevel);

% Get neighbours from innner ring using distance criterion
% use real coordinates and not the stretched ones used for surface plotting!
if ~isempty(nbsi)
	dis = sqrt( (X(nbsi)-X(refel)).^2 + (Y(nbsi)-Y(refel)).^2 + (Z(nbsi)-Z(refel)).^2);
	numnbs = length(nbsi);
	dissorted = sortrows([dis; nbsi]');
	realnbs=dissorted(1:min(numnbsfromring,numnbs),:);
	% simple check for false neighbours by checking on relative distance of all
	% neighbours compared to the smallest one
	reldis = realnbs(:,1)/mean(realnbs(:,1));
	realnbs(find(reldis > maxreldis),:) = [];
	innernbs = realnbs;
else
	innernbs = [];
end
% Get neighbours from own ring using distance criterion
% use real coordinates and not the stretched ones!
if ~isempty(nbsl)
	dis = sqrt( (X(nbsl)-X(refel)).^2 + (Y(nbsl)-Y(refel)).^2 + (Z(nbsl)-Z(refel)).^2);
	numnbs = length(nbsl);
	dissorted = sortrows([dis; nbsl]');
	realnbs=dissorted(1:min(2,numnbs),:);
	% simple check for false neighbours by checking on relative distance of all
	% neighbours compared to the smallest one
	reldis = realnbs(:,1)/mean(realnbs(:,1));
	realnbs(find(reldis > maxreldis),:) = [];
	% find large theta differences indicating false neighbours
	falseones = find(abs(mod(theta(realnbs(:,2))-theta(refel),pi)) > maxabsangle);
	realnbs(falseones,:) = [];
	linenbs = realnbs;
else
	linenbs = [];
end
% Get neighbours from outer ring using distance criterion
% use real coordinates and not the stretched ones!
if ~isempty(nbso)
	dis = sqrt( (X(nbso)-X(refel)).^2 + (Y(nbso)-Y(refel)).^2 + (Z(nbso)-Z(refel)).^2);
	numnbs = length(nbso);
	dissorted = sortrows([dis; nbso]');
	realnbs=dissorted(1:min(numnbsfromring,numnbs),:);
	% simple check for false neighbours by checking on relative distance of all
	% neighbours compared to the smallest one
	reldis = realnbs(:,1)/mean(realnbs(:,1));
	realnbs(find(reldis > maxreldis),:) = [];
	% find large theta differences indicating false neighbours
	falseones = find(abs(mod(theta(realnbs(:,2))-theta(refel),pi)) > maxabsangle);
	realnbs(falseones,:) = [];
	outernbs = realnbs;
else
	outernbs = [];
end

% combine the neighbours of the three (inner, inline, outer) slice levels
realnbs = sortrows([linenbs; innernbs; outernbs]);

res = realnbs(:,2);
