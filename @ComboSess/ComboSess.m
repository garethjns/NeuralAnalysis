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
   end
   
   methods
       function obj = ComboSess(SessObjs)
           % Input is cell array of Sess objects.
           % Append behavioural data together
       end
   end
   
end