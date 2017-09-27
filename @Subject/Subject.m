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
        
        function obj = importComboSessions(obj, how, lev)
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
              switch lev
                  case 8
                      how = 'Dates';
                  case 9 
                      how = ''; % WIDs?
                  case 10
                      how = 'DID';
                  case 11
                      how = 'SID2';
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
           % Set level
           cS.levels = lev;
           
           switch how
               case 'DID'
                   % Divide by DID
                   [obj, cS] = divideByID(obj, cS, how);

               case 'SID2'
                   [obj, cS] = divideByID(obj, cS, how);
                   % Divide by DID  
                   
               case 'Dates'
                   % Divide by auto date ranges (and any set in params?)
                   disp('NOT YET IMPLEMENTED')
                   keyboard
                   return
                   
               case 'All'
                   % Mush all sessions available for level together!
                   [obj, cS] = comboAll(obj, cS);
               
               otherwise
                   disp('Unknown combo param')
                   keyboard
                   return
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
            someSessions.levels = cS.levels;
            
            % Remove data - will be reimported
            someSessions.sessionData = {};
            
            % Keep only relevant rows in session table - in this case, all
            % at level
            sIdx = true(height(someSessions.sessions),1);
            lIdx = obj.sessions.sessions.Level==cS.levels;
             
            % And reset n
            someSessions.nS = sum(sIdx & lIdx);
            someSessions.sessions = obj.sessions.sessions(sIdx & lIdx,:);
            
            % Import the data for this sub group and save it back in to
            % the new sessions object holding the combo sessions
            cS.sessionData{1} = ...
                ComboSess(someSessions, obj, 'All');
            
        end
        
        function [obj, cS] = divideByID(obj, cS, how)
            
            % Find all DIDs
            IDs = unique(obj.sessions.sessions.(how));
            % Exclude "Missing" (don't want to merge all level 10s on
            % missing SID, for example...)
            IDs = IDs(~string(IDs).contains('Missing'));
            
            % Create a ComboSess object for each SID/DID
            nIDs = numel(IDs);
            for s = 1:nIDs
                
                % Copy sessions object
                someSessions = obj.sessions;
                someSessions.levels = cS.levels;
                
                % Keep only relevant rows in session table
                sIdx = strcmp(obj.sessions.sessions.(how), IDs{s});
                lIdx = obj.sessions.sessions.Level==cS.levels;
                someSessions.sessionData = ...
                    someSessions.sessionData(lIdx & sIdx);
                
                % And reset n
                someSessions.nS = sum(sIdx & lIdx);
                someSessions.sessions = obj.sessions.sessions(sIdx,:);
                
                % Import the data for this sub group and save it back in to
                % the new sessions object holding the combo sessions
                cS.sessionData{s} = ...
                    ComboSess(someSessions, obj, how);
                
                % After-Spike data is saved to analysis folder
                % Check correct path already set
                
            end

        end
        
    end
    
    methods (Static)
        
    end
    
end