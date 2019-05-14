function plotcap(coordinates)
%plotcap function also uses neighbours to plot a measured cap
%use as plotcap(coordinates)
%standard it uses the 256 electrode neighbours file!
%part of beamforming project

neighbours          =   myload('/Volumes/BCI_Data/equipment_data/cap_layout/biosemi/neighbours/neighbors256.mat');
hold;
for(j=1:length(neighbours))
   p1=coordinates(neighbours(j,1),:);
   p2=coordinates(neighbours(j,2),:);
   if~((p1==[0 0 0]) | (p2==[0 0 0]))
    p=[p1;p2];
    plot3(p(:,1),p(:,2),p(:,3),'red');
   end
end
markers={'x','o','^','.','v','+','*','<'};
for i=1:8
    range=i*32-31; 
    v=range:range+31;
    plot3(coordinates(v,1),coordinates(v,2),coordinates(v,3),markers{i});
end