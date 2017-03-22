function [PCCorAsM, PCCorOff] = PCCorrectAs(allData, trialInd, figInfo, fParams)
% Calculate percent correct: Both offset and asm for asyncs
% Correct answer histogram
% Plots histogram of all answers.
% Gets % correct summary
% Need to tidy: calculates std,n etc. but doesn't return. No colours on
% plots.

% Valid conditions
validConditions = [1, 5];

% Unpackage figInfo
% {rect, colours, validCondTits, validCondTitsComp, validCondTitsAlt, ...
% fName}
rect = figInfo.rect;
tA = figInfo.titleAppend;
colours = figInfo.colours;
validCondTits = figInfo.validCondTits;
validCondTitsComp = figInfo.validCondTitsComp;
validCondTitsAlt = figInfo.validCondTitsAlt;
fName = figInfo.fName;
fns = figInfo.fns;

% Unique rates in set
allRates = unique(allData.nEventsA(~isnan(allData.nEventsA)));

% Unique offsets for async
offIdx = allData.Type==5 & ~isnan(allData.aSyncOffset) & trialInd;
allOffsets = unique(allData.aSyncOffset(offIdx));
nOffs = size(allOffsets,1);

% Async metric
% Histogram of available data (type 5)
bDiv = fParams.asParams.bDivL11;
asBinEdges = 0:bDiv:1;
allAsBins = diff(asBinEdges)/2 + asBinEdges(1:end-1);
nAsBins = numel(allAsBins);
idx5 = allData.Type == 5 & trialInd;
n5 = sum(idx5);


%% Loop + figure for offsets

% Preallocate
PCCorOff = array2table(NaN(1,size(allOffsets,1)+1));
PCCorOff.Properties.VariableNames{1} = 'AllAs5';

% Can't be arsed to name properly
for a = 1:nOffs
    PCCorOff.Properties.VariableNames{a+1} = ['o', num2str(a)];
end
pdl = NaN(1,length(validConditions));

% Create colour gradient
asColours = colours(5,:);
for c = 2:nOffs+1
    asColours(c,:) = asColours(c-1,:) + ...
        [-(colours(5,1)/nOffs-0.005), ...
        (colours(5,2)/nOffs-0.005), ...
        (colours(5,1)/nOffs-0.005)];
end
asColours(asColours<0) = 0;
asColours(asColours>1) = 1;

figure('OuterPosition', rect);
% In this case 1=All async, 5=async, then subdivided by whichever index
fpCol = 0;
for v = 1:length(validConditions)
    
    switch validConditions(v)
        case 1
            nOffsb = 1;
        case 5
            nOffsb = nOffs;
    end
    
    for o = 1:nOffsb % Run once for 1, as much as needed for 5
        plotData = [];
        fpCol = fpCol + 1;
        switch v
            case 1
                plotData(:,1) = allData.Correct(offIdx); % offIdx includes trialInd
                
                pdl(v) = size(plotData,1);
                
                % Graph stuff
                tit = 'All async trials';
                limy = [0, 600];
                col = asColours(v,:);
                ecol = 'w';
                
            otherwise % Data for current, valid condition
                index = allData.aSyncOffset == allOffsets(o)... 
                    & trialInd;
                
                plotData = allData.Correct(index);
                
                % Graph stuff
                tit = ['o', num2str(allOffsets(o))];
                limy = [0, 600];
                col = asColours(v,:);
                ecol = 'k';
        end
        
        subplot(1,nOffs+1,fpCol),
        hist(plotData,0:1:1);
        % Set colour of hist
        h = findobj(gca,'Type','patch');
        try % What if there's no bar?
            set(h,'FaceColor', col, 'EdgeColor', ecol)
        end
        title(tit);
        ylabel('n');
        xlim([-1 2]);
        ylim(limy)
        
        % PCcorrect
        PCCorOff{1,fpCol} = sum(plotData)/length(plotData)*100;
        xlabel([num2str((round(PCCorOff{1,fpCol}*10))/10), '%']);
        PCCorOffStd(1,fpCol) = std(plotData)*100;
        PCCorOffn(1,fpCol) = length(plotData);
        clear data2Plot index tit h col ecol limy
    end
end
suptitle([tA, 'Proportion of correct responses'])
Sess.ng;

fn = [fns, 'Prop correct As Offs'];
Sess.hgx(fn)

disp('%s correct:')
disp(PCCorOff);


%% Loop + figure for AsM

% Preallocate
PCCorAsM = array2table(NaN(1,size(allAsBins,2)+1));
PCCorAsM.Properties.VariableNames{1} = 'AllAs5';
% Can't be arsed to name properly
for a = 1:nAsBins
    PCCorAsM.Properties.VariableNames{a+1} = ['a', num2str(a)];
end
pdl = NaN(1,length(validConditions));

% Create colour gradient
asColours = colours(5,:);
for c = 2:nAsBins+1
    asColours(c,:) = asColours(c-1,:) + ...
        [-(colours(5,1)/nAsBins-0.005), ...
        (colours(5,2)/nAsBins-0.005), ...
        (colours(5,1)/nAsBins-0.005)];
end
asColours(asColours<0) = 0;
asColours(asColours>1) = 1;

figure('OuterPosition', rect);
% In this case 1=All async, 5=async, then subdivided by whichever index
fpCol = 0;
for v = 1:length(validConditions)
    
    switch validConditions(v)
        case 1
            nAsBinsb = 1;
        case 5
            nAsBinsb = nAsBins;
    end
    
    for o = 1:nAsBinsb % Run once for 1, as much as needed for 5
        plotData = [];
        fpCol = fpCol + 1;
        switch v
            case 1
                plotData(:,1) = allData.Correct(idx5); % idx5 includes trialInd
                
                pdl(v) = size(plotData,1);
                
                % Graph stuff
                tit = 'All async trials';
                limy = [0, 600];
                col = asColours(v,:);
                ecol = 'w';
                
            otherwise % Data for current, valid condition
                index = allData.AsMActualLog >= asBinEdges(o) ... % AsM >
                        & allData.AsMActualLog < asBinEdges(o+1) ... % AsM <
                        & trialInd;
                
                plotData = allData.Correct(index);
                
                % Graph stuff
                tit = ['a', num2str(allAsBins(o))];
                limy = [0, 600];
                col = asColours(v,:);
                ecol = 'k';
        end
        
        subplot(1,nAsBins+1,fpCol),
        hist(plotData,0:1:1);
        % Set colour of hist
        h = findobj(gca,'Type','patch');
        set(h,'FaceColor', col, 'EdgeColor', ecol)
        title(tit);
        ylabel('n');
        xlim([-1 2]);
        ylim(limy)
        
        % PCcorrect
        PCCorAsM{1,fpCol} = sum(plotData)/length(plotData)*100;
        xlabel([num2str((round(PCCorAsM{1,fpCol}*10))/10), '%']);
        PCCorAsMStd(1,fpCol) = std(plotData)*100;
        PCCorAsMn(1,fpCol) = length(plotData);
        clear data2Plot index tit h col ecol limy
    end
end
suptitle([tA, 'Proportion of correct responses'])
Sess.ng;

fn = [fns, 'Prop correct As Offs'];
Sess.hgx(fn)
% hgexport(gcf, fn, hgexport('factorystyle'), ...
%     'Format', 'png');

disp('%s correct:')
disp(PCCorAsM);

%% Alternative, more sensible plots

close all force

figure
hBar = bar(1:nOffs+1, PCCorOff{1,:});
hold on
errorbar(PCCorOff{1,:}, PCCorOffStd./sqrt(PCCorOffn), 'LineStyle', 'none')
a = gca;
a.XTickLabel = ['AllAs'; cellstr(num2str(allOffsets))];
ylabel('% Correct')
xlabel('Offset')
title('% correct, asyncs by offset')
Sess.ng;
fn = [fns, 'Prop correct As Offs2'];
Sess.hgx(fn)

figure
hBar = bar(1:nAsBins+1, PCCorAsM{1,:});
hold on
errorbar(PCCorAsM{1,:}, PCCorAsMStd./sqrt(PCCorAsMn), 'LineStyle', 'none')
a = gca;
a.XTickLabel = ['AllAs'; cellstr(num2str(allAsBins'))];
ylabel('% Correct')
xlabel('AsM')
title('% correct, asyncs by AsM')
Sess.ng;
fn = [fns, 'Prop correct As AsM2'];
Sess.hgx(fn)

