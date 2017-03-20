classdef Sess < behavAnalysis
    % Object to hold imported behavioural experimental data
    % Includes import, report and plot methods
    % For creation, requires table row from Sessions. Also needs subjects
    % paramters and paths - these will be used in analysis so useful if
    % available here rather than Subject object (?).
    
    properties (SetAccess = immutable)
        % Inherited from  
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
        hs % Figure handles
        analysisDone = 0 % Indicate if Sess. analysis has been run yet
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
            obj.nTrials = session.nTrials;
            
            % Copy subjects parameters if available
            % Make required rather than optional?
            if exist('subjectReference', 'var')
                obj.subjectParams = subjectReference{1};
                obj.subjectPaths = subjectReference{2};
            end
                
            
            % Import session
            obj.report();
            obj.data = ...
                obj.importSession(obj.session, obj.subject, obj.fID);
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
                case 9
                case 10
                case 11
                    obj = obj.level11();
            end
            
            obj.analysisDone = true;
            
        end
            
        function hs = plot(obj)
            % Plots for single sessions
            
        end
        
    end
    
    methods (Static)
        function summary
        end
        

        
        % Import session (external file)
        data = importSession(session, subject, fID)
        
        % Template table for session (external file)
        emptyTable = sessionTable(nTrials)
        
    end
    
end