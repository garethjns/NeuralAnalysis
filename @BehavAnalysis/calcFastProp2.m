function fastProp = calcFastProp2(allData, trialInd, figInfo, bDiv)

close all

fns = figInfo.fns;

% Valid conditions
validConditions = [1, 5];

% Unique rates in set
allRates = unique(allData.nEventsA(~isnan(allData.nEventsA)));

% Unique offsets for async
idx = allData.Type==5 & ~isnan(allData.aSyncOffset) & trialInd;
allOffsets = unique(allData.aSyncOffset(idx));

% Async metric
% Histogram of available data (type 5)
if numel(bDiv) == 1
    % bDiv is division size
    asBinEdges = 0:bDiv:1;
    
else
    % bDiv is requested AsMs
     
     % Expand in to bins
     mDiff = mean(diff(bDiv));
     asBinEdges = [0, bDiv(1), bDiv(2), bDiv(3), 1];
end
allAsBins = diff(asBinEdges)/2 + asBinEdges(1:end-1);

nAsBins = numel(allAsBins);
idx5 = allData.Type == 5 & trialInd;
n5 = sum(idx5);

figure
histogram(allData.AsMActualLog(idx5,1), 'BinEdges', asBinEdges)
hold on
histogram(allData.AsMActualLog(idx5,1), 'BinEdges', 0:0.2:1)
histogram(allData.AsMActualLog(idx5,1), 'BinEdges', 0:0.1:1)
histogram(allData.AsMActualLog(idx5,1), 'BinEdges', 0:0.05:1)
histogram(allData.AsMActualLog(idx5,1), 'BinEdges', 0:0.025:1)
legend({'Selected bin edges', '0.2', '0.1', '0.05', '0.025'})

ng('1024');
hgx([fns, 'AsyncMetric divisions'])

% Calculate fastProp for each bin
% rates(1:6) x asBin x stat(1:3)
% (:,:,1) = mean
% (:,:,2) = STD
% (:,:,3) = SE
% Columns: All data, AVa async 1, AVa async 2, ...
% Preallocate:
fastProp = ...
    NaN(numel(allRates), nAsBins+1, 3);
fastPropN = ...
    NaN(numel(allRates), nAsBins+1);

fpCol = 0;
for v = 1:length(validConditions)
    
    switch validConditions(v)
        case 1
            nAsBinsT = 1;
        case 5
            nAsBinsT = nAsBins;
    end
            
    
    for a = 1:nAsBinsT
        fpCol = fpCol + 1;
        for r = 1:numel(allRates)
            switch validConditions(v)
                case 1 % "All", but just all 5s
                    index = (allData.nEventsA == allRates(r) | ... % A rate |
                        allData.nEventsV == allRates(r)) ...
                        & allData.Type == 5 ...
                        & trialInd;
                case 5
                    % Pick subset of asyncs
                    index = (allData.nEventsA == allRates(r) | ... % A rate |
                        allData.nEventsV == allRates(r)) ... % V rate
                        & allData.Type == validConditions(v) ... % 5 only
                        & allData.AsMActualLog >= asBinEdges(a) ... % AsM >
                        & allData.AsMActualLog < asBinEdges(a+1) ... % AsM <
                        & trialInd; % Data subset
            end
            
            data = allData.Response(index);
            n = numel(data);
            % Calculate proportion of fast respoinses
            prop = sum(data==1) / n;
            % Also record n
            fastPropN (r,fpCol) = n;
            % SD assmuning normal distribution (requires  large n)
            % SD = std(data);
            % SD assuming binomial distribution (low n)
            SD = mean(data)*(1-mean(data)) /n;
            % Save
            fastProp(r,fpCol,1) = prop;
            fastProp(r,fpCol,2) = SD;
            fastProp(r,fpCol,3) = SD./sqrt(n);
            
            clear index data prop
            
        end
    end
end

% Plot a summary image of what's in this data subset
close all
figure
clabel = arrayfun(@(x){sprintf('%0.0f',x)}, fastPropN);
ylabels = arrayfun(@(x){sprintf('%0.0f',x)}, allRates);
xlabels = {'All(5)'};
for a = 1:numel(allAsBins)
    xlabels = [xlabels, ['AsM_', num2str(allAsBins(a))]]; %#ok<AGROW>
end
subplot(2,1,1)
heatmap(fastPropN, xlabels, ylabels, clabel, 'TickAngle', 45)
title(['n trials available in ', figInfo.titleAppend])
ylabel('Rates')
xlabel('Subset')

subplot(2,1,2)
clabel = arrayfun(@(x){sprintf('%0.2f',x)}, fastProp(:,:,1));
heatmap(fastProp(:,:,1), xlabels, ylabels, clabel, 'TickAngle', 45)
title(['Prop of right responses in  ', figInfo.titleAppend])
ylabel('Rates')
xlabel('Subset')

ng('1024');
hgx([fns, 'AsyncMetric Subset summary'])

