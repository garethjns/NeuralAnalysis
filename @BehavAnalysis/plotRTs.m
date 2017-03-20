function [RTsCI, RTsV] = plotRTs(allData, trialInd, figInfo)
% Calculate and plot reation times
% Reaction time Histogram

% Valid conditions
validConditions = [1, 2, 3, 4, 5];

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

upperLim = 10;
lowerLim = -0.1;
xaxis=lowerLim:0.1:upperLim;

% Preallocate (far too big, shorten later)
statsData = NaN(length(allData.ResponseTime),3);

disp(tA)

% Create figure for subplotting
figure('OuterPosition', rect);
for i = 1:3 % 3 Conditions, 3 plots (all, correct, incorrect)
    % Address subplot
    subplot(3,1,i),
    hold on
    % Get right data
    switch  i
        case 1 % All RTs
            tit='All trials';
            % Get rid of anything longer than upperlimit
            index = allData.RT<upperLim ...
                & trialInd;
            col=colours(1,:);
            % This index will be longest, use to cull off NaNs later
            rowCul = sum(index);
        case 2 % Correct RTs
            tit='Correct trials only';
            index = allData.Correct == 1 ...
                & allData.RT<upperLim...
                & trialInd;
            col=colours(3,:);
        case 3 % Incorrect RTs
            tit='Incorrect trials only';
            % Get rid of correct answers
            index = allData.Correct == 0 ...
                & allData.RT<upperLim...
                & trialInd;
            col=colours(2,:);
    end
    
    % Collect for stats later
    statsData(1:length(allData.ResponseTime(index)),i) = ...
        allData.ResponseTime(index);
    
    % Plot histogram
    hist(allData.RT(index),xaxis);
    h = findobj(gca,'Type','patch');
    set(h,'FaceColor', col, 'EdgeColor', col);
    axis([min(xaxis), max(xaxis), 0 sum(trialInd)])
    title(tit);
    
    clear df index
end
suptitle([tA, 'Reaction time distributions'])
ng;

fn = [fns, 'RTs cor v incor'];
hgx(fn)
% hgexport(gcf, fn, hgexport('factorystyle'), ...
%     'Format', 'png');

% Remove uncessary NaNs
RTs=statsData(1:rowCul,:);

% ANOVA: RTs all vs correct vs incorrect
% Perform ANOVA (note anova is unbalanced if including 'all' group
[~, tab, stats] = anova1(RTs,{'All', 'Correct', 'Incorrect'});
title('RTs: correct vs incorrect trials')
ng;

% fn = [fns, 'Anova graphs.png'];
% hgexport(gcf, fn, hgexport('factorystyle'), ...
%     'Format', 'png');

RTsCI.data=RTs;
RTsCI.stats.Anova1.table = tab;
RTsCI.stats.Anova1.stats = stats;
% Use Anova stats to perform multiple comparison
RTsCI.stats.multiComp.stats = multcompare(stats);
RTsCI.stats.multiComp.colNames = {...
    'Group 1', ...
    'Group 2', ...
    '?', ...
    '?', ...
    '?', ...
    'p'};
% Print stats
disp(RTsCI.stats.multiComp.colNames)
disp(RTsCI.stats.multiComp.stats);

clear i RTs v statsData

% RT Boxplot **************************************************************
% Preallocate

plotData=NaN(size(allData,1),length(validConditions));

% Get data to use with boxplot
% Correct trials only
for v=1:length(validConditions)
    switch v
        case 1 % Everything
            ind = allData.RT<upperLim ...
                & allData.RT>lowerLim ...
                & trialInd;
            rowCul=sum(ind);
            data = allData.RT(ind);
        otherwise % v=1 or above
            % Get data to plot
            ind = allData.RT<upperLim ...
                & allData.RT>lowerLim ...
                & allData.Type==validConditions(v) ...
                & allData.Correct==1 ...
                & trialInd;
            
            data = allData.RT(ind);
    end
    
    % Store for boxplot
    plotData(1:length(data),v) = data;
    
    clear data
end

plotData=plotData(1:rowCul,:);
RTsV.data=plotData;

figure('OuterPosition', rect);
boxplot(plotData(:,2:5), 'colors', colours(2:5,:), 'notch', 'on', ...
    'widths', 0.5, 'plotstyle', 'compact', ...
    'labels', validCondTitsComp(2:5));
hYLabel=ylabel('Response time, ms');
hTitle=title([tA, 'Subject (Correct trials)']);
ng;

fn = [fns, 'RT correct trials'];
% hgexport(gcf, fn, hgexport('factorystyle'), ...
%     'Format', 'png');
hgx(fn)

clear plotData
