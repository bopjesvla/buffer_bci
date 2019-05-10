%function res = NeighbourList(CartesianCoordinates, slicedis, numnbsfromring)
% This function returns all neighbour electrodes of all electrodes
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

function [nbsvector,nbsmatrix] = NeighbourList(CartesianCoordinates, slicedis, numnbsfromring)

allnbs = [];
for ch = 1 : length(CartesianCoordinates(:,1)),
	disp(['Find neighbour of electrode index number ' num2str(ch) ]);
	nbs = FindNeighbours(ch,CartesianCoordinates,slicedis,numnbsfromring);
	numnbs = length(nbs);
	pairs =  [nbs ch.*ones(numnbs,1)];
	allnbs = [allnbs; pairs];
end

% allnbs still has duplicates, i.e., pairs n - m and m - n are equal!
% Remove them by first composing a pair matrix, and then generate a unique
% neighbour list from this matrix.
% put electrode neighbours in pair-matrix.
numelectrodes = length(CartesianCoordinates(:,1));
nbsmatrix = zeros(numelectrodes);
for idx = 1 : length(allnbs(:,1)),
	el1 = allnbs(idx,1);
	el2 = allnbs(idx,2);
	nbsmatrix(el1,el2) = 1;
	nbsmatrix(el2,el1) = 1;
end

% generate new unique neighbour matrix without duplicates!
[i,j,v]=find(nbsmatrix ~= 0);
nbsvector = [i j];

