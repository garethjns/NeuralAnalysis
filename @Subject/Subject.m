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
        
        function tidy(obj)
            % Close associated handles
        end
        
    end
    
    methods (Static)
        
    end
end