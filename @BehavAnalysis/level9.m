function obj = level9(obj)
close all force

% Level
l=9;

% Find unique WIDs
ws = [];
for w = 1:height(allData)
    if ~isempty(allData.WeekID{w}) ...
            && ~strcmp(num2str(allData.WeekID{w}), 'NaN')
        ws = [ws; allData.WeekID(w)]; %#ok<AGROW>
    end
end
WIDs = unique(ws);

if any(fParams.level==l)
    for w = 1:length(WIDs)
        
        WID = WIDs{w};
        wInd = strcmp(allData.WeekID, WID);
        
        % DateRange for this WID
        dateRange = [datestr(min(allData.DateNum(wInd)));
            datestr(max(allData.DateNum(wInd)))];
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
        % (WeekID, training, centre reward, level, correction trials)
        trialInd = wInd & tInd & crInd & lInd & corInd;
        
        % Set file/folder string to use when saving grapsh
        figInfo.fns = [fPaths.fBehavAnalysisFolder, ...
            'Level', num2str(l), '\', ...
            WID, '\'];
        figInfo.WID = WID;
        figInfo.titleAppend = ['Level', num2str(l), ', WID ', WID, ': '];
        if ~exist(figInfo.fns,'dir')
            mkdir(figInfo.fns);
        end
        
        % Summary stats
        sumStats(allData, trialInd, l, dateRange, figInfo)
        
        % Check it's worth running
        if sum(trialInd)>10
            
            % Overall analysis
            % Calculate overall fastProp - don't do for individual levels
            fastProp = calcFastProp(allData, trialInd, figInfo);
            snapnow; close all force
            
            % Plot performance and psych curves
            [fastPropFitted, bsAvg] = ...
                plotPsych(allData, fastProp, trialInd, figInfo); %#ok<ASGLU>
            snapnow; close all force
            
            % Correct
            PCCor = PCCorrect(allData, trialInd, figInfo);
            snapnow; close all force
            
            % Plot RTs
            [RTsCI, RTsV] = ...
                plotRTs(allData, trialInd, figInfo); %#ok<ASGLU>
            snapnow; close all force
            
            % Run race model
            % raceStats=runRace(RTsV.data); %#ok<NASGU>
            % No race model in level 9 - unisensory
            
            % Per-noise level analysis
            % Calculate threshold
            thresh = threshold(allData, trialInd, figInfo);
            snapnow; close all force
            
            % Save to stats structure
            eval(['trialStats.Level', num2str(l), 'WID', WID, ...
                '.fastProp=fastProp;']);
            eval(['trialStats.Level', num2str(l), 'WID', WID, ...
                '.fastPropFitted=fastPropFitted;']);
            eval(['trialStats.Level', num2str(l), 'WID', WID, ...
                '.bsAvg=bsAvg;']);
            eval(['trialStats.Level', num2str(l), 'WID', WID, ...
                '.PCCor=PCCor;']);
            eval(['trialStats.Level', num2str(l), 'WID', WID, ...
                '.RTsCI=RTsCI;']);
            eval(['trialStats.Level', num2str(l), 'WID', WID, ...
                '.RTsV=RTsV;']);
            eval(['trialStats.Level', num2str(l), 'WID', WID, ...
                '.RTsV.raceStats=NaN;']);
            eval(['trialStats.Level', num2str(l), 'WID', WID, ...
                '.thresh=thresh;']);
        else
            disp(['Not running level ', num2str(l), ...
                ' analysis, n to low in date range']);
            % Save NaNs to stats structure
            eval(['trialStats.Level', num2str(l), 'WID', WID, ...
                '.fastProp=NaN;']);
            eval(['trialStats.Level', num2str(l), 'WID', WID, ...
                '.fastPropFitted=NaN;']);
            eval(['trialStats.Level', num2str(l), 'WID', WID, ...
                '.bsAvg=NaN;']);
            eval(['trialStats.Level', num2str(l), 'WID', WID, ...
                '.PCCor=NaN;']);
            eval(['trialStats.Level', num2str(l), 'WID', WID, ...
                '.RTsCI=NaN;']);
            eval(['trialStats.Level', num2str(l), 'WID', WID, ...
                '.RTsV=NaN;']);
            %             eval(['trialStats.Level', num2str(l), 'WID', WID, ...
            %                 '.RTsV.raceStats=NaN;']);
            eval(['trialStats.Level', num2str(l), 'WID', WID, ...
                '.thresh=NaN;']);
        end
        clear fastProp fastPropFitted bsAvg PCCor RTsCI RTsV raceStats
        figInfo = rmfield(figInfo, 'WID');
    end
end