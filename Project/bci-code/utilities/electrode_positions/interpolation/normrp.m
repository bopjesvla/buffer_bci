function NE = normrp(E,p);
%normalise the row to 1 in the one norm

for j = 1:size(E,1)
    NE(j,:) = E(j,:)./(norm(E(j,:),p));
end