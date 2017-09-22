function [hAVs, hAVa] = findMSI(obj, chan)
% Run findMSI on supplied data
% All trials in data used, so handle idexing in calling function
%

% Get index of ok neural data on this channel
eIdx = obj.neuralData.recOK.OK;
okIdx = eIdx(1,chan,:);

% Load spikes
eSpikes = obj.neuralData.spikes(:,chan,okIdx);

% Get behav data
data = obj.data(okIdx,:);

hAVs = figure;
hAVa = figure;

if isempty(data)
    return
end


%% A, V, AVs figure

figure(hAVs)
mods = [2, 3, 4];
nMods = numel(mods);
rates = [4, 6, 8, 12, 14, 16];
nRates = numel(rates);
sp = 0 + nRates;
maxEvents = 0;
stimRowDone = false(1, nRates);

% A, V, AVs
for vi = 1:3
    v = mods(vi);
    tIdx = data.Type == v;
    
    for ri = 1:nRates
        r = rates(ri);
        
        % Subplot number
        sp = sp+1;
        
        switch v
            case 2
                rIdx = data.nEventsA==r;
                tit = ['A: ', num2str(r), ' events'];
                yLab = 'nurEvRate';
            case 3
                rIdx = data.nEventsV==r;
                tit = ['V: ', num2str(r), ' events'];
            case 4
                rIdx = data.nEventsA==r;
                tit = ['AVs: ', num2str(r), ' events'];
        end
        
        % Set line colour
        col = obj.figInfo.colours(v,:);
        yLab = 'nurEvRate';
        
        % Rate and type index
        dIdx = tIdx & rIdx;
        
        % If there's no data, don't try and plot...
        if sum(dIdx)==0
            continue
        end
        
        % Plot stim row for this rate if it hasn't been done yet
        if ~stimRowDone(ri)
            subplot(nMods+1, nRates, ri);
            plotStimRow(obj, data, dIdx)
            stimRowDone(ri) = true;
            title([num2str(rates(ri)), ' Events'])
            if r == 1
                ylabel('Normalised stim')
            end
        end

        % Plot this PSTH box
        subplot(nMods+1, nRates, sp)
        [nEv, ~, ~] = plotPSTHBox(obj, eSpikes, dIdx, col);
        
        % Left col
        if r == 1
            ylabel(yLab)
        end
        % Bottom row, middle
        if r == 3 && vi == 3
            xlabel('Time, S')
        end
        
        % Keep track of maxEvents to rescale plots
        maxEvents(maxEvents<nEv) = nEv; %#ok<AGROW> lies
    end
end

% Set maxEvents on each axis
if maxEvents>1000
    maxEvents = 1000;
end
for sp = nRates+1:nMods*nRates+nRates
    subplot(nMods+1, nRates, sp)
    ylim([0, maxEvents])
end

ng('Huge')
hgx([obj.analysisPath, 'MSI\Chan', num2str(chan), '_AVs.png'])


%% AVa Figure

figure(hAVa)

v = 5;
nMods = 1;
tIdx = data.Type == v;

maxEvents = 0;
stimRowDone = false(1, nRates);
sp = 1;

for ri = 1:nRates
    r = rates(ri);
    
    % Subplot number
    sp = sp+1;
    
    rIdx = data.nEventsA==r;
    tit = ['AVa: ', num2str(r), ' events'];
    
    % Set line colour
    col = obj.figInfo.colours(v,:);
    yLab = 'nurEvRate';
    
    % Rate and type index
    dIdx = tIdx & rIdx;
    
    % If there's no data, don't try and plot...
    if sum(dIdx)==0
        continue
    end
    
    % Plot stim row for this rate if it hasn't been done yet
    if ~stimRowDone(ri)
        subplot(nMods+1, nRates, ri);
        plotStimRow(obj, data, dIdx)
        stimRowDone(ri) = true;
        title([num2str(rates(ri)), ' Events'])
        if r == 1
            ylabel('Normalised stim')
        end
    end
    
    % Plot this PSTH box
    subplot(nMods+1, nRates, sp)
    [nEv, ~, ~] = plotPSTHBox(obj, eSpikes, dIdx, col);
    
    % Left col
    if r == 1
        ylabel(yLab)
    end
    % Bottom row, middle
    if r == 3 && vi == 3
        xlabel('Time, S')
    end
    
    % Keep track of maxEvents to rescale plots
    maxEvents(maxEvents<nEv) = nEv; %#ok<AGROW> lies
end
    
% Set maxEvents on each axis
if maxEvents>1000
    maxEvents = 1000;
end
for sp = nRates+1:nMods*nRates+nRates
    subplot(nMods+1, nRates, sp)
    ylim([0, maxEvents])
end

ng('Huge')
hgx([obj.analysisPath, 'MSI\Chan', num2str(chan), '_AVs.png'])


function plotStimRow(obj, data, dIdx)
% Plot stimulus row

% Regen the "generic" stim
% Only need to do this once per column, but might be in A or V depending on
% type
stimA.sound = [];
stimV.sound = [];
if isstruct(data(dIdx,:).aStim{1})
    % Get from A
    cfgA = data(dIdx,:).aStim{1};
    cfgA.eventType = 'flat';
    cfgA.noiseType = 'blocked';
    cfgA.eventMag = 1;
    cfgA.mag = 0;
    cfgA.noiseMag = 0.000001;
    stimA = TemporalStim(cfgA);
    
    FsS = cfgA.Fs;
elseif isstruct(data(dIdx,:).vStim{1})
    % Get from V
    cfgV = data(dIdx,:).vStim{1};
    cfgV.eventType = 'flat';
    cfgV.noiseType = 'blocked';
    cfgV.eventMag = 1;
    cfgV.mag = 0;
    cfgV.noiseMag = 0.000001;
    stimV = TemporalStim(cfgV);
    
    FsS = cfgV.Fs;
end

% stims = zeros(2, max([length(stimV.sound), length(stimA.sound)]));
% stims(1, 1:length(stimA.sound)) = stimA.sound;
% stims(2, 1:length(stimV.sound)) = stimV.sound; 

% Drop in buffer
preTime = obj.neuralData.neuralParams.EpochPreTime;
postTime = obj.neuralData.neuralParams.EpochPostTime;
SprePts = round(preTime*FsS);
SpostPts = round(postTime*FsS);
SepochPts = abs(SprePts) + SpostPts + 1;
buffer = zeros(2, SepochPts);
tVecS = ...
    linspace(preTime, postTime, size(buffer,2));
[~, zIdx] = min(abs(tVecS));
buffer(1,zIdx-(length(stimA.sound)-1):zIdx) = ...
    stimA.sound;
buffer(1,zIdx-(length(stimV.sound)-1):zIdx) = ...
    stimV.sound;

% Add start/end lines
hold on
line([-1.15, -1.15],[-1000, 1000], ...
    'LineStyle', '--', ...
    'color', [0.80, 0.80, 0.80])
line([0, 0],[-1000, 1000], ...
    'LineStyle', '--', ...
    'color', [0.80, 0.80, 0.80])

% Plot stim
plot(tVecS, buffer, 'color', 'k')

% Finish
ylim([-0.05, 1.1])
xlim([-1.5, 0.2])


function [nEv, PSTH, acc] = plotPSTHBox(obj, eSpikes, dIdx, col)
% Get PSTH and raster, plot

% Get PSTH
fs = obj.neuralData.neuralParams.Fs; 
[raster, ~, ~] = ...
    obj.neuralData.raster(eSpikes(:,:,dIdx), fs);
[PSTH, tVecP] = obj.neuralData.PSTH(raster, fs, 10);

% Plot
plot(tVecP, PSTH, 'color', col)
leg = [num2str(sum(dIdx)), ' trials'];

% Run current Brunton script
window = 300-117:300;
params.a = 0.001;
params.aVar = 0;
params.sVar = 0;
params.lam = 1;
params.C = 1;
params.phi = 2;
params.tauPhi = 1;
params.B = 100;
params.plot = 0;
% Adaptation disabled in this script
acc = Sess.Brunton2013G(PSTH(window), params);
nEv = max(acc)/10;

% plotLayout{vi,r} = acc;
% tVec = tVec+50;

% Add start/end lines
hold on
line([3000-1150, 3000-1150], [-10000, 10000], ...
    'LineStyle', '--', ...
    'color', [0.80, 0.80, 0.80])
line([3000, 3000], [-10000, 10000], ...
    'LineStyle', '--', ...
    'color', [0.80, 0.80, 0.80])
plot(tVecP(window), acc/10, 'color', 'k')

% Finish
legend(leg)
ylim([-2, 20])
xlim([1500, 3200])
a = gca;
a.XTickLabel = {'-1','0'};
