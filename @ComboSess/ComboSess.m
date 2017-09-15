classdef ComboSess < Sess
    % Combined sessions
    % Eg. For DIDs for levels 10, 11
    % For date ranges for level 8
    %
    % Subject object has method to find all sessions to combine.
    % This will use Sessions to create a new group of sessions containing
    % ComboSess objects (equiv to Sess objects).
    % Sessions can then handle batch processing of ComboSess objects using
    % the same methods used to handle Sess objects.
    %
    % Need (external):
    % 1) To add method to Sessions or Subject to handle creation of new set
    % of Sessions.
    % Need (internal):
    % 2) Methods to sumarise statistics from each Sess object. Stats run on
    % ComboSession object will be run using BehavAnalysis in the same way as
    % Sess
    % 3) Methods to handle loading of neural data - keep original paths and
    % load and concatonate from individual files?
    % 4) To change properties of Sess class as needed (some are ummutable)
    % and to ID as ComboSess. Sess already imports BehavAnalysis &
    % fitPsyche.
    
    properties
        sessions = {}
    end
    
    methods
        function obj = ComboSess(sessions, sub, split, forceNeural)
            % Taking sessions obj as input, then importing as Sess objs
            % here (rather than taking Sess objects as input).
            % Downside: Possible extra disk access (in checking if done,
            % even if just done).
            % Advantage: Doesn't require individual sessions to have already
            % been processed
            
            % as in Sess object, dupliate reference data
            % Import session data from input sessions row
            % Copy meta data
            
            obj.subject = sub.subject;
            obj.level = sub.levels;
            obj.fID = sub.fID;
            
            if exist('forceNeural', 'var')
                obj.forceNeural = forceNeural;
            end
            
            % Copy subjects parameters if available
            % Make required rather than optional?
            if exist('sub', 'var')
                % Need to set a combo path.
                obj.subjectParams = sub.params;
                obj.subjectPaths = sub.paths;
            end
            
            % Import the data
            obj.sessions = sessions.importData(true);
            
            % Append sessions data to sessionData
            nS = obj.sessions.nS;
            
            % Preallocate behavioural data
            sessionData = obj.sessionTable(obj.sessions.nT);
            % Get behavioural data from each individual session
            row = 1;
            for s = 1:nS
                n = height(obj.sessions.sessionData{s}.data);
                
                sessionData(row:row+n-1,:) = ...
                    obj.sessions.sessionData{s}.data;
                row = row+n;
            end
            
            % Reset TrialNumbers
            sessionData.TrialNumber(:,1) = 1:obj.sessions.nT;
            obj.data = sessionData;
            obj.nTrials = height(sessionData);
            
            % Set title
            % Date
            ds = datestr(min(sessions.sessions.DateNum));
            de = datestr(max(sessions.sessions.DateNum));
            
            % Type of split (just used for graph title)
            switch split
                case 'SID2s'
                    s = ['SID2s_', sessions.sessions.SID2{1}];
                case 'DID'
                    s = ['DID_', sessions.sessions.DID{1}];
                case 'All'
                    s = 'All';
            end
            obj.title = ['Level', num2str(obj.level), '\', ...
                s, '_', ds, '_', de ...
                ];
            
            % Collect the attached neural objects from the sessions and
            % concatenate into single object to attach to ComboSess object
            comboNeural = Neural(obj);
        end
        
        
    end
    
    methods (Static)
        
    end
    
end
