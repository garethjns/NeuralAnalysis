function obj = level11(obj)
% Level 11 Analyisis - in progress
% DIDs not compiled yet

close all force

% Level
l = 11;

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

% Check it's worth running
if sum(trialInd)>20
    
    % Calculate fastProp
    fastProp = obj.calcFastProp(obj.data, trialInd, figInfo);
    snapnow; close all force
    
    % Explore asychrony metric and recalculate fastProp
    % In level 11 AsMs are requested, so set fParams.asParams.bDiv
    % Eg. finalReport.targetAsMs: [0.1000 0.2500 0.4000]
    % to something sensible
    % ROUGH
    fParams.asParams.bDiv = obj.data(trialInd,:).ReqAsMs{1};
    fastPropAs = ...
        obj.calcFastProp2(obj.data, trialInd, figInfo, ...
        fParams.asParams.bDiv);
    snapnow; close all force
    
    % Plot performance and psych curves
    [fastPropFitted, bsAvg] = ...
        obj.plotPsych(obj.data, fastProp, trialInd, figInfo); 
    snapnow; close all force
    
    % And async
    [fastPropFittedAs, bsAvgAs] = ...
        obj.plotPsychAs(obj.data, fastPropAs, trialInd, figInfo, ...
        fParams.asParams.bDiv);
    snapnow; close all force
    
    % % Correct
    PCCor = obj.PCCorrect(obj.data, trialInd, figInfo);
    snapnow; close all force
    
    % % Correct asyncs
    [PCCorAsM, PCCorOff] = ...
        obj.PCCorrectAs(obj.data, trialInd, figInfo, fParams); 
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
    trialStats.fastPropFittedAs = fastPropFittedAs;
    trialStats.bsAvg = bsAvg;
    trialStats.bsAvgAs = bsAvgAs;
    trialStats.PCCor = PCCor;
    trialStats.PCCorAsM = PCCorAsM;
    trialStats.PCCorOff = PCCorOff;
    trialStats.RTsCI = RTsCI;
    trialStats.RTsV = RTsV;
    trialStats.raceStats = raceStats;
    
else
    % Save to stats structure
    trialStats.fastProp = NaN;
    trialStats.fastPropFitted = NaN;
    trialStats.fastPropFittedAs = NaN;
    trialStats.bsAvg = NaN;
    trialStats.bsAvgAs = NaN;
    trialStats.PCCor = NaN;
    trialStats.PCCorAsM = NaN;
    trialStats.PCCorOff = NaN;
    trialStats.RTsCI = NaN;
    trialStats.RTsV = NaN;
    trialStats.raceStats = NaN;
    
end

% Save to object
obj.stats = trialStats;
