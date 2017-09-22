classdef Sess < BehavAnalysis
    % Object to hold imported behavioural experimental data
    % Includes import, report and plot methods
    % For creation, requires table row from Sessions. Also needs subjects
    % paramters and paths - these will be used in analysis so useful if
    % available here rather than Subject object (?).
    
    properties % (SetAccess = immutable)
        title
        subject
        fID
        level
        task
        date
        session % Session row
    end
    
    properties
        single = true % 1 = single, 0 = combo
        nTrials % Number of trials available
        data % Imported data table
        behavAnalysisDone = 0 % Indicate if Sess. analysis has been run yet
        neuralAnalysisDone = 0
        stats = [] % Output from analysis
        neuralData
        neuralPaths
        forceNeural = 0
        analysisPath
        targetSide
    end
    
    properties (Hidden = true)
        % Kept for convenience/debugging, Hidden for tidyness:
        subjectParams = [] % Parameters set for subject
        subjectPaths = [] % Paths set for subject
    end
    
    methods
        function obj = Sess(session, subjectReference, forceNeural)
            
            if ~exist('session', 'var')
                % If session is more than one row, assume ComboSess is
                % being created. Return dummy object and let ComboSess
                % handle rest
                obj.single = false;
                return
            end
            
            % Import session data from input sessions row
            % Copy meta data
            obj.subject = session.Subject{1};
            obj.level = session.Level;
            obj.fID = session.fID{1};
            obj.task = session.Task{1};
            obj.session = session;
            obj.targetSide = 1;
            
            
            if exist('forceNeural', 'var')
                obj.forceNeural = forceNeural;
            end
            
            % Copy subjects parameters if available
            % Make required rather than optional?
            if exist('subjectReference', 'var')
                obj.subjectParams = subjectReference{1};
                obj.subjectPaths = subjectReference{2};
            end
            
            % Import session
            obj.data = ...
                obj.importSession(obj.session, obj.subject, obj.fID);
            
            % Set title
            % Date
            d = datestr(session.DateNum(1));
            % Session num
            s = session.SessionNum(1);
            obj.title = ['Level', num2str(obj.level), '\', ...
                d, '_', ...
                obj.session.Time{1}, '_', ...
                num2str(s)];
            % Set full analysis path
            obj.analysisPath = ...
                [subjectReference{2}.behav.individualSessAnalysis, ...
                obj.title, '\'];
            
            % .nTrials should be actual number of trials imported, not
            % expected number (session.nTrials)
            obj.nTrials = height(table(obj.data));
            obj.report();
            
            % Add neural data
            obj = addNeuralData(obj);
        end
        
        function report(obj)
            % Output basic session info to command line
            
            disp(' ')
            disp(['Subject: ', obj.subject])
            disp(['Task: ', obj.task])
            disp(['nTrials: ', num2str(obj.nTrials)])
            
        end
        
        function obj = analyseBehav(obj)
            % Analyse a single sess object
            % Output stats to object
            % This function will ignore analysisDone flag and always run.
            % [NOTE: Same name as Sessions.analyseBehav, Sessions version
            % calls this function for multiple objects and doesn't ignore
            % analysisDone flag.]
            
            % Switch on level, run appropriate function
            % (These are inhertied from behavAnalysis lib)
            switch obj.level
                case 8
                    obj = obj.level8();
                case 9
                    obj = obj.level9();
                case 10
                    obj = obj.level10();
                case 11
                    obj = obj.level11();
            end
            
            obj.behavAnalysisDone = true;
            
        end
        
        function obj = addNeuralData(obj)
            % Populate nerual paths
            % Process if needed
            % Save nerual object to session
            
            % First check if there is any neural data
            % obj.session will contain relevent info
            
            if ~ obj.session.NeuralData
                return
            end
            
            % Also check there's behavioural data, otherwise no point
            % running
            if isempty(obj.data)
                return
            end
            
            % Set .neuralPaths
            obj.neuralPaths.TDT = [obj.session.fNeuralPathTDT{1}, '\', ...
                obj.session.BlockName{1}, '\'];
            obj.neuralPaths.Extracted = ...
                [obj.subjectPaths.neural.extracted, ...
                obj.session.BlockName{1}, '\'];
            obj.neuralPaths.Filtered = obj.session.PreProFilt{1};
            obj.neuralPaths.Epoched = obj.session.PreProEpoch{1};
            obj.neuralPaths.Spikes = obj.session.Spikes{1};
            % Analysis file - in analysis directory
            % Get from prepDir rather than session.AnalysisFile
            figInfo = obj.prepDir(obj, false);
            obj.neuralPaths.Analysis = figInfo.fns;
            
            % Create neuralData object
            obj.neuralData = Neural(obj);
            % Process it as much as possible (depending on available
            % local data)
            obj.neuralData = obj.neuralData.process(obj.data);
            
        end
        
        function obj = analyseNeural(obj)
            % This uses behav and neural data, so analyse in this object so
            % easy access to both
            
            % Is neural data available?
            if ~isstruct(obj.neuralData.recOK)
                % No
                disp(['Neural data not available for ', obj.title, ', skipping'])
                return
            end
            
            % Run prep to create analysis file and check stimuli
            % obj = processPSTH(obj);
            
            % Run findMSI
            obj = processMSI(obj);
        end
        
        function obj = processMSI(obj)
            
            if ~exist([obj.analysisPath, 'MSI'], 'dir')
                mkdir([obj.analysisPath, 'MSI'])
            end
            
           
            
            % For all channels
            for c = 1:32
                close all
                % Run find MSI
                    [hAVs, hAVa] = obj.findMSI(12);
                
            end
        end
        
        function obj = processPSTH(obj)
            % Use the PSTH function from NeuralAnalysis to calc PSTHs for
            % requested data in params
            
            % First tmake sure analysis directory is ready
            if ~exist([obj.analysisPath, 'Rasters'], 'dir')
                mkdir([obj.analysisPath, 'Rasters'])
            end
            if ~exist([obj.analysisPath, 'PSTHs'], 'dir')
                mkdir([obj.analysisPath, 'PSTHs'])
            end
            
            % Load ok index to use
            % eIdx = obj.neuralData.loadFromAnalysis('OKIdx');
            % Just using recOK idex for now
            eIdx = obj.neuralData.recOK.OK;
            
            % Load spikes
            eSpikes = obj.neuralData.spikes;
            fs = obj.neuralData.neuralParams.Fs;
            
            % Expand eIdx time dimension to size(eSpikes,1);
            eIdx = repmat(eIdx, size(eSpikes,1), 1, 1);
            
            % Apply index by NaNing out bad data
            % Can't index in across channels and epochs
            eSpikes = single(eSpikes); %#ok<CPROP>
            eSpikes(~eIdx) = NaN;
            
            % Find unique stims
            uT = unique(obj.data.Type);
            nT = numel(uT);
            [uR, nR] = obj.unqRates(obj.data);
            
            % Run for types 2, 3, 4
            for t = [2, 3, 4]
                for r = uR'
                    close all
                    % Set type idx
                    tyIdx = obj.data.Type == t;
                    % Set rate idx
                    rIdx = obj.setRateIdx(obj.data, r);
                    
                    % Set other indexes from params and combine
                    trialIdx = obj.setTrialIdx(obj) & tyIdx & rIdx;
                    
                    % Get PSTH and raster
                    % Using sIdx & eIdx
                    [raster, ~, ~] = ...
                        obj.neuralData.raster(eSpikes(:,:,trialIdx), fs);
                    [PSTH, tVecP] = obj.neuralData.PSTH(raster, fs, 10);
                    
                    % Check stim - not acting on this here yet
                    obj.stimCheck(obj.data(trialIdx,:))
                    
                    % Plot PSTH/raster/stim
                    fn = ['Type', num2str(t), ...
                        '_Rate', num2str(r), '.png'];
                    
                    hRas = obj.neuralData.plotRaster(raster, fs);
                    suptitle(['Stim: ', 'Type: ', num2str(t), ...
                        ', Rate:', num2str(r)])
                    obj.ng('Huge')
                    obj.hgx([obj.analysisPath, 'Rasters\',fn])
                    
                    hPSTH = obj.neuralData.plotPSTH(PSTH, tVecP, ...
                        obj.nTrials, typeColour(obj, t)); %#ok<CPROP>
                    suptitle(['Stim: ', 'Type: ', num2str(t), ...
                        ', Rate:', num2str(r)])
                    obj.ng('Huge')
                    obj.hgx([obj.analysisPath, 'PSTHs\',fn])
                    
                end
            end
            
        end
        
        % This function is here as it is specific to this analysis, and
        % uses both behavioural and neural data
        [hAV, hAVs] = findMSI(obj, chan);
        
    end
    
    methods (Static)
        
        function summary
        end
        
        % Import session (external file)
        data = importSession(session, subject, fID)
        
        % Template table for session (external file)
        emptyTable = sessionTable(nTrials)
        
        acc = Brunton2013G(ev, params)
        
        function figInfo = prepDir(obj, del)
            % Set file/folder string to use when saving graphs
            % For invidual sessions, use title (date and session number)
            % for sub folder.
            figInfo = obj.figInfo;
            
            % Set parent folder to save to - individual or joined
            if obj.single
                pType = obj.subjectPaths.behav.individualSessAnalysis;
            else
                pType = obj.subjectPaths.behav.joinedSessAnalysis;
            end
            
            % Set file name and level path - already set in .title
            figInfo.fns = ...
                [pType, ...
                obj.title, '\'];
            figInfo.titleAppend = obj.title;
            
            % Default to delete any previous analysis, keep if del==false.
            if ~exist('del', 'var')
                del = true;
            end
            if del
                if exist(figInfo.fns, 'dir')
                    try
                        rmdir(figInfo.fns(1:end-1), 's')
                    catch err
                        disp(err)
                        disp('Failed to remove dir') % But why??
                    end
                end
                
                % Create the output folder
                mkdir(figInfo.fns)
            end
        end
        
        function trialIdx = setTrialIdx(obj)
            % Set trial index based on inc centreRewardTrials and
            % incCorrectionTrials - NOT training, which varies by level
            
            % Centre reward trials
            if obj.subjectParams.behav.incCentreRewardTrials == 1
                % Use all trials
                crIdx = ones(height(obj.data),1);
            else
                % Don't use trials where centre was rewarded
                crIdx = obj.data.CentreReward==0;
            end
            
            % Correction trials
            if obj.subjectParams.behav.incCorrectionTrials == 1
                % Use all trials
                corIdx = ones(height(obj.data),1);
            else
                % Don't usecorrection trials
                corIdx = obj.data.CorrectionTrial==0;
            end
            
            % Return index
            trialIdx = crIdx & corIdx;
            
        end
        
    end
    
end