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
    
    % Calculate fastProp - temp dis
    fastProp = obj.calcFastProp(obj.data, trialInd, figInfo);
    snapnow; close all force
    % Plot performance and psych curves
    [fastPropFitted, bsAvg] = ...
        obj.plotPsych(obj.data, fastProp, trialInd, figInfo);
    %snapnow; close all force
    % % Correct
    PCCor = obj.PCCorrect(obj.data, trialInd, figInfo);
    snapnow; close all force
    
    % Calculate fastProp for AsM as calculated during seed generation
    % - depends on params used then. Use the originally requested AsMs as
    % bins
    % This is in .AsMActualLog / .ReqAsMs
    bDiv = obj.data(trialInd,:).ReqAsMs{1};
    figInfo.fnsAppend = [char(BehavAnalysis.BES(bDiv)), 'Recalc0'];
    [fastPropAsExp, ~] = ...
        obj.calcFastProp2(obj.data, trialInd, figInfo, ...
        bDiv);
    snapnow; close all force
    % Plot these
    [fastPropFittedAsExp, bsAvgAsExp] = ...
        obj.plotPsychAs(obj.data, fastPropAsExp, trialInd, figInfo, ...
        bDiv);
    snapnow; close all force
    % % Correct asyncs
    [PCCorAsMExp, PCCorOffExp] = ...
        obj.PCCorrectAs(obj.data, trialInd, figInfo, bDiv); 
    snapnow; close all force
    
    % Calculate fastProp using using bins defined in analysis params
    % (fParams.asParams.bDiv2) 
    bDiv2 = obj.subjectParams.asParams.bDiv2;
    figInfo.fnsAppend = [char(BehavAnalysis.BES(bDiv2)), 'Recalc0'];
    [fastPropAsRecalc, recalcedAsM] = ...
        obj.calcFastProp2(obj.data, trialInd, figInfo, ...
        bDiv2);
    snapnow; close all force
    % Plot these
    [fastPropFittedAsRecalc, bsAvgAsRecalc] = ...
        obj.plotPsychAs(obj.data, fastPropAsRecalc, trialInd, figInfo, ...
       bDiv2);
    snapnow; close all force
    % % Correct asyncs
    % TODO: Append recalced AsM to obj.data when this is added
    [PCCorAsMRecalc, PCCorOffRecalc] = ...
        obj.PCCorrectAs(obj.data, trialInd, figInfo, bDiv2); 
    snapnow; close all force
    
    % NOT YET SAVED PROPERLY_______________________________________________
    % Calculate fastProp based on recalculated AsM using paramters defined
    % in analysis set up (TODO) 
    % And using bins defined in analysis params (fParams.asParams.bDiv3) 
    figInfo.fnsAppend = [char(BehavAnalysis.BES(bDiv3)), 'Recalc1'];
    bDiv3 = obj.subjectParams.asParams.bDiv3;
    [fastPropAsRecalc, recalcedAsM] = ...
        obj.calcFastProp2(obj.data, trialInd, figInfo, ...
        bDiv3, obj.subjectParams.asParams);
    snapnow; close all force
    % Plot these
    [fastPropFittedAsRecalc, bsAvgAsRecalc] = ...
        obj.plotPsychAs(obj.data, fastPropAsRecalc, trialInd, figInfo, ...
       bDiv3);
    snapnow; close all force
    % % Correct asyncs
    % TODO: Append recalced AsM to obj.data when this is added
    [PCCorAsMRecalc, PCCorOffRecalc] = ...
        obj.PCCorrectAs(obj.data, trialInd, figInfo, bDiv3); 
    snapnow; close all force
    %______________________________________________________________________
    
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
    trialStats.fastPropFittedAsExp = fastPropFittedAsExp;
    trialStats.fastPropFittedAsRecalc = fastPropFittedAsRecalc;
    trialStats.bsAvg = bsAvg;
    trialStats.bsAvgAsExp = bsAvgAsExp;
    trialStats.bsAvgAsRecalc = bsAvgAsRecalc;
    trialStats.PCCor = PCCor;
    trialStats.PCCorAsMExp = PCCorAsMExp;
    trialStats.PCCorAsMRecalc = PCCorAsMRecalc;
    trialStats.PCCorOffAsMExp = PCCorOffExp;
    trialStats.PCCorOffAsMRecalc = PCCorOffRecalc;
    trialStats.RTsCI = RTsCI;
    trialStats.RTsV = RTsV;
    trialStats.raceStats = raceStats;
    
else
    % Save to stats structure
    trialStats.fastProp = NaN;
    trialStats.fastPropFitted = NaN;
    trialStats.fastPropFittedAsExp = NaN;
    trialStats.fastPropFittedAsRecalc = NaN;
    trialStats.bsAvg = NaN;
    trialStats.bsAvgAsExp = NaN;
    trialStats.bsAvgAsRecalc = NaN;
    trialStats.PCCor = NaN;
    trialStats.PCCorAsMExp = NaN;
    trialStats.PCCorAsMRecalc = NaN;
    trialStats.PCCorOffExp = NaN;
    trialStats.PCCorOffRecalc = NaN;
    trialStats.RTsCI = NaN;
    trialStats.RTsV = NaN;
    trialStats.raceStats = NaN;
    
end

% Save to object
obj.stats = trialStats;
