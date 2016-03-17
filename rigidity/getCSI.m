function [CSI,colShifts,maxShift,shiftedBscan] = getCSI(bscan, yTop)

%-% Flattening of Image According to BM
meanTop   = round(mean(yTop));
colShifts = meanTop - yTop;
maxShift  = double(max(abs(colShifts)));

shiftedBscan = BMImageShift(bscan,colShifts,maxShift,'Pad');

%-% Edge Probability
scalesize = [10 15 20];
angles    = [-20 0 20];
[~,OG] = EdgeProbability(shiftedBscan,scalesize,angles,meanTop,maxShift);

%-% Inflection Points
Infl2 = zeros(size(shiftedBscan));

shiftedBscan = shiftedBscan / max(shiftedBscan(:)) * 255;

filteredBscan = imfilter(shiftedBscan,OrientedGaussian([3 3],0));
colspacing    = 2;

nCols = size(filteredBscan,2);

testGrad = [];
testGrad2 = [];

for j = 1:nCols
    
    filteredAscan = smooth(double(filteredBscan(:,j)),10);
    
    grad  = gradient(filteredAscan);
    grad2 = del2(    filteredAscan);
    
    testGrad = [testGrad grad];
    testGrad2 = [testGrad2 grad2];
    
    %                     z     = (grad2 < 1E-16) & (grad > 0.7);
    z     = (abs(grad2) < 1E-2) & (grad > 0.7); %[JM]
    z(1:meanTop + maxShift + 15) = 0;
    
    Infl2(z,j) = 1;
end

%                 % START **** ALTERNATIVE INFLEXION POINT SEARCH ****
%                 smoothedBscan = filter2(fspecial('disk',5),filteredBscan,'same');
%                 [gradX,gradY]  = gradient(smoothedBscan);
%                 gradM   = sqrt(gradX.^2 + gradY.^2);
%                 gradAng = atan2(gradY,gradX);
%
%                 laplac = del2(smoothedBscan);
%                 %       #zero of laplac#  &  #big slope#  &         #downward Yslope#
%                 z  = (abs(laplac) < 5E-2) & (gradM > 0.7) & (sin(gradAng) > sin(pi/4));
%                 z(1:meanBM + maxShift + 15,:) = 0;
%                 Infl2 = z;
%                 % END **** ALTERNATIVE INFLEXION POINT SEARCH ****

Infl2 = bwmorph(Infl2,'clean');
Infl2 = imfill(Infl2,'holes');
Infl2 = bwmorph(Infl2,'skel','inf');

Infl2(:,setdiff((1:nCols),(1:colspacing:nCols))) = 0;

Infl2 = bwmorph(Infl2,'shrink','inf');
g     = imextendedmin(filteredBscan,10);

% Not sure about this. Check how it works with one example
Infl2(Infl2 & g) = 0;

nodes = Infl2;

%-% Find CSI
[CSI, ~] = mapFindCSI(nodes,OG,maxShift,colShifts);

end