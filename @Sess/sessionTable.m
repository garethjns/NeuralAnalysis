function emptyTable = sessionTable(nTrials)
% Create and return empty table of standard arrangement for all levels

% Create table
varNames = { ...
    NaN(nTrials,1), 'TrialNumber', ''; ... Added
    NaN(nTrials,1), 'Level', ''; ... Added
    cell(nTrials,1), 'Box', ''; ... Added
    NaN(nTrials,1), 'SessionNum', ''; ... Added
    inf(nTrials,8), 'TrainingFlag', ''; ...
    NaN(nTrials,1), 'RepeatMode', ''; ...
    NaN(nTrials,1), 'DateNum', ''; ... Added
    NaN(nTrials,1), 'CorrectionTrial', ''; ... Added
    NaN(nTrials,1), 'Type', ''; ... Added
    NaN(nTrials,1), 'AsyncMetric', 'Rated asynchrony, on import'; ...
    cell(nTrials,1), 'AysncParams', 'Params used to calc asynchrony metric'; ...
    NaN(nTrials,1), 'nEventsA', ''; ... Added
    NaN(nTrials,1), 'nEventsV', ''; ... Added
    NaN(nTrials,1), 'Side', ''; ... Added
    NaN(nTrials,1), 'Response', ''; ... Added
    NaN(nTrials,1), 'Correct', ''; ... Added
    NaN(nTrials,1), 'RT', ''; ...
    NaN(nTrials,1), 'ResponseTime', ''; ... Added
    NaN(nTrials,1), 'StartTime', ''; ...
    NaN(nTrials,1), 'StartTrialTime', ''; ...
    NaN(nTrials,1), 'SessionTime', ''; ...
    NaN(nTrials,1), 'HoldTime', ''; ...
    NaN(nTrials,1), 'tStim', ''; ...
    NaN(nTrials,1), 'tRec', ''; ...
    NaN(nTrials,1), 'Atten', ''; ... Added
    NaN(nTrials,1), 'CentreReward', ''; ... Added
    NaN(nTrials,1), 'stimEventDuration', ''; ... Added
    NaN(nTrials,1), 'gap1', ''; ... Added
    NaN(nTrials,1), 'gap2', ''; ... Added
    NaN(nTrials,1), 'duration', ''; ... Added
    NaN(nTrials,1), 'startBuff', ''; ... Added
    NaN(nTrials,1), 'endBuff', ''; ... Added
    NaN(nTrials,1), 'cutOff', ''; ... Added
    NaN(nTrials,1), 'aSyncOffset' ''; ... Added
    NaN(nTrials,1), 'vMulti', ''; ... Added
    NaN(nTrials,1), 'aNoise', ''; ... Added
    NaN(nTrials,1), 'vNoise', ''; ... Added
    NaN(nTrials,1), 'aTargetThresh', ''; ...
    NaN(nTrials,1), 'vTargetThresh', ''; ...
    cell(nTrials,1), 'aStim', ''; ... Added
    cell(nTrials,1), 'vStim', ''; ... Added
    cell(nTrials,1), 'fName' ''; ... Added
    cell(nTrials,1), 'fID', ''; ... Added
    cell(nTrials,1), 'fMatPath', ''; ... Added
    cell(nTrials,1), 'fTxtPath', ''; ... Added
    NaN(nTrials,1), 'Neural', ''; ...  Neural data available?
    NaN(nTrials,1), 'LocalAvailTDT', ''; ... And locally in tank?
    NaN(nTrials,1), 'LocalAvailMat', ''; ... And/or in .mat?
    NaN(nTrials,1), 'BlockNum', ''; ... Block 7-3 = 73
    cell(nTrials,1), 'BlockName', ''; ... if available
    cell(nTrials,1), 'fNeuralPathTDT', ''; ... if available
    cell(nTrials,1), 'fNeuralPathMat', ''; ... if available
    cell(nTrials,1), 'EpochFile', ''; ... if available
    cell(nTrials,1), 'AnalysisFile', ''; ... if available
    cell(nTrials,1), 'WeekID', ''; ... Level 9 and 10 and 11
    cell(nTrials,1), 'ThreshPath', ''; ... Level 9 and 10
    cell(nTrials,1), 'DayID', ''; ... Level 10 and 11
    NaN(nTrials,1), 'SeedID' ''; ... Level 10 and 11
    cell(nTrials,1), 'ReqAsMs', 'The AsMs that were requested'; ... Level 11
    NaN(nTrials,1), 'AsM', 'gf.AsM'; ... Level 11... Offset
    NaN(nTrials,1), 'AsMActualLog', 'gf.AsMActualLog, from experiment'; ... Level 11
    };

emptyTable = table(varNames{:,1});
emptyTable.Properties.VariableNames = varNames(:,2);
emptyTable.Properties.VariableDescriptions = varNames(:,3);

% Suppress warning about default row contents
warning('off', 'MATLAB:table:RowsAddedExistingVars');
warning('off','MATLAB:table:RowsAddedNewVars');
