classdef Subject
    
    properties (SetAccess = immutable)
        subject % Short name
        subject2 % Long name (subject + fID)
        fID % Subject ID
        box = 'Nellie'
        task = 'Temporal'
    end
    
    properties
        levels = 11
        sessions % To hold sessions object
        comboSessions
        params
        paths
    end
    
    methods
        function obj = Subject(params)
            % Set defult parameters
            obj.subject = params.subject;
            [obj.params, obj.paths] = obj.setupSubject();
            
            % Then overwrite any specified parameters
            % Not added yet
            obj.levels = params.level;
            
            % Set obj fields
            obj.fID = obj.params.fID;
            obj.subject2 = obj.params.subject2;
            obj.task = obj.params.task;
        end
        
        function obj = importSessions(obj, reImport)
            % Create sessions object for sub/level
            % Return to sub.sessions
            
            obj.sessions = Sessions(obj, reImport);
        end
        
        function obj = importComboSessions(obj, how)
           % Look through already imported sessions, create combo sessions 
           % where appropriate.
           % For level 8, divide by requested dates - has auto date range
           % been added yet?
           % For level 10 (and 9), find weekIDs, create session for each.
           % For level 11, find weekIDs, create session for each. 
           
           % Copy the sessions object to .comboSessions. This will hold all
           % the combine sessions in one object
           obj.comboSessions = obj.sessions;
           % Clear out the existing Sess objects and data
           obj.comboSessions.sessionStats = struct
           obj.comboSessions.sessionData = {};
           obj.comboSessions.sessions = table;
           
           if strcmp(how, 'auto')
              switch obj.level
                  case 8
                      how = 'Dates';
                  case 9 
                      how = ''; % WIDs?
                  case 10
                      how = 'DIDs';
                  case 11
                      how = 'SIDs';
              end
               
               
           end
           
           
           switch how
               case 'DIDs'
                   obj = divideByDIDs(obj);
                   % Divide by DID
                   
               case 'SID2s'
                   obj = divideBySID2s(obj);
                   % Divide by DID  
                   
               case 'Dates'
                   % Divide by auto date ranges (and any set in params?)
                   
               case 'All'
                   % Mush all sessions available for level together!
           end
            
            % Set nSess to number of combined sessions. Leave nT as total
            % number of trials in all sessions - this should still be the
            % same
            obj.comboSessions.nS = numel(obj.comboSessions.sessionData);
        end
        
        function obj = divideByDIDs(obj)
            
            sessions = obj.sessions.sessions;
            % Find all DIDs
            DIDs = findgroups(sessions.DID)
        end
        
        function obj = divideBySID2s(obj)
            
            % Find all DIDs
            SIDs = unique(obj.sessions.sessions.SID2);
            
            % Create a ComboSess object for each SID
            nSIDs = numel(SIDs);
            combo = cell(1,nSIDs);
            for s = 1:nSIDs
                
                % Copy sessions object
                someSessions = obj.sessions;
                % Remove data - will be reimported
                someSessions.sessionData = {};
                % Keep only relevant rows in session table
                sIdx = strcmp(obj.sessions.sessions.SID2, SIDs{s});
                % And reset n
                someSessions.nS = sum(sIdx);
                someSessions.sessions = obj.sessions.sessions(sIdx,:);
                
                % Import the data for this sub group and save it back in to
                % the new sessions ibject holding the combo sessions
                obj.comboSessions.sessionData{s} = ComboSess(someSessions, obj);
            end
            
            
        end
        
    end
    
    methods (Static)
        
    end
end