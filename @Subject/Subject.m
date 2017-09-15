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
        comboSessions = struct
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
           % For level 10 (and 9), find WIDs/DIDs, create session for each.
           % For level 11, find seedIDs, create session for each. 
           % 
           % Concatenate neural data where available
           % Save this to disk in \ComboNeural\ID
           % And set this as the spike path in the attached neural object
           
           % Auto will only work if subject contains only sessions of one
           % level
           if strcmp(how, 'auto')
              switch obj.level
                  case 8
                      how = 'Dates';
                  case 9 
                      how = ''; % WIDs?
                  case 10
                      how = 'DID';
                  case 11
                      how = 'SID2s';
              end
           end
           
           % Copy the sessions object to comboSessions. This will hold all
           % the combine sessions in one object. Not saving to obj yet.
           cS = obj.sessions;
           % Clear out the existing Sess objects and data
           cS.sessionStats = struct;
           cS.sessionData = {};
           cS.sessions = table;
           cS.type = how;
           
           switch how
               case 'DID'
                   % Divide by DID
                   [obj, cS] = divideByID(obj, cS, how);

               case 'SID2s'
                   [obj, cS] = divideByID(obj, cS, how);
                   % Divide by DID  
                   
               case 'Dates'
                   % Divide by auto date ranges (and any set in params?)
                   disp('NOT YET IMPLEMENTED')
                   return
                   
               case 'All'
                   % Mush all sessions available for level together!
                   [obj, cS] = comboAll(obj, cS);
               
               otherwise
                   disp('Unknown combo param')
           end
            
            % Set nSess to number of combined sessions. Leave nT as total
            % number of trials in all sessions - this should still be the
            % same
            cS.nS = numel(cS.sessionData);
            
            % Save to object in comboSessions structure using how as the
            % sub field
            obj.comboSessions.(how) = cS;
        end
        
        
        function [obj, cS] = comboAll(obj, cS)
            % Copy sessions object
            someSessions = obj.sessions;
            % Remove data - will be reimported
            someSessions.sessionData = {};
            
            % Keep only relevant rows in session table - tin this case, all
            sIdx = true(height(someSessions.sessions),1);
            % And reset n
            someSessions.nS = sum(sIdx);
            someSessions.sessions = obj.sessions.sessions(sIdx,:);
            
            % Import the data for this sub group and save it back in to
            % the new sessions object holding the combo sessions
            cS.sessionData{1} = ...
                ComboSess(someSessions, obj, 'All');
            
        end
        
        
        function [obj, cS] = divideByID(obj, cS, how)
            
            % Find all DIDs
            IDs = unique(obj.sessions.sessions.(how));
            
            % Create a ComboSess object for each SID/DID
            nIDs = numel(IDs);
            for s = 1:nIDs
                
                % Copy sessions object
                someSessions = obj.sessions;
                % Keep only relevant rows in session table
                sIdx = strcmp(obj.sessions.sessions.(how), IDs{s});
                someSessions.sessionData = someSessions.sessionData(sIdx);
                % And reset n
                someSessions.nS = sum(sIdx);
                someSessions.sessions = obj.sessions.sessions(sIdx,:);
                
                % Import the data for this sub group and save it back in to
                % the new sessions object holding the combo sessions
                cS.sessionData{s} = ...
                    ComboSess(someSessions, obj, how);
                
            end

        end
        
    end
    
    methods (Static)
        
    end
    
end