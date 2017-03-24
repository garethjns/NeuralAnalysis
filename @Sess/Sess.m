classdef Sess < BehavAnalysis & fitPsyche
    % Object to hold imported behavioural experimental data
    % Includes import, report and plot methods
    % For creation, requires table row from Sessions. Also needs subjects
    % paramters and paths - these will be used in analysis so useful if
    % available here rather than Subject object (?).
    
    properties (SetAccess = immutable)
        title
        subject
        fID
        level
        task
        date
        session % Session row
    end
    
    properties
        nTrials % Number of trials available
        data % Imported data table
        analysisDone = 0 % Indicate if Sess. analysis has been run yet
        stats = [] % Output from analysis
        neuralData
        neuralPaths
    end
    
    properties (Hidden = true)
        % Kept for convenience/debugging, Hidden for tidyness:
        subjectParams = [] % Parameters set for subject
        subjectPaths = [] % Paths set for subject
    end
    
    methods
        function obj = Sess(session, subjectReference)
            
            % Import session data from input sessions row
            % Copy meta data
            obj.subject = session.Subject{1};
            obj.level = session.Level;
            obj.fID = session.fID{1};
            obj.task = session.Task{1};
            obj.session = session;
            
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
            
            obj.analysisDone = true;
            
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
            
            % Set .neuralPaths
            obj.neuralPaths.TDT = [obj.session.fNeuralPathTDT{1}, '\', ...
                obj.session.BlockName{1}, '\'];
            obj.neuralPaths.Extracted = ...
                [obj.subjectPaths.neural.extracted, ...
                obj.session.BlockName{1}, '\'];
            obj.neuralPaths.PreProFilt = obj.session.PreProFilt{1};
            obj.neuralPaths.Epoch = obj.session.PreProEpoch{1};
            obj.neuralPaths.Analysis = obj.session.AnalysisFile{1};
            
            % Create neuralData object
            obj.neuralData = Neural(obj);
            % Process it as much as possible (depending on available
            % data)
            obj.neuralData.process()
            
        end
    end
    
    methods (Static)
        function summary
        end
        
        % Import session (external file)
        data = importSession(session, subject, fID)
        
        % Template table for session (external file)
        emptyTable = sessionTable(nTrials)
        
        function figInfo = prepDir(obj)
            % Set file/folder string to use when saving graphs
            % For invidual sessions, use title (date and session number)
            % for sub folder.
            figInfo = obj.figInfo;
            figInfo.fns = ...
                [obj.subjectPaths.behav.individualSessAnalysis, ...
                obj.title, '\'];
            figInfo.titleAppend = obj.title;
            
            % Delete any previous analysis
            if exist(figInfo.fns, 'dir')
                try
                    rmdir(figInfo.fns(1:end-1), 's')
                catch err
                    disp('Failed to remove dir') % But why??
                end
            end
            mkdir(figInfo.fns)
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
            
            trialIdx = crIdx & corIdx;
            
        end
        
    end
    
end