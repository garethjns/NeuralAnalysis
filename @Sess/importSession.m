function obj = importSession(obj)

% Load behavioural file

fMat = string(obj.session.BehavPath);
nTrials = obj.session.nTrials;
fData = open(fMat.char());

% Check some data was saved...
if length(fData.saveData)<2
    disp(['Skipping, empty file: ', fMat])
    return
end
% Check response is available
if isempty(fData.saveData{1,2}.response)
    disp(['Skipping, response missing: ', fMat])
    return
end
if ~isfield(fData.saveData{1,2}, 'box')
    % No data or no box is recorded, don't import
    disp('Skipping, unknown box')
    return
end

% If level 11 file, load seed2
clear seed2
if fData.saveData{2}.level == 11
    fn = fMat.extractBefore(obj.session.BehavFn) ...
        + obj.session.Subject ...
        + '_SEEDID2_' ...
        +  fData.saveData{2}.seedID2 ...
        + '.mat';
    seed2 = load(fn.char());
end

% Check box - not importing Dumbo
% Add WE later
switch obj.session.Box
    case 'Nellie'
    otherwise
        disp('Skipping, wrong box')
        % Do nothing with this file
        return
end

% Prepare empty table
data = obj.sessionTable(nTrials);

row = 0;
for f = 1:nTrials
    % Get cell with trial data
    trialData = fData.saveData{1,r};
    % Check it has data
    if isempty(trialData)
        continue
    else
        % Increment row
        row = row+1;
    end
    
    % Session
    data.SessionNum(row,1) = ...
        obj.session.SessionNum(1,1);
    
    % Neural info
    if obj.session.NeuralData
        data.NeuralData(row,1) = obj.session.NeuralData;
        data.LocalAvailTDT(row,1) = obj.session.LocalAvailTDT;
        data.LocalAvailMat(row,1) = obj.session.LocalAvailMat;
        data.BlockNum(row,1) = obj.session.BlockNum;
        data.BlockName{row,1} = obj.session.BlockName;
        data.fNeuralPathTDT{row,1} = obj.session.fNeuralPathTDT;
        % data.fNeuralPathMat(row,1) = obj.session.fNeuralPathMat;
        % data.EpochFile{row,1} = epochFile;
        data.analysisFile{row,1} = obj.session.AnalysisFile;
    else
       data.NeuralData(row,1) = obj.session.NeuralData;
    end
    
    % Add box
    data.Box{row,1} = trialData.box;
    
    % Add date
    data.DateNum(row,1) = obj.session.DateNum;
    
    % Add paths
    % HERE ******************************************
    data.fMatPath{row} = fMat;
    
    % Add stim
    data.aStim{row} = [];
    data.vStim{row} = [];
    if isfield(trialData, 'aStim')
        data.aStim{row}=trialData.aStim;
    else
        if isfield(trialData, 'stimRecord')
            try
                data.aStim{row} =...
                    trialData.stimRecord{1};
            end
        end
    end
    if isfield(trialData, 'vStim')
        data.vStim{row}=trialData.vStim;
    else
        if isfield(trialData, 'stimRecord')
            try
                data.vStim{row}=...
                    trialData.stimRecord{2};
            end
        end
    end
    
    % Level
    if isfield(trialData, 'level')
        data.Level(row)=trialData.level;
    else
        % Asume level 8
        data.Level(row)=8;
    end
    
    % TrainingFlag
    % TrainingGlag is 0 or 1 or inf for
    % [All, A, V, AVsync, AVasync, A bonus, V bouns, conflict]
    % NaN = TrainingFlag unknown, or session didn't inlcude this
    % TrialType
    if isfield(trialData, 'trainingFlag') ...
            && numel(trialData.trainingFlag) == 8
        data.TrainingFlag(row,:) = ...
            trialData.trainingFlag;
    else
        data.TrainingFlag(row,:) = NaN(1,8);
    end
    
    % RepeatMode
    if isfield(trialData, 'repeatMode')
        % data.RepeatMode(row) = 1;
        data.RepeatMode(row) = trialData.repeatMode;
        % If repeats are on, all modes active modes
        % were training
        aModes = [1, trialData.trialTypes];
        trainingFlag = NaN(1,8);
        trainingFlag(aModes) = 1;
        if isequaln(trainingFlag, ...
                trialData.trainingFlag)
            % Original training flag agrees with
            % estimated, so keep original
        else
            % Trainingflag in params appears wrong,
            % use the generated version
            data.TrainingFlag(row,:) = ...
                trainingFlag;
        end
        
    else
        % All were 0 before this param was added,
        % so if it's not
        % present, repeats were off
        % Not relevant to Nellie
        data.RepeatMode(row) = 0;
        % Leave trainingFlag as it was
    end
    
    % CorrectionTrial
    data.CorrectionTrial(row)=...
        trialData.correctionTrial;
    
    % Type
    if isfield(trialData, 'TT')
        % Trial type is recorded
        data.Type(row)=trialData.TT;
    else
        % Try and figure it out
        ty=[NaN, NaN];
        if isfield(trialData, 'soundOn')
            ty(1) = trialData.soundOn;
        end
        if isfield(trialData, 'lightOn')
            ty(2) = trialData.lightOn;
        end
        
        switch num2str(ty)
            case num2str([1 0]) % AO
                data.Type(row)=2;
            case num2str([0 1]) % VO
                data.Type(row)=3;
            case num2str([1 1]) % AV, must be sync in this case
                data.Type(row)=4;
            otherwise
                % Can't figure out type
                data.Type(row)=NaN;
        end
    end
    
    % nEvents
    if isstruct(data.aStim{row})
        data.nEventsA(row) = ...
            data.aStim{row}.nEvents;
    else
        data.nEventsA(row)=NaN;
    end
    if isstruct(data.vStim{row})
        data.nEventsV(row) = ...
            data.vStim{row}.nEvents;
    else
        data.nEventsV(row)=NaN;
    end
    
    % Check nEvents is the same for both modalities in
    % the 4 and 5 conditions
    if data.Type(row) == 4 || data.Type(row) == 5
        % MS trial
        if data.nEventsV(row) ...
                == data.nEventsA(row)
            % All is good
        else
            disp(['Fuck up, trial skipped. Type: ', ...
                num2str(data.Type(row))])
            % Set row back to previous values and
            % delete current row
            data(row,:) = [];
            row=row-1;
            % And bail out of this for loop
            continue
        end
    end
    
    % Side
    data.Side(row)=trialData.side;
    
    % Response
    if ~isempty(trialData.response)
        data.Response(row)=trialData.response;
    else
        data.Response(row)=NaN;
    end
    
    % Correct?
    if data.Response(row)==data.Side(row)
        data.Correct(row)=1;
    else
        data.Correct(row)=0;
    end
    
    % RT (relative)
    data.RT(row)= ...
        trialData.responseTime ...
        - trialData.startTrialTime;
    % NB on time outs, response time saved as -1 so
    % will get stupid values for these - just
    
    % Response Time (abs)
    data.ResponseTime(row) = trialData.responseTime;
    
    % StartTrialTime
    data.StartTrialTime(row) = ...
        trialData.startTrialTime;
    
    % Hold time
    data.HoldTime(row) = ...
        trialData.holdTime;
    
    % Session time
    data.SessionTime(row) = trialData.sessionTime;
    
    % tRec
    data.tRec(row) = trialData.tRec;
    
    % tStim
    data.tStim(row) = trialData.tStim;
    
    % Atten
    data.Atten(row) = trialData.atten;
    
    % CentreReward
    data.CentreReward(row) = trialData.centerReward;
    
    % humayra waz ere  (shut up gareth),....:igthf7965
    
    % stimEventDuration
    data.stimEventDuration(row)= ...
        trialData.stimEventDuration;
    
    % gap1
    data.gap1(row)=trialData.gap1;
    
    % gap2
    data.gap2(row)=trialData.gap2;
    
    % duration
    data.duration(row)=trialData.duration;
    
    % StartBuff
    data.startBuff(row)=trialData.startBuff;
    
    % endBuff
    data.endBuff(row)=trialData.endBuff;
    
    % cutOff
    data.cutOff(row)=trialData.cutOff;
    
    % aSyncOffset
    if data.Type(row) == 5
        data.aSyncOffset(row,1) = ...
            trialData.aStim.startBuff ...
            - trialData.vStim.startBuff;
        
        if trialData.level == 11
            data.aSyncOffset(row,1) = ...
                trialData.level11Offsets(trialData.AsM, [4, 6, 8, 12, 14, 16]==trialData.r);
        end
    end
    
    % aNoise
    if data.Type(row) == 2 ...
            || data.Type(row) == 4 ...
            || data.Type(row) == 5
        if isfield(trialData, 'aNoise')
            if numel(trialData.aNoise)== 1
                % One noise in params
                data.aNoise(row)=trialData.aNoise;
            else
                % Vector in params
                % Get used value from aStim/cfg
                data.aNoise(row)=...
                    trialData.aStim.noiseMag;
            end
            
        else
            % Not used in Nellie?
            if isfield(trialData, 'stimNoiseMag')
                data.aNoise(row)=...
                    trialData.stimNoiseMag;
            else
                data.vNoise(row)=NaN;
            end
        end
    end
    
    
    % vNoise & vMulti
    if data.Type(row) == 3 ...
            || data.Type(row) == 4 ...
            || data.Type(row) == 5
        if isfield(trialData, 'vNoise')
            if numel(trialData.vNoise)== 1
                % One noise in params
                data.vNoise(row)=trialData.vNoise;
            else
                % Vector in params
                % Get used value from aStim/cfg
                data.vNoise(row)=...
                    trialData.vStim.noiseMag;
            end
        else
            % Not used in Nellie?
            if isfield(trialData, 'stimNoise')
                data.vNoise(row)=...
                    trialData.stimNoiseMag;
            else
                data.vNoise(row)=NaN;
            end
        end
        
        % vMulti
        % Changed to be inc in gf, if available, this
        % controlled light brightness (not gf.atten)
        if isfield(trialData, 'vMultiTrial')
            data.vMulti(row) = ...
                trialData.vMultiTrial;
        end
    end
    % fName
    data.fName{row} = fName;
    
    % fID
    data.fID{row} = fID;
    
    % Level 8 stuff
    if data.Level(row)==8
    end
    
    % Level 9 stuff
    if data.Level(row)==9
    end
    
    % Level 9, 10, 11 stuff
    data.WeekID{row,1}=NaN;
    if data.Level(row)==9 ...
            || data.Level(row)==10 ...
            || data.Level(row)==11
        if isfield(trialData,'weekID')
            data.WeekID{row} = trialData.weekID;
        else
            data.WeekID{row} = 'Missing';
        end
    end
    
    % Level 10 and 11 stuff
    data.DayID{row,1}=NaN;
    if data.Level(row)==10 || data.Level(row)==11
        if isfield(trialData,'dayID')
            data.DayID{row} = trialData.dayID;
        else
            data.DayID{row} = 'Missing';
        end
    end
    
    % Level 10 and 11 stuff
    data.SeedID(row,1)=NaN;
    if data.Level(row)==10 || data.Level(row)==11
        if isfield(trialData,'seedID')
            data.SeedID(row) = trialData.seedID;
        else
            data.SeedID(row) = 'Missing';
        end
    end
    
    
    % Level 11 stuff
    data.AsMActualLog(row,1) = NaN;
    data.AsM(row,1) = NaN;
    data.ReqAsMs{row,1} = NaN;
    if data.Level(row)==11
        data.ReqAsMs{row,1} = trialData.targetAsMs;
        if trialData.TT == 5
            data.AsMActualLog(row,1) = ...
                trialData.AsMActualLog;
            data.AsM(row,1) = trialData.AsM;
            
            % Loaded before row loop
            data.AsyncParams{row,1} = ...
                seed2.finalReport;
        end
    end
    
    if mod(row,100)==0
        disp(['Added ', num2str(row), ' trials...'])
    end
end