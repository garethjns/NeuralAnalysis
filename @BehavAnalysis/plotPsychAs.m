function [fastPropFitted, bsAvg] = ...
    plotPsychAs(allData, fastProp, trialInd, figInfo, bDiv)

% Plot psychometric curves (async metric)

%% Setup

% Unpackage figInfo
rect = figInfo.rect;
tA = figInfo.titleAppend;
colours = figInfo.colours;
validCondTits = figInfo.validCondTits; %#ok<*NASGU>
validCondTitsComp = figInfo.validCondTitsComp;
validCondTitsAlt = figInfo.validCondTitsAlt;
fName = figInfo.fName;
fns = figInfo.fns;
fnsAppend = figInfo.fnsAppend;

% Valid conditions
validConditions = [1, 5];

% Unique rates in set
allRates = unique(allData.nEventsA(~isnan(allData.nEventsA)));

% Async metric
% Histogram of available data (type 5)
if numel(bDiv) == 1
    % bDiv is division size
    asBinEdges = 0:bDiv:1;
else
    % bDiv is actual bins
    if bDiv(1) ~= 0 && bDiv(end) ~=1
        % Expand in to bins
        asBinEdges = [0, bDiv, 1];
    else
        asBinEdges = bDiv;
    end
end

% Get bin midpoints
allAsBins = diff(asBinEdges)/2 + asBinEdges(1:end-1);

% Count bins, trails
nAsBins = numel(allAsBins);
idx5 = allData.Type == 5 & trialInd;
n5 = sum(idx5);

% Unique offsets for async
xLabels = {'All(5)'};
for a = 1:numel(allAsBins)
    xLabels = [xLabels, ['AsM_', num2str(allAsBins(a))]]; %#ok<AGROW>
end

% Params for fitting psychcurve
fineX = linspace(min(allRates)-10, max(allRates)+10, 100);
xaxis = (min(allRates):max(allRates))';

% Limits and start points:
%     g   l   u   v
UL = [0.02, 0.02, inf, inf];
SP = [0.01, 0.01, 10.5, 1];
LM = [0, 0, 0, 0];

% Preallocate
fastPropFitted = NaN(numel(fineX), size(fastProp,2), 1);


%% Run
% Order run:
% All (5), AsMs

for v = 1:size(fastProp,2)
    % Reset xaxis
    xaxis = allRates;
    % Now have fastProp for all rates for this v
    % Fit psychcurve...
    
    % Get current data for convenience
    data = fastProp(:,v,1);
    % Discard nans
    xaxis = xaxis(~isnan(data));
    data = data(~isnan(data));
    
    % Fit
    try % Fit fails on NaN data
        b = ...
            BehavAnalysis.fitPsycheCurveWH(xaxis, data, [UL; SP; LM]);
        
        % Save coefficients
        bsAvg(:,v).data = b;  %#ok<AGROW>
        
        % Eval curve
        y = feval(b, fineX);
        
        % Save curve
        fastPropFitted(:,v) = y;
        
    catch err
        bsAvg(:,v).data = NaN; %#ok<AGROW>
        % err
        % Will error on fit if data is empty
    end
    
    clear data y b
end
clear r v


%% Plot figure for AVasync subsets

figure
plotInd = 2:size(fastProp,2);
sp = 0;
% Create colour gradient
asColours = colours(5,:);
for c = 2:numel(plotInd)
    asColours(c,:) = asColours(c-1,:) + ...
        [-(colours(5,1)/numel(plotInd)-0.005), ...
        (colours(5,2)/numel(plotInd)-0.005), ...
        (colours(5,1)/numel(plotInd)-0.005)];
end
asColours(asColours<0) = 0;
asColours(asColours>1) = 1;

for v = plotInd
    sp = sp+1;
    hPlot = subplot(1,length(plotInd), sp);
    hold on,
    plot(fineX, fastPropFitted(:,v), 'color', asColours(sp,:), ...
        'LineWidth',2.5);
    h = errorbar(allRates', fastProp(:,v,1), ...
        fastProp(:,v,3), ['o', '']);
    set(h,'Color', asColours(sp,:));
    axis([min(allRates)-4, max(allRates)+4, 0, 1]);
    if v==plotInd(1)
        ylabel('Prop. "fast" response');
    end
    hXLabel = xlabel('n Events, /s');
    title(xLabels(v));
end
suptitle([tA, 'Proportion of "fast" responses']);
Sess.ng;
hold off


% Save
fn = [fns, 'Prop right Async', fnsAppend];
Sess.hgx(fn)

% Tidy
clear v

% Plot again, on one fig
figure('OuterPosition', [-600 0 500 800]);
plotInd = 2:size(fastProp,2);
sp = 0;
hp = plot(fineX, fastPropFitted(:, plotInd), ...
    'LineWidth',2.5);
for c = 1:numel(plotInd)
    hp(c).Color = asColours(c,:);
end

for v = plotInd
    sp = sp+1;
    hold on,
    
    h = errorbar(allRates', fastProp(:,v,1), ...
        fastProp(:,v,3), ['o', '']);
    set(h,'Color', asColours(sp,:))
    h.MarkerSize = 10;
    h.LineWidth = 1.5;
    axis([min(allRates)-4, max(allRates)+4, 0, 1]);
    if v==plotInd(1)
        ylabel('Prop. "fast" response');
    end
    xlabel('n Events, /s');
end
suptitle([tA, fName]);
% Double plot above, so duplicate titles and order correctly...
hLegend = legend(hp, xLabels(2:size(fastProp,2)));
set(hLegend, 'Location', 'NorthWest');
set(hLegend, 'Color', [0.95 0.95 0.95]);
ylabel('Prop. "Fast" responses')
hold off
Sess.ng;

% Save
fn = [fns, 'Prop right Async2_AsM', fnsAppend];
Sess.hgx(fn)


%% Plot DT and bias as a function of Async metric

figure

plotInd = 2:size(fastProp,2);
nPlot = numel(plotInd);
DT = NaN(nPlot, 1);
bi = NaN(nPlot, 1);
for v = plotInd
    % Get fit values, if available
    % (Remembering first v=5, and col 1 is all)
    if isa(bsAvg(v).data, 'cfit')
        DT(v-(plotInd(1)-1)) = bsAvg(v).data.v;
        bi(v-(plotInd(1)-1)) = bsAvg(v).data.u;
    else
        DT(v-(plotInd(1)-1)) = NaN;
        bi(v-(plotInd(1)-1)) = NaN;
    end
end

% Remove totally stupid fits
idx = DT > 50 & bi > 50;
DT = DT(~idx);
bi = bi(~idx);

bar([DT, bi])
h = gca;
h.XTickLabel = cellstr(num2str(allAsBins'));
xlabel('Asynchrony, DT | Bias')
ylabel('nEvents')
title('DT and bias vs Async metric')
hold off
Sess.ng;

fn = [fns, 'Fit vs AsOffset_AsM', fnsAppend];
Sess.hgx(fn)

close all force
