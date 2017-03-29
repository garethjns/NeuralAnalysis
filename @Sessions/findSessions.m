function allData = findSessions(obj, sub)
% Compile list of all data collection sessions for each subject
% Loads each file to calculate basic performance
% Dumps <10 trial sessions at end (maintains numbering order)
% Return as table

%% Set paths and params
% Reusing older code - just set here to save changing throughout.

fName = sub.subject;
task = sub.task;
box = sub.box;
fID = sub.fID;

fNeuralFolder = sub.paths.neural.TDTRaw;
fNeuralPathMat = sub.paths.neural.extracted;
behavPath = sub.paths.behav.data;
% Make folder for extracted neural data if it doesn't exist already
try
    if ~exist(fNeuralPathMat, 'dir')
        mkdir(fNeuralPathMat);
    end
end

tic

% Try and load existing data set if requested

%% Import

% Go to behavioural data directory and find how many sessions exist
% Find sessions for selected levels
sessions = [];
for l = 1:length(sub.levels)
    
    lv = sub.levels(l);
    s = [behavPath, '*level', num2str(lv), '*_', box, '_*.mat'];
    newSesh = dir(s);
    sessions = [sessions; newSesh]; %#ok<AGROW>
    
    disp(['Including level ', num2str(lv), ...
        ': ', num2str(length(newSesh)), ' sessions'])
end

% Preallocate output table
nFiles = length(sessions);
allData = obj.sessionsTable(nFiles);

% Work out number of expected neural .mat files per block after extraction
% Should be sum(EvIDs*nCchans)
nMats = 0;
for evs=1:length(sub.params.extractEvIDs)
    nMats = nMats+ length(sub.params.extractEvIDs{evs}{2});
end

% Start importing
row = 0;
for s = 1:length(sessions) % For each session
    clear fData
    row = row+1;
    
    % Add data from sub object (that's not in exp file)
    allData.fID{row,1} = sub.fID;
    allData.Subject{row,1} = sub.subject;
    
    % Behav path
    fMat = sessions(s).name;
    disp(['Adding session ' num2str(s), '/', num2str(length(sessions)), ...
        ': ', fMat])
    allData.BehavPath{row,1} = [behavPath, fMat];
    allData.BehavFn{row,1} = fMat;
    
    % Level
    try
        fData = open([behavPath, fMat]);
        lv = fData.saveData{1,2}.level;
        allData.Level(row,1) = lv;
    catch
        % level is missing from first level 8s, other levels should have it
        % set
        allData.Level(row,1) = 8;
    end
    
    fMat = string(fMat);
    
    % DateNum, Date
    % Get from file name, not modified time. First 10 chars.
    allData.DateNum(row,1) = datenum(fMat.extractBefore(' ').char()...
        ,'dd_mm_yyyy');
    allData.Date{row} = datestr(allData.DateNum(row,1));
    
    % Get time from filename, not modified date
    % ts = datestr(sessions(s).datenum);
    
    tString = fMat.extractBetween([fName, ' '], ' ');
    
    % Convert hour to double
    ts = tString.extractBefore('_').double();
    if ts < 13
        allData.Time{row} = 'AM';
    else
        allData.Time{row} = 'PM';
    end
    
    % Subject
    allData.Subject{row} = fName;
    
    % Task
    allData.Task{row} = task;
    
    % Box
    allData.Box{row} = box;
    
    % Paths
    clear nameInd s ndA blockNum blockName fNeuralPathTDT ndALTDT ...
        dnALMAt
    
    % Look for work "Block" in file name
    blockAvail = fMat.contains('Block');
    if  blockAvail
        % There's a reference to blockname in filename
        % There is neural data available somewhere
        % allData.Neural = 1
        ndA = 1;
        
        % Remove '-' from filename
        % Get last chars (after block) and before .mat
        % = BlockNumber
        blockNum = ...
            fMat.replace('-', '').extractBetween('Block', '.mat').double();
        % Goes in allData.BlockNum
        
        % allData.BlockName
        blockName = ...
            fMat.extractBetween(fMat.extractBefore('Block'), '.mat').char();
        
        % This will go in allData.fNeuralPathTDT
        fNeuralPathTDT = fNeuralFolder(1:end-1); % Remove '\' or TDT will
        % fail to open tank
        % And is this data available locally in tank?
        % allData.LocalAvailTDT
        ndALTDT = exist([fNeuralPathTDT, '\', blockName], ...
            'dir')==7;
        
        % This will go in allData.fNeuralPathMat
        % fNeuralPathMat = [fNeuralFolder, fMat(nameInd:end)];
        fNeuralPathMat2 = [fNeuralPathMat, sub.subject, ...
            '_', blockName];
        % And/or in .mat?
        ndALMat = exist(fNeuralPathMat2, 'file')==2;
        
        % Save
        allData.NeuralData(row,1) = ndA;
        allData.LocalAvailTDT(row,1) = ndALTDT;
        allData.LocalAvailMat(row,1) = ndALMat;
        allData.BlockNum(row,1) = blockNum;
        allData.BlockName{row} = blockName;
        allData.fNeuralPathTDT{row} = fNeuralPathTDT;
        
        % Assume cables not flipped unless listed here
        % Block 10-159 cables flipped
        if blockNum == 10159
            allData.FlipCables(row,1) = 1;
        end
       
        % And flip list of file names - removed, handle later with neural
        % data
        % if allData.FlipCables(row,1) == 1
        %     % Cable flipped, so flip BB_2 and BB_3
        %     tmp = allData.fNeuralPathMats(row, :);
        %     tmp = [tmp(17:32), tmp(1:16), tmp(33:end)];
        %     allData.fNeuralPathMats(row, :) = tmp;
        % else
        % end
        
        % Paths for PrePro files (filt and epoch)
        allData.PreProEpoch{row} = [sub.paths.neural.epoched, ...
            allData.BlockName{row}, '\'];
        allData.PreProFilt{row} =  [sub.paths.neural.filtered, ...
            allData.BlockName{row}, '\'];
        allData.Spikes{row} =  [sub.paths.neural.spikes, ...
            allData.BlockName{row}, '\'];
        % And analysis file - Not using yet
        % allData.AnalysisFile{row} = [sub.paths.neural.PP, ...
        %     allData.BlockName{row}, '_Analysis.mat'];
        
        % Assume cables were plugged in correct way around, for now
        allData.FlipCables(row,1) = 0;
        
    end
    
    
    % Following require information from behavioural file *************
    try
        % Load file
        fData = open([behavPath, fMat.char()]);
        
        % nTrials
        n = length(fData.saveData);
        allData.nTrials(row,1) = n-1;
        
        % Import if more than n trials avaiable
        % Properly applied at end
        if n > 1
            % Calculate correct (non-correction)
            c = NaN(n,5);
            for t=1:n
                if ~isempty(fData.saveData{1,t})
                    try % What if a field is missing? ...
                        for v = 2:5 % For each type
                            if fData.saveData{1,t}.correctionTrial == 0 ...
                                    && fData.saveData{1,t}.TT==v
                                c(t,v)= ...
                                    fData.saveData{1,t}.response == ...
                                    fData.saveData{1,t}.side;
                            end
                        end
                    catch
                        % ... It's left as a NaN
                    end
                end
            end
            
            % For all data (perf 1)
            % if any column contains a "correct" mark overall column as
            % correct
            c(any(c')',1) = 1;
            % Can't tell NaNs from wrong here, so count correct...
            n2 = sum(c(:,1));
            
            filePerfs = nanmean(c)*100;
            % And just average individal mod perf here
            allData.Perf1(row,1) = nanmean(filePerfs(2:5));
            allData.Perf2(row,1) = filePerfs(2);
            allData.Perf3(row,1) = filePerfs(3);
            allData.Perf4(row,1) = filePerfs(4);
            allData.Perf5(row,1) = filePerfs(5);
            
            allData.nTrials2(row,1) = n2;
            
        else
            allData.Perf1(row,1) = NaN;
            allData.nTrials2(row,1) = NaN;
        end
        
        % If perf is NaN, mark bad
        if isnan(allData.Perf1(row,1))
            allData.Good(row,1) = 0;
        else
            allData.Good(row,1) = 1;
        end
        
        try % Rates
            r = [fData.saveData{1,2}.nEventsSlow,...
                fData.saveData{1,2}.nEventsFast];
            allData.Rates{row} = r;
        catch
            % Leave empty
        end
        
        try % Types
            ts = fData.saveData{1,2}.trialTypes;
            allData.Types{row} = ts;
        catch
            % Leave empty
        end
        
        try % tFlag
            tFlag = nansum(fData.saveData{1,2}.trainingFlag)>0;
            allData.Training(row,1) = tFlag;
        catch
            % Leave empty
        end
        
        % Atten range
        allData.AttenRange{row} = fData.saveData{1,2}.attenRange;
        
        % Hold range
        allData.HoldRange{row} = fData.saveData{1,2}.holdRange;
        
        % Level 9 and 10 stuff - WID
        allData.WID{row,1} = '';
        if allData.Level(row)==9 || allData.Level(row)==10
            if isfield(fData.saveData{1,2},'weekID')
                allData.WID{row} = fData.saveData{1,2}.weekID;
            else
                allData.WID{row} = 'Missing';
            end
        end
        
        % Level 10 stuff - DID
        allData.DID{row,1} = '';
        if allData.Level(row)==10
            if isfield(fData.saveData{1,2},'dayID')
                allData.DID{row} = fData.saveData{1,2}.dayID;
            else
                allData.DID{row} = 'Missing';
            end
        end
        
        % Level 10 and 11 stuff - SID
        allData.SID{row,1}='';
        if allData.Level(row)==10 || allData.Level(row)==11
            if isfield(fData.saveData{1,2},'seedID')
                allData.SID{row} = fData.saveData{1,2}.seedID;
            else
                allData.SID{row} = 'Missing';
            end
        end
        
        % Level 11 stuff - AsM (sID2, asm ID)
        % Not added yet
        
        
        % Length of imported trials now known allData.nTrials
        if blockAvail % this is a check to see if "Block" in file name
            allData.OKMats{row} = ones(allData.nTrials(row), 32);
        else
            allData.OKMats{row} = zeros(allData.nTrials(row), 32);
        end
        
        
    end
    
end   

%% Tidy

% Sort in to date order
allData = sortrows(allData, 'DateNum');
allData.SessionNum(1:height(allData),1) = 1:height(allData);

bs = allData.nTrials<10;
allData = allData(~bs,:);
disp(['Dumped ', num2str(sum(bs)), ' sessions'])
 