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
figInfo.fns = [obj.subjectPaths.individualSessAnalysis, ...
    'Level', num2str(l), '\', ...
    d, '_', num2str(s), '\'];
figInfo.titleAppend = ['Level', num2str(l), 'Level', num2str(l), '\', ...
    d, '_', num2str(s), '\'];

% *************************************************************************
% HERE ********************************************************************
% *************************************************************************

if ~exist(figInfo.fns,'dir')
    mkdir(figInfo.fns);
end

% Summary stats
sumStats(obj.data, trialInd, l, dateRange, figInfo)

% Check it's worth running
if sum(trialInd)>20
    
    % Calculate fastProp
    fastProp = calcFastProp(obj.data, trialInd, figInfo);
    snapnow; close all force
    
    % Explore asychrony metric and recalculate fastProp
    % In level 11 AsMs are requested, so set fParams.asParams.bDiv
    % Eg. finalReport.targetAsMs: [0.1000 0.2500 0.4000]
    % to something sensible
    % ROUGH
    fParams.asParams.bDivL11 = obj.data(trialInd,:).ReqAsMs{1};
    fastPropAs = ...
        calcFastProp2(obj.data, trialInd, figInfo, fParams.asParams.bDivL11);
    snapnow; close all force
    
    % Plot performance and psych curves
    [fastPropFitted, bsAvg] = ...
        plotPsych(obj.data, fastProp, trialInd, figInfo); %#ok<ASGLU> % evaled
    snapnow; close all force
    
    % And async
    [fastPropFittedAs, bsAvgAs] = ...
        plotPsychAs(obj.data, fastPropAs, trialInd, figInfo, ...
        fParams.asParams.bDiv); %#ok<ASGLU> % evaled
    snapnow; close all force
    
    % % Correct
    PCCor = PCCorrect(obj.data, trialInd, figInfo);
    snapnow; close all force
    
    % % Correct asyncs
    [PCCorAsM, PCCorOff] = ...
        PCCorrectAs(obj.data, trialInd, figInfo, fParams); %#ok<ASGLU> % evaled
    
    % Plot RTs
    [RTsCI, RTsV] = ...
        plotRTs(obj.data, trialInd, figInfo); %#ok<ASGLU> % evaled
    snapnow; close all force
    
    % Run race model
    try
        raceStats=runRace(RTsV.data);
        snapnow; close all force
    catch
        raceStats = NaN;
    end
    
    % Save to stats structure
    eval(['trialStats.Level', num2str(l), 'DID', DID, ...
        '.fastProp=fastProp;']);
    eval(['trialStats.Level', num2str(l), 'DID', DID, ...
        '.fastPropFitted=fastPropFitted;']);
    eval(['trialStats.Level', num2str(l), 'DID', DID, ...
        '.fastPropFittedAs=fastPropFittedAs;']);
    eval(['trialStats.Level', num2str(l), 'DID', DID, ...
        '.bsAvg=bsAvg;']);
    eval(['trialStats.Level', num2str(l), 'DID', DID, ...
        '.bsAvgAs=bsAvgAs;']);
    eval(['trialStats.Level', num2str(l), 'DID', DID, ...
        '.PCCor=PCCor;']);
    eval(['trialStats.Level', num2str(l), 'DID', DID, ...
        '.PCCorAsM=PCCorAsM;']);
    eval(['trialStats.Level', num2str(l), 'DID', DID, ...
        '.PCCorOff=PCCorOff;']);
    eval(['trialStats.Level', num2str(l), 'DID', DID, ...
        '.RTsCI=RTsCI;']);
    eval(['trialStats.Level', num2str(l), 'DID', DID, ...
        '.RTsV=RTsV;']);
    eval(['trialStats.Level', num2str(l), 'DID', DID, ...
        '.RTsV.raceStats=raceStats;']);
else
    disp(['Not running level ', num2str(l), ...
        ' analysis, n to low in date range']);
    % Save NaNs to stats structure
    eval(['trialStats.Level', num2str(l), 'DID', DID, ...
        '.fastProp=NaN;']);
    eval(['trialStats.Level', num2str(l), 'DID', DID, ...
        '.fastPropFitted=NaN;']);
    eval(['trialStats.Level', num2str(l), 'DID', DID, ...
        '.fastPropFittedAs=NaN;']);
    eval(['trialStats.Level', num2str(l), 'DID', DID, ...
        '.bsAvg=NaN;']);
    eval(['trialStats.Level', num2str(l), 'DID', DID, ...
        '.bsAvgAs=NaN;']);
    eval(['trialStats.Level', num2str(l), 'DID', DID, ...
        '.PCCor=NaN;']);
    eval(['trialStats.Level', num2str(l), 'DID', DID, ...
        '.PCCorAsM=NaN;']);
    eval(['trialStats.Level', num2str(l), 'DID', DID, ...
        '.PCCorOff=NaN;']);
    eval(['trialStats.Level', num2str(l), 'DID', DID, ...
        '.RTsCI=NaN;']);
    eval(['trialStats.Level', num2str(l), 'DID', DID, ...
        '.RTsV=NaN;']);
    %         eval(['trialStats.Level', num2str(l), 'DID', DID, ...
    %             '.RTsV.raceStats=NaN;']);
end
clear fastProp fastPropFitted bsAvg PCCor RTsCI RTsV raceStats
figInfo = rmfield(figInfo, 'WID');
figInfo = rmfield(figInfo, 'DID');
