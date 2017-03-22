function [fastPropFitted, bsAvg] = ...
    plotPsych(allData, fastProp, trialInd, figInfo)
% Fit and plot psychometric curves

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

% Valid conditions
validConditions = [1, 2, 3, 4, 5];

% Unique rates in set
allRates = unique(allData.nEventsA(~isnan(allData.nEventsA)));

% Unique offsets for async
idx = allData.Type==5 & ~isnan(allData.aSyncOffset) & trialInd;
allOffsets = unique(allData.aSyncOffset(idx));
% Legend labels inclduing available offsets
xlabels = {'All', 'AO', 'VO', 'AVs', 'AVa'};
for o = 1:numel(allOffsets)
    xlabels = [xlabels, ['AVa_', num2str(allOffsets(o))]]; %#ok<AGROW>
end

% Params for fitting psychcurve
fineX = linspace(min(allRates)-10, max(allRates)+10, 100);
xaxis = (min(allRates):max(allRates))';

% Limits and start points:
%     g   l   u   v
UL = [0.02, 0.02, Inf, Inf];
SP = [0.01, 0.01, 10.5, 1];
LM = [0, 0, 0, 0];

% Preallocate
fastPropFitted = NaN(numel(fineX), size(fastProp,2), 1);


%% Run
% Order run:
% All data, AO, VO, AVs, AVa all, AVa offset 1, AVa offset 2, ...

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
            Sess.FitPsycheCurveWH2001b(xaxis, data, SP, LM, UL);
        
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


%% Plot summary fast prop graph
% Subplot and on same plot

disp(fastProp)
disp(allRates')

figure('OuterPosition', rect);
sp = 0;
plotInd = 2:5;
for v = plotInd
    sp = sp+1;
    hPlot = subplot(1, length(plotInd), sp);
    hold on,
    plot(fineX, fastPropFitted(:,v), 'color', colours(v,:), ...
        'LineWidth',2.5);
    h = errorbar(allRates', fastProp(:,v,1), ...
        fastProp(:,v,3), ['o', '']);
    set(h,'Color',colours(v,:));
    axis([min(allRates)-4, max(allRates)+4, 0, 1]);
    if v==1
        ylabel('Prop. "fast" response');
    end
    hXLabel=xlabel('n Events, /s');
    title(validCondTitsAlt(v));
end
suptitle([tA, 'Proportion of "fast" responses']);
Sess.ng;
hold off

% Save
fn = [fns, 'Prop right'];
Sess.hgx(fn)

% Tidy
clear v

% Plot again, on one fig
figure('OuterPosition', [-600 0 500 800]);
for v = plotInd
    hold on,
    plot(fineX, fastPropFitted(:,v), 'color', colours(v,:), ...
        'LineWidth',2.5);
    h = errorbar(allRates', fastProp(:,v,1), ...
        fastProp(:,v,3), ['o', '']);
    set(h,'Color',colours(v,:))
    h.MarkerSize = 10;
    h.LineWidth=1.5;
    axis([min(allRates)-4, max(allRates)+4, 0, 1]);
    if v==plotInd(1)
        ylabel('Prop. "fast" response');
    end
    xlabel('n Events, /s');
end
suptitle([tA, fName]);
% Double plot above, so duplicate titles and order correctly...
hLegend = legend(reshape(repmat(validCondTitsAlt(2:5),2,1), ...
    numel(validCondTitsAlt(2:5))*2,1));
set(hLegend,'Location','NorthWest');
set(hLegend,'Color',[0.95 0.95 0.95]);
ylabel('Prop. "Fast" responses')
hold off
Sess.ng;

% Save
fn = [fns, 'Prop right2'];
Sess.hgx(fn)

% Tidy
clear v


%% Plot figure for AVasync subsets

figure
plotInd = 5:size(fastProp,2);
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
        'LineWidth', 2.5);
    h = errorbar(allRates', fastProp(:,v,1), ...
        fastProp(:,v,3), ['o', '']);
    set(h,'Color', asColours(sp,:));
    axis([min(allRates)-4, max(allRates)+4, 0, 1]);
    if v==plotInd(1)
        ylabel('Prop. "fast" response');
    end
    hXLabel = xlabel('n Events, /s');
    title(xlabels(v));
end

suptitle([tA, 'Proportion of "fast" responses']);
Sess.ng;
hold off

% Save
fn = [fns, 'Prop right Async'];
Sess.hgx(fn)

% Tidy
clear v

% Plot again, on one fig
figure('OuterPosition', [-600 0 500 800]);
plotInd = 5:size(fastProp, 2);
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
hLegend = legend(hp, xlabels(5:size(fastProp,2)));
set(hLegend, 'Location', 'NorthWest');
set(hLegend, 'Color', [0.95 0.95 0.95]);
ylabel('Prop. "Fast" responses')
hold off
Sess.ng;

% Save
fn = [fns, 'Prop right Async2'];
Sess.hgx(fn)


%% Plot DT and bias as a function of modality

figure
plotInd = 2:5;
nPlot = numel(plotInd);
DT = NaN(nPlot, 1);
bi = NaN(nPlot, 1);
for v = plotInd
    % Get fit values, if available
    % (Remembering first v=2, and col 1 is all)
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
h.XTickLabel = {'Aud', 'Vis', 'AVs', 'AVa'};
xlabel('Modality, DT | Bias')
ylabel('nEvents')
title('DT and bias vs modality')
hold off
Sess.ng;

fn = [fns, 'Fit vs Mod'];
Sess.hgx(fn)


%% Plot DT and bias as a function of Async offset

figure

plotInd = 5:size(fastProp,2);
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
h.XTickLabel = xlabels(5:size(fastProp,2));
xlabel('As offset, DT | Bias')
ylabel('nEvents')
title('DT and bias vs Async offset')
hold off
Sess.ng;

fn = [fns, 'Fit vs AsOffset'];
Sess.hgx(fn)

close all force
