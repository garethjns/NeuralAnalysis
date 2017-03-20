classdef Neural < TDTHelper
    % Extract neural data (using TDTHelper)
    % Pre-process
    % Clean
    % Save to disk
    % Analysis:
    % Load from disk - either single or combined
    % Epoch - using Sess or ComboSess data
    % PSTH etc.
    
    properties
        
    end
    
    methods
        function neural(sess)
           % Check nerual data 
        end
        
        function process
           % Run extraction
           % Run PP
           % Save to disk
           % Shrink
           % Attach to session
        end
        
        function extract
            % Extract neural data
        end
        
        function PP
            % Run PP on neural data
        end
        
        function clean
        end
        
        function spikes
        end
        
        function save
           % Save to disk 
        end
        
        function shrink
            % Remove from memory
            
        end
        
        function get
            % Retrive from disk
        end
        
    end
    
end