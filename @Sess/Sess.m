classdef Sess
    % Object to hold imported behavioural experimental data
    
    properties
        subject
        level
        session % Session row
        data % Imported data table
    end
    
    methods
        function obj = Sess(session)
            % Import session data from input sessions row
            obj.subject = session.Subject;
            obj.level = session.Level;
            obj.session = session;
            
            % Copy meta data
            
            % Import session
            obj.importSession()
        end

    end
    
    methods (Static)
        function summary
        end
    end
    
end