function obj = level9(obj)
% Analysis for level 9 using standard template. ie. analysing as if rate is
% being changed. Does do noise level analysis - see threshold function -
% check.

close all force

% Level
l = 9;

% No training trials for this level?
trInd = ones(height(obj.data),1);

% Set standard trialIdx based on parameters
trialIdx = obj.setTrialIdx(obj);

% Construct trialInd - note old name
trialInd = trInd & trialIdx;

% Get WID
obj.figInfo.WID = obj.session.WID{1};

% Set file/folder string to use when saving graphs
figInfo = obj.prepDir(obj);

% Summary stats
obj.sumStats(obj.data, trialInd, l, figInfo)

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
        
    % Per-noise level analysis
    % Calculate threshold
    thresh = obj.threshold(obj.data, trialInd, figInfo);
    snapnow; close all force
    
    trialStats.fastProp = fastProp;
    trialStats.fastPropFitted = fastPropFitted;
    trialStats.bsAvg = bsAvg;
    trialStats.PCCor = PCCor;
    trialStats.RTsCI = RTsCI;
    trialStats.RTsV = RTsV;
    trialStats.thresh = thresh;
else
    % Save to stats structure
    trialStats.fastProp = NaN;
    trialStats.fastPropFitted = NaN;
    trialStats.bsAvg = NaN;
    trialStats.PCCor = NaN;
    trialStats.RTsCI = NaN;
    trialStats.RTsV = NaN;
    trialStats.thresh = NaN;
end

% Save to object
obj.stats = trialStats;
