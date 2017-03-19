classdef Sessions
    % Import list of sessions for subject
    
    
    properties
        subject
        fID
        levels
        sessions % Tabulated list of sessions
        sessionStats
        sessionData = cell(1) % Exp objects containing data for sessions
        nS
    end
    
    methods
        
        function obj = Sessions(sub, reImport)
            obj.subject = sub.subject;
            obj.levels = sub.levels;
            obj.fID = sub.fID;
            
            % Import sessions for subject
            % Reload or reimport?
            if ~reImport
                % Attempt load
                
                try
                    fns = dataSetFns(obj);
                    tic
                    load(fns{1})
                    disp(['Loaded ', num2str(height(sessions.sessions)), ...
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
            sessions = obj; %#ok<PROPLC>
            
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
                obj.sessionData{s} = Sess(obj.sessions(s,:));
            end
            
        end
        
        function fns = dataSetFns(obj)
            l = obj.l2fn(obj.levels);
            fns{1} = [obj.fID, '_', obj.subject, ...
                '_levels', l, '_SessionDataset.mat'];
            fns{2} = [obj.fID, '_', obj.subject, ...
                '_levels', l, '_SessionDataset.txt'];
        end
        
    end
    
    
    methods (Static)
        function fn = l2fn(levels)
            % Add levels to file name
            l = ('_' + string(levels'))';
            fn = l.join('').char();
        end
        
    end
    
    
end