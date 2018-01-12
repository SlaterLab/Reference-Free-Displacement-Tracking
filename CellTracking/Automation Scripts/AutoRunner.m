%% Automated Script
clear all
close all
[ListName,ListPath] = uigetfile;
fullListName = strcat(ListPath,ListName);
load(strcat(ListPath,ListName),'dirList')
parts = strsplit(ListName, 'List');
prefix = parts{1};
set(0,'defaultfigurecolor',[1 1 1])
%% For clearing old files
for j = 1:2
    for i = 1:size(dirList,1)
        cleanOld(dirList{i,1})
        disp(num2str(i))
    end
end

%% For Running XY Script
for i = 1:size(dirList,1)
    try
    dispShear(dirList{i,1})
    disp(num2str(i))
    catch
        disp('Shear Failed')
        i
    end
end

%% For Running Z Script
for i = 1:size(dirList,1)
    cd(dirList{i,1})
    %First check to see if the stack to analyze has been stored previously
    clear files
    files = dir('*.mat');
    if size(files,1)>=1
        for k = 1:length(files)
            current=files(k).name;
            if size(current,2)>12
                check(k)=strcmp(current(end-12:end),'StackName.mat');
            else
                check(k) = 0;
            end
        end
    end
    
    %If the Stack has not been assigned previously, manually assign it
    if size(find(check),2)==0
        [StackName,StackPath] = uigetfile('*.tif');
        save('StackName.mat','StackName')
    else
        load('StackName.mat','StackName')
        if StackName == 0
            [StackName,StackPath] = uigetfile('*.tif');
            save('StackName.mat','StackName')
        end
    end
    
end
%% Make sure every folder has a rowV file
[rowVName,rowVPath] = uigetfile;
load(strcat(rowVPath,rowVName),'rowV')
for i = 1:size(dirList,1)
    cd(dirList{i,1})
    save('rowV.mat','rowV')
end

%% For Running Z Script
for i = 1:size(dirList,1)
    try
    disp(dirList{i,1})
    disp3D(dirList{i,1})
    disp(dirList{i,1})
    i
       catch
       disp('Normal Failed')
       i
    end
end

%% For Running Z Script Outputs Only (faster alternative)
for i = 1:size(dirList,1)
    disp3DOutputs(dirList{i,1})
    i
end


%%
for i = 1:size(dirList,1)
    disp(dirList{i,1})
    cd(dirList{i,1});
    load('3Ddata.mat')
    filePath = cd;
    folderName = 'Profile Data';
    mkdir(filePath,folderName)
    save('Profile Data\vqZ.mat','vqN','vq3','image','HeatMapN','HeatMap3')
end

%% Collect vqXY/vqZ totals for shear v normal graphs
%goodData = [1;2;3;5;6;14;17;23;31;34;43;44;47;49;50;48;11;12;19;25;28;36];
%goodData = [1:1:51]';

goodData = [1:1:7]';
clear vqT
for i2 = 1:size(goodData,1)
    clear planesLoc3
    disp(dirList{goodData(i2,1),1})
    cd(dirList{goodData(i2,1),1});
    load('3Ddata.mat')
    load('Profile Data\vqXY.mat');
    load('Profile Data\HeatMapXY.mat');
    zTarget = 7;
    for j = 1:size(planesGroups,1)
        planesLoc3(j) = mean(planesLoc2(1,planesGroups(j,1:nnz(planesGroups(j,:)))));
    end
    zPlane = find(abs(planesLoc3-zTarget) == min(abs(planesLoc3-zTarget)),1,'first');
    vqXY(isnan(vqXY)) = 0;
    vqXY = imresize(vqXY,[size(vq3,1) size(vq3,2)]);
    i2
    vqT(i2,1) = sum(sum(vqXY));
    vq3(isnan(vq3)) = 0;
    vqT(i2,2) = sum(sum(abs(vq3(:,:,zPlane))));
    vqT(i2,3) = zPlane;
    vqT(i2,4) = planesLoc2(zPlane);
    vqT(i2,5) = sum(sum(image.Area ==0))*raw.dataKey(9,1)^2;
    vqT(i2,6) = max(max(vqXY));
    vqT(i2,7) = max(max(abs(vq3(:,:,zPlane))));
end
save([ListPath 'ShearNormalStats.mat'],'vqT')
figure
scatter(vqT(:,1),vqT(:,2))
figure
scatter(vqT(:,5),vqT(:,1))
figure
scatter(vqT(:,5),vqT(:,2))
figure
scatter(vqT(:,6),vqT(:,7))
%% Imbalance Calculator
clear ftotals
for i = 1:size(dirList,1)
    clear totals
    totals = imbalance(dirList{i});
    ftotals(i,:) = totals;
    i
end
%%

Ys(2,:) = ftotals(:,2)+ftotals(:,4);
Ys(3,:) = ftotals(:,1)+ftotals(:,3);
BarGrapher(Ys)

%% For Running Profile Script
clear caught goodData
goodData = [1;2;3;5;6;14;17;23;31;34;43;44;47;49;50;48;11;12;19;25;28;36];
for i = 1:size(goodData,1)
    try
        [normXY,normZ,normAxis,cell_boundary] = profFunc(dirList{goodData(i,1),1});
        profBook(1,1:size(normAxis,2),i) = normAxis;
        profBook(2,1:size(normXY,2),i) = normXY;
        profBook(3,1:size(normZ,2),i) = normZ;
        cb(i) = cell_boundary;
        save('Profile Data\ProfileOutputData.mat','normXY','normZ','normAxis')
    catch
        caught(i) = 1;
        i
        dirList{goodData(i,:),1}
    end
end
cbf = mean(cb);
save(strcat(ListPath,prefix,'Profiles.mat'),'profBook','cb','cbf')

%%

cb(cb<25 | cb>75)=NaN;
cbf2 = mean(cb,'omitnan')/100;
aScale = 1/cbf2;
clear profBookCat
profBookCat = profBook;
clear keep keep2 keep3 map profBook2 profBook3
for i = 1:size(profBookCat,3)
    %max(profBookCat(2,:,i))
    if max(profBookCat(2,:,i))>1
        keep(1,i) = 1;
        keep(2,i) = max(profBookCat(2,:,i));
        profBook2(1:size(profBookCat(:,:,i),1),1:size(profBookCat(:,:,i),2),i) = profBookCat(:,:,i);
    end
end
profBook2(:,:,~keep(1,:)) = [];
keep2 = keep(2,:);
keep2(:,~keep(1,:)) = [];
[keep3,sortIdx] = sort(keep2);

colOptions{1,1} = 'white';
colOptions{2,1} = 'black';
colOptions{1,2} = 'black';
colOptions{2,2} = 'white';
map = brewermap(size(profBook2,3),'*spectral');

for i = 1:size(colOptions,2)
    fcolor = colOptions{1,i};
    bcolor = colOptions{2,i};
    
    set(0,'defaultfigurecolor',bcolor)
    ProfileOverlays = figure;
    hold on
    for i = 1:size(profBook2,3)
        plot(profBook2(1,:,sortIdx(i))*aScale,profBook2(2,:,sortIdx(i)),'color',[map(i,1:3)])
        plot(profBook2(1,:,sortIdx(i))*aScale,profBook2(3,:,sortIdx(i)),'color',[map(i,1:3)],'linestyle','-.')
    end
    p1= plot(profBook2(1,:,sortIdx(i))*aScale,mean(profBook2(2,:,sortIdx(:)),3,'omitnan'),'color',fcolor,'linewidth',3);
    p2=plot(profBook2(1,:,sortIdx(i))*aScale,mean(profBook2(3,:,sortIdx(:)),3,'omitnan'),'color',fcolor,'linestyle','-.','linewidth',3);
    p3=plot([cbf2 cbf2]*aScale,[min(min(min(profBook2))),max(max(max(profBook2)))],'color',[.5 .5 .5],'linestyle','--','linewidth',1);
    set(gca,'Color',bcolor)
    text(1.05,-.8,'\leftarrowAvg. Cell Boundary','fontsize',16,'color',fcolor)
    
    set(gca,'fontsize',28,'XColor',fcolor,'YColor',fcolor,'YMinorTick','on')
    xt = 'Location on Trace(AU)';% input('enter the xaxis label','s');
    yt = 'Displacement (\mum)'; %input('enter the yaxis label','s');
    tt = 'Line-Profile Displacements';%input('enter the title','s');
    le = 'Shear'; %input('enter the legend','s');
    le2 = 'Normal';
    le3 = 'Border';
    xl = xlabel(xt);
    yl = ylabel(yt);
    %tl = title(tt);
    ytickformat('%.1f')
    set(xl, 'fontweight','bold','fontsize',28,'color',fcolor);
    set(yl,'fontweight','bold','fontsize',28,'color',fcolor);
    leg = legend([p1 p2],['\color{' fcolor '}' le],['\color{' fcolor '}' le2],'location','northwest');
    leg.FontSize = 20;
    legend boxoff
    %set(tl,'fontweight','bold','fontsize',title_font_size)
    axis([0 2 min(min(min(profBook2))) max(max(max(profBook2)))])
    
    
    title = strcat(prefix,['All_Data ' fcolor ' on ' bcolor]);
    savefile = [ListPath title];
    export_fig(ProfileOverlays,savefile,'-native');
    
    
    % Normalized Graph
    profBook3 = profBook2;
    for i = 1:size(profBook2,3)
        top(i) = abs(max(max(max(profBook2(2:3,:,i)))));
        profBook3(2:3,:,i) = profBook3(2:3,:,i)/top(i);
    end
    ProfileOverlaysNorm = figure;
    hold on
    for i = 1:size(profBook3,3)
        plot(profBook3(1,:,sortIdx(i))*aScale,profBook3(2,:,sortIdx(i)),'color',[map(i,1:3)])
        plot(profBook3(1,:,sortIdx(i))*aScale,profBook3(3,:,sortIdx(i)),'color',[map(i,1:3)],'linestyle','-.')
    end
    p1 = plot(profBook3(1,:,sortIdx(i))*aScale,mean(profBook3(2,:,sortIdx(:)),3,'omitnan'),'color',fcolor,'linewidth',3);
    p2 = plot(profBook3(1,:,sortIdx(i))*aScale,mean(profBook3(3,:,sortIdx(:)),3,'omitnan'),'color',fcolor,'linestyle','-.','linewidth',3);
    p3 = plot([cbf2 cbf2]*aScale,[min(min(min(profBook3))),1],'color',[.5 .5 .5],'linestyle','--','linewidth',1);
    set(gca,'Color',bcolor)
    text(1.05,-.3,'\leftarrowAvg. Cell Boundary','fontsize',16,'color',fcolor)
    
    set(gca,'fontsize',28,'XColor',fcolor,'YColor',fcolor,'YMinorTick','on')
    xt = 'Location on Trace(AU)';% input('enter the xaxis label','s');
    yt = 'Displacement (AU)'; %input('enter the yaxis label','s');
    tt = 'Line-Profile Displacements';%input('enter the title','s');
    le = 'Shear'; %input('enter the legend','s');
    le2 = 'Normal';
    le3 = 'Border';
    xl = xlabel(xt);
    yl = ylabel(yt);
    %tl = title(tt);
    set(xl, 'fontweight','bold','fontsize',28,'color',fcolor);
    set(yl,'fontweight','bold','fontsize',28,'color',fcolor);
    ytickformat('%.2f')
    leg = legend([p1 p2],['\color{' fcolor '}' le],['\color{' fcolor '}' le2],'location','northwest');
    leg.FontSize = 20;
    legend boxoff
    axis([0 2 min(min(min(profBook3))) max(max(max(profBook3)))])
     ytickformat('%.1f')
    %set(tl,'fontweight','bold','fontsize',title_font_size)
    
    
    title = strcat(prefix,['All_Data_Normalized ' fcolor ' on ' bcolor]);
    savefile = [ListPath title];
    export_fig(ProfileOverlaysNorm,savefile,'-native');
end
%%
for i = 1:size(dirList,1)
   cd(dirList{i})
   load('SphereIndent.mat')
   figure
   % Heatmap for XZ
colorMapRad = colormap(jet(77000));
colorMapRad(65537:end,:) = [];
colorMapRad = flipud(colorMapRad);
MaximumHeatMap = imagesc(radXX(:,1),radYY(:,1),radvq);
radHeat = MaximumHeatMap.CData;%.*(imageBinary==0);

radHeatNaN = (isnan(radHeat));
radHeat(isnan(radHeat)) = 0;
heatScale = (65536/2.4); %(max(max(imageHeat)))
radHeat = uint16(round(radHeat * heatScale));
radHeatColor = ind2rgb(radHeat,colorMapRad);


scale = (max(max(radYY))-min(min(radYY)))/51;
addTop = round(min(min(radYY)) / scale);
addbottom = round((22 - max(max(radYY)))/ scale);
total = zeros(addTop+addbottom+51,500,3);
total(addTop:addTop+50,:,:) = radHeatColor(:,:,:);

radHeatColor2 = imresize(total, [100 500]);

radHeatColor3(:,:,:,i) =  radHeatColor2;
 close
% figure
% imshow(radHeatColor)
% hold on
% text(200,25,[num2str(max(max(radYY))) ' ' num2str(min(min(radYY)))])

figure
imshow(radHeatColor2)
hold on
text(200,25,[num2str(max(max(radYY))) ' ' num2str(min(min(radYY)))])
   
   
end
radHeatColor3(radHeatColor3(:,:,1:3,:)==0) = NaN;
rHC3Mean = mean(radHeatColor3(:,:,:,:),4,'omitnan');
mInd = figure;
imshow(rHC3Mean)
hold on
for i = 1:4
    plot([-1 525],[(500/22)*(i) (500/22)*(i)],'k')
%text(200,25,[num2str(max(max(radYY))) ' ' num2str(min(min(radYY)))])
end
for i = 1:11
    plot([(2500/50)*(i) (2500/50)*(i)],[-1 105],'k')
%text(200,25,[num2str(max(max(radYY))) ' ' num2str(min(min(radYY)))])
end
title = ['\Mean Indentation Profile'];
savefile = [ListPath title];
export_fig(mInd,savefile,'-native');
cd(ListPath)

