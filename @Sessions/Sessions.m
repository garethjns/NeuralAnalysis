classdef Sessions
    % Import list of sessions for subject
    % Inherit session methods for reporting and plotting
    
    properties (SetAccess = immutable)
        subject
        fID
    end
    
    properties
        levels
        sessions % Tabulated list of sessions
        sessionStats
        sessionData = cell(1) % Exp objects containing data for sessions
        nS % Number of sessions
        nT % Total number of trials available
        
    end
    
    properties (Hidden = true)
        % Kept for convenience/debugging, Hidden for tidyness:
        subjectParams % Parameters set for subject
        subjectPaths % Paths set for subject
    end
    
    methods
        
        function obj = Sessions(sub, reImport)
            
            obj.subject = sub.subject;
            obj.levels = sub.levels;
            obj.fID = sub.fID;
            obj.subjectParams = sub.params;
            obj.subjectPaths = sub.paths;
            
            % Import sessions for subject
            % Reload or reimport?
            if ~reImport
                
                % Attempt load
                try
                    fns = dataSetFns(obj);
                    tic
                    load(fns{1})
                    disp(['Loaded ', ...
                        num2str(height(sessions.sessions)), ...
                        ' trials in ', ...
                        num2str(toc), 's.'])
                    obj = sessions;
                    loadOK = true;
                catch
                    disp('Load failed, importing...')
                    loadOK = false;
                end
                
                
                if ~loadOK
                    reImport = true;
                end
            end
            
            % Reimport and save if not loaded
            if reImport
                obj.sessions = obj.findSessions(sub);
                obj.nS = height(obj.sessions);
                obj.saveSessions(sub);
            end
            
        end
        
        function saveSessions(obj, sub)
            
            % Generate file names
            fns = dataSetFns(obj);
            
            % Rename obj to sessions in saved file
            sessions = obj; %#ok<NASGU,PROPLC>
            
            disp('Saving .mat')
            save(fns{1}, ...
                'sessions', 'sub')
            
            disp('Writing table')
            writetable(obj.sessions, [obj.fID, '_', sub.subject, ...
                fns{2}])
            
            disp(['Saved: ', obj.fID, '_',  sub.subject, ...
                '_SessionDataset .mat/.txt'])
        end
        
        function obj = importData(obj, reImport)
            % Create table for analysis from sess objects
            
            if ~reImport
                % Load
            end
            
            for s = 1:obj.nS
                % Report and time for debugging
                a = string('*').pad(30, '*');
                disp(a)
                disp(['Importing session: ', num2str(s), ...
                    '/', num2str(obj.nS)])
                tic
                % Create session object for each session using table row
                % from Sessions and subject's parameters/paths
                obj.sessionData{s} = Sess(obj.sessions(s,:), ...
                    {obj.subjectParams, obj.subjectPaths});
                b = toc;
                disp(['Done in ', num2str(b) ', S @ ', ...
                    num2str(obj.sessionData{s}.nTrials/b), ' t/S'])
            end
            
        end
        
        function fns = dataSetFns(obj)
            l = obj.l2fn(obj.levels);
            fns{1} = [obj.fID, '_', obj.subject, ...
                '_levels', l, '_SessionDataset.mat'];
            fns{2} = [obj.fID, '_', obj.subject, ...
                '_levels', l, '_SessionDataset.txt'];
        end
        
        function obj = analyseBehav(obj, force)
            % Analyse all sess objects held in session, if not already
            % done.
            % (Using Sess.analyseBehav(sessObj)
            
            % Check force parameter - if true force redoing of analysis of
            % each Sess object, ignoring .analysisDone.
            if ~exist('force', 'var')
                % Default to false
                force = false;
            end
            
            for s = 1:obj.nS
                % Check analysis flag
                sess = obj.sessionData{s};
                if ~(sess.analysisDone == 0 || force)
                    % Done, don't redo
                    continue
                end
                
                % Else, run analysis
                obj.sessionData{s} = obj.sessionData{s}.analyseBehav();
                
            end
            
            % Do subject level analysis
            
        end

    end
    
    
    methods (Static)
        function fn = l2fn(levels)
            % Add levels to file name
            l = ('_' + string(levels'))';
            fn = l.join('').char();
        end
        
        
        % Template table for sessions (external file)
        emptyTable = sessionsTable(nTrials)
    end
    
    
end