function obj = level10(obj)
close all force

% Level
l = 10;

% Training index - assume no training.
trInd = ones(height(obj.data),1);

% Set standard trialIdx based on parameters
trialIdx = obj.setTrialIdx(obj);

% Construct trialInd - not old name
trialInd = trInd & trialIdx;

% Get WID
obj.figInfo.WID = obj.session.WID{1,1};
% Get DID - If combo session, will contain more than one row (but just use
% first)
obj.figInfo.DID = obj.session.DID{1,1};

% Set file/folder string to use when saving graphs
figInfo = obj.prepDir(obj);

% Summary stats
obj.sumStats(obj.data, trialInd, l, figInfo)

% Check it's worth running
if sum(trialInd)>10
    
    fParams.asParams.bDiv = [0.1000 0.2500 0.4000];
    
    % Calculate fastProp
    fastProp = obj.calcFastProp(obj.data, trialInd, figInfo);
    snapnow; close all force
    
    % Explore asychrony metric and recalculate fastProp
    bDiv = fParams.asParams.bDiv;
    figInfo.fnsAppend = [char(BehavAnalysis.BES(bDiv)), 'Recalc0'];
    [fastPropAs, ~] = ...
        obj.calcFastProp2(obj.data, trialInd, figInfo, ...
        bDiv);
    snapnow; close all force
    % Plot these
    [fastPropFittedAs, bsAvgAs] = ...
        obj.plotPsychAs(obj.data, fastPropAs, trialInd, figInfo, ...
        bDiv);
    
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