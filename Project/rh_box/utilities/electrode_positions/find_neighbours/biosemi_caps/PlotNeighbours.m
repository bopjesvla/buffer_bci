function PlotNeighbours(CartesianCoordinates,labels,nbs,rotation);
X = CartesianCoordinates(:,1)';
Y = CartesianCoordinates(:,2)';
Z = CartesianCoordinates(:,3)';


% plot figure with neighbours connected with lines
% phi: spherical orientation, radial direction (moving from the top of the head downwards)
% theta: radial orientation, spherical direction (moving horizontally around the head)
theta = atan2(Y,X) - rotation;
phi=atan2(Z,sqrt(X.^2 + Y.^2));
% stretch phi in order to get a better view of all channels if watching 
% the head from top view  
% correction = booglengte over schedel tov Cz (=A1)
phicor=1-(2*(phi'))/pi;

% Convert stretched (better viewable) 2D electrode coordinates back to cartesian
[x,y] = pol2cart(theta,phicor');

% define colors of BioSemi cap A to H
clA=[ 80, 25, 0]/255; % brown
clB=[255, 0 , 0]/255; %red
clC=[255, 128 , 0]/255; %orange
clD=[255, 225 , 0]/255; %yellow
clE=[0, 200 , 0]/255; %green
clF=[0, 0 , 255]/255; %blue
clG=[200, 0 , 100]/255; %magenta/paars
clH=[150, 150 , 150]/255; %gray
CapColors = [clA; clB; clC; clD; clE; clF; clG; clH];
LightGray = [200, 200, 200]/255;

hold on;
rmax = 1;

base  = rmax-.0046;
basex = 0.18*rmax;                   % nose width
tip   = 1.15*rmax;
tiphw = .04*rmax;                    % nose tip half width
tipr  = .01*rmax;                    % nose tip rounding
q = .04; % ear lengthening
EarX  = [.497-.005  .510  .518  .5299 .5419  .54    .547   .532   .510   .489-.005]; % rmax = 0.5
EarY  = [q+.0555 q+.0775 q+.0783 q+.0746 q+.0555 -.0055 -.0932 -.1313 -.1384 -.1199];
sf=1.05;
% plot ears and nose
%plot([base;tip-tipr;tip;tip-tipr;base]*sf,[basex;tiphw;0;-tiphw;-basex]*sf) % plot nose
lh = plot([basex;tiphw;0;-tiphw;-basex]*sf,[base;tip-tipr;tip;tip-tipr;base]*sf); % plot nose
set (lh,'Color',LightGray);
lh = plot(EarX*2*sf,EarY*sf);    % plot left ear
set (lh,'Color',LightGray);
lh = plot(-EarX*2*sf,EarY*sf);   % plot right ear
set (lh,'Color',LightGray);

% plot lines for neighbours
for idx = 1 : length(nbs)
	lh = line([x(nbs(idx,1)),x(nbs(idx,2))],[y(nbs(idx,1)),y(nbs(idx,2))]);
	set(lh,'Color',LightGray,'LineWidth',0.5,'Marker','none'); %'MarkerEdgeColor','k','MarkerFaceColor','g'
end

numconnectors = floor(length(x)/32);
% Plot electrode positions
for connector = 1 :numconnectors,
	ph = polar(theta(:,(connector-1)*32+1:connector*32),phicor((connector-1)*32+1:connector*32,:)','o');
	cl = CapColors(connector,:);
	set(ph,'MarkerSize',4,'MarkerEdgeColor',cl,'MarkerFaceColor',cl);
end

% Plot labels next to electrodes
text(x,y,labels);

