classdef ggraph
    % Matlab plotting convenience functions
    
    properties (Hidden)
        beAnnoying = true
    end
    
    methods
        
        function obj = ggraph()
            
            if obj.beAnnoying
                disp('Importing ggraph')
            end
            
        end
        
    end
    
    methods (Static)
        
        % Lazy figure saving
        hgx(varargin)
        
        % Nice-graph templates
        handles = ng(template)
        
        % Turn openGL on
        og
        
        % Get MATLAB's default figure colours
        cols = getCols
        
    end
    
end