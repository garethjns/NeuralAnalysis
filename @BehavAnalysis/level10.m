function obj = level10(obj)
close all force

% Level
l=10;

% Find unique DIDs
ds = [];
for d = 1:height(allData)
    if ~isempty(allData.DayID{d}) ...
            && ~strcmp(num2str(allData.DayID{d}), 'NaN')
        ds = [ds; allData.DayID(d)]; %#ok<AGROW>
    end
end
DIDs = unique(ds);

% Add "all", for summary
DIDs = ['All'; DIDs];
% DIDs = {'All'} % just do all for now - REMEBER TO REMOVE

for d=1:length(DIDs)
    
    DID = DIDs{d};
    switch DID
        case 'All'
            dayInd = ones(height(allData),1) == 1;
        otherwise
            dayInd = strcmp(allData.DayID, DID);
    end
    
    % WIDs used for this DID
    % See below
    
    % DateRange for this DID
    dateRange = [datestr(min(allData.DateNum(dayInd)));
        datestr(max(allData.DateNum(dayInd)))];
    % Don't need a dInd
    
    % Reconstruct trialInd spefically for level
    lInd = allData.Level==l;
    % dInd = dInd; % Unchanged
    tInd = ones(height(allData),1);
    % Centre reward trials
    if incCentreRewardTrials == 1
        % Use all trials
        crInd = ones(height(allData),1);
    else
        % Don't use trials where centre was rewarded
        crInd = allData.CentreReward==0;
    end
    % Correction trials
    if incCorTrials == 1
        % Use all trials
        corInd = ones(height(allData),1);
    else
        % Don't usecorrection trials
        corInd = allData.CorrectionTrial==0;
    end
    
    % Construct trialInd
    % (DayID, training, centre reward, level, correction trials)
    trialInd = dayInd & tInd & crInd & lInd & corInd;
    
    % WIDs used for this DID
    % May be more than 1 - will need to update this code when it is!
    switch DID
        case 'All'
            WID = 'All';
        otherwise
            WID = unique(trialData.WeekID(trialInd));
    end
    
    % Set file/folder string to use when saving grapsh
    figInfo.fns = [fPaths.fBehavAnalysisFolder, ...
        'Level', num2str(l), '\', ...
        DID, '\'];
    figInfo.titleAppend = ['Level', num2str(l), ', DID ', DID, ': '];
    figInfo.DID = DID;
    figInfo.WID = WID;
    if ~exist(figInfo.fns,'dir')
        mkdir(figInfo.fns);
    end
    
    % Summary stats
    sumStats(allData, trialInd, l, dateRange, figInfo)
    
    % Check it's worth running
    if sum(trialInd)>10
        
        % Calculate fastProp
        fastProp = calcFastProp(allData, trialInd, figInfo);
        snapnow; close all force
        
        % Explore asychrony metric and recalculate fastProp
        fastPropAs = ...
            calcFastProp2(allData, trialInd, figInfo, fParams.asParams.bDiv);
        snapnow; close all force
        
        % Plot performance and psych curves
        [fastPropFitted, bsAvg] = ...
            plotPsych(allData, fastProp, trialInd, figInfo); %#ok<ASGLU> % evaled
        snapnow; close all force
        
        % And async
        [fastPropFittedAs, bsAvgAs] = ...
            plotPsychAs(allData, fastPropAs, trialInd, figInfo, ...
            fParams.asParams.bDiv); %#ok<ASGLU> % evaled
        snapnow; close all force
        
        % % Correct
        PCCor = PCCorrect(allData, trialInd, figInfo);
        snapnow; close all force
        
        % % Correct asyncs
        [PCCorAsM, PCCorOff] = ...
            PCCorrectAs(allData, trialInd, figInfo, fParams); %#ok<ASGLU> % evaled
        
        % Plot RTs
        [RTsCI, RTsV] = ...
            plotRTs(allData, trialInd, figInfo); %#ok<ASGLU> % evaled
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
end