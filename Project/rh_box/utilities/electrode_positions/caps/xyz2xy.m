function xy=xyz2xy(xyz)
%if ( all(xyz(3,:)>=0) && all(xyz(3,:)<=2) && all(abs(xyz(1,:))<2) && all(abs(xyz(2,:))<2) ) % good co-ords
%  cz=0;
%else 
   cz= mean(xyz(3,:)); % center
%end
r = abs(max(abs(xyz(3,:)-cz))*1.1); if( r<eps ) r=1; end;  % radius
h = xyz(3,:)-cz;  % height
rr=sqrt(2*(r.^2-r*h)./(r.^2-h.^2)); % arc-length to radial length ratio
xy = [xyz(1,:).*rr; xyz(2,:).*rr];
return
