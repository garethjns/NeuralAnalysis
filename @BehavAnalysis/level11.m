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
    % Plot performance and psych curves
    [fastPropFitted, bsAvg] = ...
        obj.plotPsych(obj.data, fastProp, trialInd, figInfo);
    %snapnow; close all force
    % % Correct
    PCCor = obj.PCCorrect(obj.data, trialInd, figInfo);
    snapnow; close all force
    
    % ASM 1
    % Calculate fastProp for AsM as calculated during seed generation
    % - depends on params used then. Use the originally requested AsMs as
    % bins
    % This is in .AsMActualLog / .ReqAsMs
    bDiv = obj.data(trialInd,:).ReqAsMs{1};
    figInfo.fnsAppend = [char(BehavAnalysis.BES(bDiv)), 'Recalc0'];
    [fastPropAsM1, ~] = ...
        obj.calcFastProp2(obj.data, trialInd, figInfo, ...
        bDiv);
    snapnow; close all force
    % Plot these
    [fastPropFittedAsM1, bsAvgAsM1] = ...
        obj.plotPsychAs(obj.data, fastPropAsAsM1, trialInd, figInfo, ...
        bDiv);
    snapnow; close all force
    % % Correct asyncs
    [PCCorAsM1, PCCorOffAsM1] = ...
        obj.PCCorrectAs(obj.data, trialInd, figInfo, bDiv); 
    snapnow; close all force
    
    % ASM2
    % Calculate fastProp using using bins defined in analysis params
    % (fParams.asParams.bDiv2) 
    bDiv2 = obj.subjectParams.asParams.bDiv2;
    figInfo.fnsAppend = [char(BehavAnalysis.BES(bDiv2)), 'Recalc0'];
    [fastPropAsM2, ~] = ...
        obj.calcFastProp2(obj.data, trialInd, figInfo, ...
        bDiv2);
    snapnow; close all force
    % Plot these
    [fastPropFittedAsM2, bsAvgAsM2] = ...
        obj.plotPsychAs(obj.data, fastPropAsM2, trialInd, figInfo, ...
       bDiv2);
    snapnow; close all force
    % % Correct asyncs
    % TODO: Append recalced AsM to obj.data when this is added
    [PCCorAsM2, PCCorOffAsM2] = ...
        obj.PCCorrectAs(obj.data, trialInd, figInfo, bDiv2); 
    snapnow; close all force
    
    % ASM3
    % Calculate fastProp based on recalculated AsM using paramters defined
    % in analysis set up (TODO) 
    % And using bins defined in analysis params (fParams.asParams.bDiv3) 
    bDiv3 = obj.subjectParams.asParams.bDiv3;
    figInfo.fnsAppend = [char(BehavAnalysis.BES(bDiv3)), 'Recalc1'];
    [fastPropAsM3, recalcedAsM3] = ...
        obj.calcFastProp2(obj.data, trialInd, figInfo, ...
        bDiv3, obj.subjectParams.asParams);
    snapnow; close all force
    % Plot these
    [fastPropFittedAsM3, bsAvgAsM3] = ...
        obj.plotPsychAs(obj.data, fastPropAsM3, trialInd, figInfo, ...
       bDiv3);
    snapnow; close all force
    % % Correct asyncs
    % TODO: Append recalced AsM to obj.data when this is added
    [PCCorAsM3, PCCorOffAsM3] = ...
        obj.PCCorrectAs(obj.data, trialInd, figInfo, bDiv3); 
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
    
    trialStats.fastPropAsM1 = fastPropAsM1;
    trialStats.fastPropAsM2 = fastPropAsM2;
    trialStats.fastPropAsM3 = fastPropAsM3;
    trialStats.fastPropFittedAsM1 = fastPropFittedAsM1;
    trialStats.fastPropFittedAsM2 = fastPropFittedAsM2;
    trialStats.fastPropFittedAsM3 = fastPropFittedAsM3;
    trialStats.bsAvgAsM1 = bsAvgAsM1;
    trialStats.bsAvgAsM2 = bsAvgAsM2;
    trialStats.bsAvgAsM3 = bsAvgAsM3;
    trialStats.recalcedAsM3 = recalcedAsM3;
    trialStats.PCCorAsM1 = PCCorAsM1;
    trialStats.PCCorAsM2 = PCCorAsM2;
    trialStats.PCCorAsM3 = PCCorAsM3;
    trialStats.PCCorOffAsM1 = PCCorOffAsM1;
    trialStats.PCCorOffAsM2 = PCCorOffAsM2;
    trialStats.PCCorOffAsM3 = PCCorOffAsM3;

else
    % Save to stats structure
    trialStats.fastProp = NaN;
    trialStats.fastPropFitted = NaN;
    trialStats.bsAvg = NaN;
    trialStats.PCCor = NaN;
    trialStats.RTsCI = NaN;
    trialStats.RTsV = NaN;
    trialStats.raceStats = NaN;
    
    trialStats.fastPropAsM1 = NaN;
    trialStats.fastPropAsM2 = NaN;
    trialStats.fastPropAsM3 = NaN;
    trialStats.fastPropFittedAsM1 = NaN;
    trialStats.fastPropFittedAsM2 = NaN;
    trialStats.fastPropFittedAsM3 = NaN;
    trialStats.bsAvgAsM1 = NaN;
    trialStats.bsAvgAsM2 = NaN;
    trialStats.bsAvgAsM3 = NaN;
    trialStats.PCCorAsM1 = NaN;
    trialStats.PCCorAsM2 = NaN;
    trialStats.PCCorAsM3 = NaN;
    trialStats.PCCorOffAsM1 = NaN;
    trialStats.PCCorOffAsM2 = NaN;
    trialStats.PCCorOffAsM3 = NaN;
    
end

% Save to object
obj.stats = trialStats;
