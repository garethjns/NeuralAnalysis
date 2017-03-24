function obj = level8(obj)
% Level 8 analysis
% A, V, AVs, AVa (no offset?). Add basic AsM stuff?

close all force

% If session is empty, don't run
% Can happen in l8 if import is skipped due to missing response, box, etc.
% Not expected to happen in later levels as these were early errors and
% fixed.
if isempty(obj.data)
    return
end

% Level
l = 8;

% Training index
% Assume training flag based on RepeatMode for now
% All should be the same
trInd = ~obj.data.RepeatMode;

% Set standard trialIdx based on parameters
trialIdx = obj.setTrialIdx(obj);

% Construct trialInd - note old name
trialInd = trInd & trialIdx;

% Set file/folder string to use when saving graphs
figInfo = obj.prepDir(obj);

% Summary stats
obj.sumStats(obj.data, trialInd, l, figInfo)

% Run analysis
% Check it's worth running
if sum(trialInd)>20

    % Calculate fastProp
    fastProp = obj.calcFastProp(obj.data, trialInd, figInfo);
    snapnow; close all force
    
   % Plot performance and psych curves
    [fastPropFitted, bsAvg] = ...
        obj.plotPsych(obj.data, fastProp, trialInd, figInfo); 
    snapnow; close all force
    
    % % Correct
    PCCor = obj.PCCorrect(obj.data, trialInd, figInfo);
    snapnow; close all force
    
    % Plot RTs
    [RTsCI, RTsV] = ...
        obj.plotRTs(obj.data, trialInd, figInfo);
    snapnow; close all force
    
    % Run race model
    try
        raceStats = obj.runRace(RTsV.data);
        snapnow; close all force
    catch
        raceStats = NaN;
    end
    
    % Save to stats structure
    trialStats.fastProp = fastProp;
    trialStats.fastPropFitted = fastPropFitted;
    trialStats.bsAvg = bsAvg;
    trialStats.PCCor = PCCor;
    trialStats.RTsCI = RTsCI;
    trialStats.RTsV = RTsV;
    trialStats.raceStats = raceStats;
    
else
    % Save to stats structure
    trialStats.fastProp = NaN;
    trialStats.fastPropFitted = NaN;
    trialStats.fastPropFittedAs = NaN;
    trialStats.PCCor = NaN;
    trialStats.RTsCI = NaN;
    trialStats.RTsV = NaN;
    trialStats.raceStats = NaN;
    
end

% Save to object
obj.stats = trialStats;