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
       nSess = []
       indivData = {}
   end
   
   methods
       function obj = ComboSess(sessions, subjectReference, forceNeural)
           % Taking sessions obj as input, then importing as Sess objs
           % here (rather than taking Sess objects as input).
           % Downside: Possible extra disk access (in checking if done,
           % even if just done).
           % Advantage: Doesn't require individual sessions to have already
           % been processed

           % as in Sess object, dupliate reference data
           % Import session data from input sessions row
           % Copy meta data
           obj.subject = sessions.subject;
           obj.level = sessions.levels;
           obj.fID = sessions.fID;
           obj.task = ''
           obj.session = sessions;
           
           if exist('forceNeural', 'var')
               obj.forceNeural = forceNeural;
           end
           
           % Copy subjects parameters if available
           % Make required rather than optional?
           if exist('subjectReference', 'var')
               obj.subjectParams = subjectReference{1};
               obj.subjectPaths = subjectReference{2};
           end
           
          
           
           obj.sessions = sessions.importData(true);

           
           % Now iterate over these session objects and create title,
           % nTrails, append data, etc.
           
       end
       
       
       

   end
   
end