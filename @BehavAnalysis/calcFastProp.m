function fastProp = calcFastProp(allData, trialInd, figInfo)
% Calculate fastProp

close all

fns = figInfo.fns;

% Calculate fastProp
% rates(1:6) x type(1:7) x stat(1:3)
% (:,:,1) = mean
% (:,:,2) = STD
% (:,:,3) = SE
% Columns: All data, AO, VO, AVs, AVa all, AVa offset 1, AVa offset 2, ...

% Valid conditions
validConditions = [1, 2, 3, 4, 5];

% Unique rates in set
allRates = unique(allData.nEventsA(~isnan(allData.nEventsA)));

% Unique offsets for async
idx = allData.Type==5 & ~isnan(allData.aSyncOffset) & trialInd;
allOffsets = unique(allData.aSyncOffset(idx));

% Preallocate
fastProp = ...
    NaN(numel(allRates), length(validConditions)+length(allOffsets), 3);
fastPropN = ...
    NaN(numel(allRates), length(validConditions)+length(allOffsets));

% Order run:
% All data, AO, VO, AVs, AVa all, AVa offset 1, AVa offset 2, ...
% Output column
fpCol = 0;
for v = 1:length(validConditions)
    
    % If this is async, set offsets
    switch v
        case 5
            offsets = allOffsets;
        otherwise
            offsets = [];
    end
    
    % For all offsets
    for o = 1:numel(offsets) + 1 % 1 for all except AV async
        fpCol = fpCol + 1;
        
        % For all rates
        for r = 1:numel(allRates)
            switch v
                case 1 % All data
                    index = (allData.nEventsA == allRates(r) ... % A rate |
                        | allData.nEventsV == allRates(r)) ...
                        & trialInd;
                case 5
                    if o == 1
                        % Do average of all offsets
                        index = (allData.nEventsA == allRates(r) ... % A rate |
                            | allData.nEventsV == allRates(r)) ... % V rate
                            & allData.Type == validConditions(v) ... % 5 only
                            & trialInd; % Data subset
                    else
                        % Pick subset of offsets
                        index = (allData.nEventsA == allRates(r) ... % A rate |
                            | allData.nEventsV == allRates(r)) ... % V rate
                            & allData.Type == validConditions(v) ... % 5 only
                            & allData.aSyncOffset == offsets(o-1) ... % Offset
                            & trialInd; % Data subset
                    end
                    
                otherwise % AO, VO, AVsync
                    % ( | ok here because when 2 rates present, they're
                    % the same, so doesn't duplicate data)
                    index = (allData.nEventsA == allRates(r) ... % A rate |
                        | allData.nEventsV == allRates(r)) ... % V rate
                        & allData.Type == validConditions(v) ...
                        & trialInd;
            end
            
            data = allData.Response(index);
            n = numel(data);
            
            % Calculate proportion of fast responses
            prop = sum(data==1) / n;
            
            % Also record n
            fastPropN (r,fpCol) = n;
            
            % SD assmuning normal distribution (requires large n)
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
xlabels = {'All', 'AO', 'VO', 'AVs', 'AVa'};
for o = 1:numel(allOffsets)
    xlabels = [xlabels, ['AVa_', num2str(allOffsets(o))]]; %#ok<AGROW>
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

Sess.ng('1024');
hgx([fns, 'Subset summary'])

% Plot as surface, for fun
figure
x3 = repmat((1:size(fastPropN,1))', 1, size(fastPropN,2));
y3 = repmat((1:size(xlabels,2)), size(fastPropN,1), 1);
scatter3(x3(:), y3(:), fastPropN(:))

hold on
sf = fit([x3(:), y3(:)], fastPropN(:), 'poly23');
plot(sf,[x3(:),y3(:)],fastPropN(:))
ng;
hgx([fns, 'N surface']);

% Also save the behavioural subset this stuff has been calculated from
% subset = allData(trialInd,:);
% save([fns, 'behavData.mat'], 'subset')
