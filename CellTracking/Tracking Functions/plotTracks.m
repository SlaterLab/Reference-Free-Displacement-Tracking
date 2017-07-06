function plotTracks(lub,maxMasks)
disp('Plotting Linked Paths.')
figure
imshow(maxMasks)
hold on
clear tempInd1 tempInd2
for j = 1:max(lub(:,7))
    clear tempPillar
    tempInd1 = find(lub(:,7)==j,1,'first');
    tempInd2 = find(lub(:,7)==j,1,'last');
    if((tempInd2-tempInd1)>0)
    tempPillar = lub(tempInd1:tempInd2,:);
    plot3(tempPillar(:,1),tempPillar(:,2),tempPillar(:,6))
    end
end
hold off
end