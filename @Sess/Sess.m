classdef Sess
    % Object to hold imported behavioural experimental data
    % Includes import, report and plot methods
    
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
    end
    
    methods
        function obj = Sess(session)
            
            % Import session data from input sessions row
            % Copy meta data
            obj.subject = session.Subject{1};
            obj.level = session.Level;
            obj.fID = session.fID{1};
            obj.task = session.Task{1};
            obj.session = session;
            obj.nTrials = session.nTrials;
            
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