function obj = level8(obj)
% Level 8 analysis

% Add auto L8 Date ranges to those specified, if there are any
startDatesRows = ...
    find(diff(allData.Level == 8)==1);
endDatesRows = ...
    find(diff(allData.Level == 8)==-1);

if ~isempty(startDatesRows)
    
    if startDatesRows(1)>endDatesRows(1)
        % First start date is missing, so first trial must be level 8 - add it
        startDatesRows = [1;startDatesRows];
    end
    
    if length(endDatesRows)<length(startDatesRows)
        % Last endDate missing, l8 must be in progress. Leave for now.
        startDatesRows = startDatesRows(1:end-1);
    end
end
% Test
% pair = 8;
% allData(startDatesRows(pair):endDatesRows(pair),:)

% Get dates
startDates = allData.DateNum(startDatesRows);
endDates = allData.DateNum(endDatesRows);

dates2add = {};
for d = 1:length(startDates)
    dates2add{d,1} = datestr(startDates(d)); %#ok<AGROW>
    dates2add{d,2} = datestr(endDates(d)); %#ok<AGROW>
end

fParams.L8DateRanges = [fParams.L8DateRanges; dates2add];

close all force

% Level
l=8;

if any(fParams.level==l)
    for dr = 1:size(fParams.L8DateRanges,1)
        
        dateRange = ...
            [fParams.L8DateRanges{dr,1}; fParams.L8DateRanges{dr,2}];
        
        % Set date index for use in analysis
        allDates = unique(allData.DateNum);
        if isscalar(dateRange) == 1 %~~
            % Can't use scaler date ranges at the momement
            if dateRange==0 %#ok<BDSCI> % Use all
                dateRangeNum = [allDates(1); allDates(end)];
                dateRange = datestr(dateRangeNum);
                
                % Create index
                dInd = ones(height(allData),1);
                dInd = dInd==1;
            else
                % Get last n sessions
                nSes = dateRange;
                clear dateRange
                
                unSes = unique(allData.SessionNum);
                
                % Find dateRange to use
                dateRangeNum = ...
                    [unique(allData.DateNum(allData.SessionNum==unSes(end-nSes)));
                    unique(allData.DateNum(allData.SessionNum==unSes(end)))];
                
                % Save text version
                dateRange=datestr(dateRangeNum);
                
                % Create index
                dInd = allData.DateNum>=dateRangeNum(1)...
                    & allData.DateNum<=dateRangeNum(2);
            end
            
        else % Use specified date range...
            dateRangeNum=datenum(dateRange); % Does nothing if already a double
            
            % Create index
            dInd = allData.DateNum>=dateRangeNum(1) ...
                & allData.DateNum<=dateRangeNum(2); % +1 to make inclusive
        end
        
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
        % (date, training, centre reward, level, correction trials)
        trialInd = dInd & tInd & crInd & lInd & corInd;
        
        % Set file/folder string to use when saving grapsh
        figInfo.fns = [fPaths.fBehavAnalysisFolder, ...
            'Level', num2str(l), '\', ...
            dateRange(1,:), '_', dateRange(2,:), '\'];
        figInfo.titleAppend = ['Level', num2str(l), ',' ...
            dateRange(1,:), ' to ', dateRange(2,:), ' '];
        if ~exist(figInfo.fns,'dir')
            mkdir(figInfo.fns);
        end
        
        % Summary stats
        sumStats(allData, trialInd, l, dateRange, figInfo)
        
        % Run analysis
        % Check it's worth running
        if sum(trialInd)>10
            
            % Calculate fastProp
            fastProp = calcFastProp(allData, trialInd, figInfo);
            snapnow; close all force
            
            % Plot performance and psych curves
            [fastPropFitted, bsAvg] = ...
                plotPsych(allData, fastProp, trialInd, figInfo); %#ok<ASGLU>
            snapnow; close all force
            
            % % Correct
            PCCor = PCCorrect(allData, trialInd, figInfo);
            snapnow; close all force
            
            % Plot RTs
            [RTsCI, RTsV] = ...
                plotRTs(allData, trialInd, figInfo); %#ok<ASGLU>
            snapnow; close all force
            
            % Run race model
            raceStats=runRace(RTsV.data);
            snapnow; close all force
            
            % Save to stats structure
            eval(['trialStats.Level', num2str(l), 'DR', num2str(dr), ...
                '.fastProp=fastProp;']);
            eval(['trialStats.Level', num2str(l), 'DR', num2str(dr), ...
                '.fastPropFitted=fastPropFitted;']);
            eval(['trialStats.Level', num2str(l), 'DR', num2str(dr), ...
                '.bsAvg=bsAvg;']);
            eval(['trialStats.Level', num2str(l), 'DR', num2str(dr), ...
                '.PCCor=PCCor;']);
            eval(['trialStats.Level', num2str(l), 'DR', num2str(dr), ...
                '.RTsCI=RTsCI;']);
            eval(['trialStats.Level', num2str(l), 'DR', num2str(dr), ...
                '.RTsV=RTsV;']);
            eval(['trialStats.Level', num2str(l), 'DR', num2str(dr), ...
                '.RTsV.raceStats=raceStats;']);
        else
            disp(['Not running level ', num2str(l), ...
                ' analysis, n to low in date range']);
            % Save NaNs to stats structure
            eval(['trialStats.Level', num2str(l), 'DR', num2str(dr), ...
                '.fastProp=NaN;']);
            eval(['trialStats.Level', num2str(l), 'DR', num2str(dr), ...
                '.fastPropFitted=NaN;']);
            eval(['trialStats.Level', num2str(l), 'DR', num2str(dr), ...
                '.bsAvg=NaN;']);
            eval(['trialStats.Level', num2str(l), 'DR', num2str(dr), ...
                '.PCCor=NaN;']);
            eval(['trialStats.Level', num2str(l), 'DR', num2str(dr), ...
                '.RTsCI=NaN;']);
            eval(['trialStats.Level', num2str(l), 'DR', num2str(dr), ...
                '.RTsV=NaN;']);
            %             eval(['trialStats.Level', num2str(l), 'DR', num2str(dr), ...
            %                 '.RTsV.raceStats=NaN;']);
        end
        clear fastProp fastPropFitted bsAvg PCCor RTsCI RTsV raceStats
    end
end