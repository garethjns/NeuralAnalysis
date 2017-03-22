function obj = level11(obj)
% Level 11 Analyisis - in progress
% DIDs not compiled yet

close all force

% Level
l = 11;
% Date
d = datestr(obj.data.DateNum(1));
% Session num
s = obj.data.SessionNum(1);

% Training index
% Assume training flag based on RepeatMode for now
% All should be the same
trInd = ~obj.data.RepeatMode;

% Centre reward trials
if obj.subjectParams.behav.incCentreRewardTrials == 1
    % Use all trials
    crInd = ones(height(obj.data),1);
else
    % Don't use trials where centre was rewarded
    crInd = obj.data.CentreReward==0;
end

% Correction trials
if obj.subjectParams.behav.incCorrectionTrials == 1
    % Use all trials
    corInd = ones(height(obj.data),1);
else
    % Don't usecorrection trials
    corInd = obj.data.CorrectionTrial==0;
end

% Construct trialInd
% (DayID, training, centre reward, level, correction trials)
trialInd = trInd & crInd & corInd;


% Set file/folder string to use when saving graphs
% For invidual sessions, use date and session number for sub folder.
figInfo = obj.figInfo;
figInfo.fns = [obj.subjectPaths.behav.individualSessAnalysis, ...
    'Level', num2str(l), '\', ...
    d, '_', ...
    obj.session.Time{1}, '_', ... 
    num2str(s), '\'];
figInfo.titleAppend = ['Level', num2str(l), 'Level', num2str(l), '\', ...
    d, '_', num2str(s), '\'];

% Delete any previous analysis
if exist(figInfo.fns,'dir')
   rmdir(figInfo.fns, 's')
end
mkdir(figInfo.fns);
  
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
    fParams.asParams.bDivL11 = obj.data(trialInd,:).ReqAsMs{1};
    fastPropAs = ...
        obj.calcFastProp2(obj.data, trialInd, figInfo, ...
        fParams.asParams.bDivL11);
    snapnow; close all force
    
    % Plot performance and psych curves
    [fastPropFitted, bsAvg] = ...
        obj.plotPsych(obj.data, fastProp, trialInd, figInfo); 
    snapnow; close all force
    
    % And async
    [fastPropFittedAs, bsAvgAs] = ...
        obj.plotPsychAs(obj.data, fastPropAs, trialInd, figInfo, ...
        fParams.asParams.bDivL11);
    snapnow; close all force
    
    % % Correct
    PCCor = obj.PCCorrect(obj.data, trialInd, figInfo);
    snapnow; close all force
    
    % % Correct asyncs
    [PCCorAsM, PCCorOff] = ...
        obj.PCCorrectAs(obj.data, trialInd, figInfo, fParams); 
    
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
obj.Stats = trialStats;
