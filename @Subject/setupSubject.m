function [fParams, fPaths] = setupSubject(obj)
% Set options for processing
% Set options for plotting
% Set Subject specific filters
% Set paths

%% Things to (re)do
% "do" parameters turn cells on and off in AnalysisMaster. Redo paramaters
% control what's done inside each function.

fParams.do.verifySoFar = 0; % Verfiy files saved so far are not corrupt

fParams.do.reImportSessions = 1; % Reimport session data, or load it from disk?
fParams.do.reImportTrials = 1; % Reimport trial data, or load it from disk?

fParams.do.doExtract = 1; % Run extraction cell
fParams.do.redoExtract = 0; % Redo neural extraction?

fParams.do.doPreProcessing = 1; % Run preprocessing cell
fParams.do.PreProRedo = 0; % Redo preprocessing on extracted data?
fParams.do.PreProBehavUpdate = 0; % Or just update behaviour?

fParams.do.doSpkTrgAvg = 0; % Run spkTrigAvg cell
fParams.do.RedoSpkTrgAvg = 0; % Redo spike triggered average? Useless
fParams.do.RedoEventsSpkTrgAvg = 0; % And Redectect events before spkTrigAvg?

fParams.do.doPSTH = 1; % Run PSTH cell
fParams.do.PSTHRedo1 = 0; % Redo PSTHs? (single blocks)
fParams.do.PSTHRedo2 = 0; % (DIDs)

fParams.do.doFI = 0; % Run find interesting?
fParams.do.doMSI = 0; % Run MSI?

fParams.do.doDaySplit = 1; % Run daySplit cell
fParams.do.daySplitRedetectEvents=0; % Redetect events after combining epochs?
fParams.do.DaySplitRedo = 0; % Redo day splits?

fParams.do.doDayAnalysis = 0; % Do day analysis?

fParams.do.doRvE = 0; % Do rate vs events on day sets? (simple sum)

fParams.do.doBruntonMod = 0; % Run modified Bruton model on day sets?


%% Things to plot

fParams.plot.PreProPlot = 0; % Preprocessing graphs
fParams.plot.eventPlot = 0; % Events graphs in preprocessing
fParams.plot.eventRedoPlot = 1; % Events graphs in any redos
fParams.plot.PSTHPlot = 1;


%% Other parameters

% Include centre trials in trial analysis?
fParams.behav.incCentreRewardTrials = 0;
% Include corretion trails?
fParams.behav.incCorrectionTrials = 0;

% Behavioural analysis
% Set size when deviding trials into bins based on asyncMetric
fParams.asParams.bDiv = 0.25;
fParams.asParams.C2Fun = @Church2Nellie;
fParams.asParams.mu = 0;
fParams.asParams.sig = 0.3;
fParams.asParams.plotOn = 0;
fParams.asParams.dispOn = 0;
fParams.asParams.compType = 'AbsDiff';
fParams.asParams.PreProType = 'TWI';
fParams.asParams.TWIWidth = 200; % ms
fParams.asParams.TWIFun = @normpdf; % Guassian
fParams.asParams.Fs = 12000;


% Extraction
% NOTE: Set as defualts in TDT helper, not being reapplied at the moment
fParams.extractEvIDs = { ...
    % {'SU_2', 1:16, 24414.0625, 24414.0625}, ...
    % {'SU_3', 1:16, 24414.0625, 24414.0625}, ...
    {'BB_2', 1:16, 24414.0625, 24414.0625}, ...
    {'BB_3', 1:16, 24414.0625, 24414.0625}, ...
    {'dBug', 1:3, 6103.515625, 6103.515625}, ...
    {'Sens', 1:3, 762.939254, 762.939453}, ...
    {'Sond', 1:3, 762.939254, 762.939453}, ...
    {'Valv', 1:3, 762.939254, 762.939453}, ...
    };

% Pre-processing
% Epoch size
fParams.PP.EpochPreTime = -3;
fParams.PP.EpochPostTime = +2;
fParams.PP.eventThreshRedo = 0; % Disabled for now
fParams.PP.evMode = 'K'; % 'G' or 'B', 'K' or 'J' not yet implemented
% If using basic detect: Event threshold? >x*RMS
fParams.PP.eventThresh = 3;
% If using Kath detect
fParams.PP.medianThresh = 3;
fParams.PP.artThresh = 10;
% If using Gareth detect
fParams.PP.GDetectThresh = [3 40];
fParams.PP.GDetectReject = [5 50];
% Resample LFP
fParams.PP.LFPResampleFs = 1000;


%% Set up for subject

switch obj.subject
    case 'Twister'
        fParams.subject2 = 'F1312_Twister';
        fParams.task = 'Temporal';
        fParams.fName = 'Twister';
        fParams.L8.DateRanges={...
            '16-Apr-2015', '17-Apr-2015'; ...
            '19-Apr-2015', '02-May-2015'; ...
            '02-May-2015', '17-May-2015'; ...
            '18-May-2015', '24-May-2015'; ...
            };
        fParams.fID = 'F1312';
        % fParams.level=[8, 9, 10];
        
    case 'Snow'
        fParams.subject2 = 'F1403_Snow';
        fParams.fName = 'Snow';
        fParams.fID = 'F1403';
        fParams.task = 'Temporal';
        % fParams.level=[8, 9, 10];
        fParams.L8.DateRanges = {...
            '26-Apr-2015', '05-May-2015'; ...
            '01-Apr-2015', '25-Apr-2015'...
            };
        
    case 'Suarez'
        fParams.fID = 'F1408';
        fParams.fName = 'Suarez';
        fParams.subject2 = 'F1408_Suarez';
        fParams.task = 'Temporal';
        fParams.L8.DateRanges = {...
            '10-Apr-2015', '15-Apr-2015'; ...
            '01-Apr-2015', '09-Apr-2015'...
            };
        % fParams.level = [8, 9, 10];
        
    case 'Beryl'
        fParams.fID = 'F1520';
        fParams.fName = 'Beryl';
        fParams.subject2 = 'F1520_Beryl';
        fParams.task = 'Temporal';
        fParams.L8.DateRanges = {...
            '01-Jan-2016', '31-Jan-2016'; ...
            '01-Feb-2016', '28-Feb-2016'; ...
            '01-Mar-2016', '31-Mar-2016'; ...
            '01-Apr-2016', '30-Apr-2016'; ...
            '01-May-2016', '31-May-2016'; ...
            '01-Jun-2016', '30-Jun-2016'; ...
            '01-Jul-2016', '31-Jul-2016'; ...
            '01-Aug-2016', '31-Aug-2016'; ...
            '01-Sep-2016', '33-Sep-2016'; ...
            '01-Nov-2016', '33-Nov-2016'; ...
            '01-Dec-2016', '33-Dec-2016'; ...
            };
end


%% Set paths T Drive

% Neural data (TDT)
fPaths.neural.TDTRaw = ['T:\Analysis\Behaving\', ...
    fParams.task, '\' fParams.subject2, '\'];
% Extracted neural data (.mat)
fPaths.neural.extracted = ['T:\Analysis\Behaving\', ...
    fParams.task, '\' fParams.subject2, '\Extracted\'];
% Pre-processing directory
fPaths.neural.PP = ['T:\Analysis\Behaving\', ...
    fParams.task, '\' fParams.subject2, '\Processing\'];
% Path for pre-processing cleaning graphs
fPaths.graphs.neuralCleaning = [fPaths.neural.PP, ...
    'Cleaning\'];
% Path for pre-processing event graphs
fPaths.graphs.neuralEvents = [fPaths.neural.PP, ...
    'Events\'];

% Path for behavioural graphs
fPaths.behav.analysis = ['T:\Analysis\Behaving\', ...
    fParams.task, '\' fParams.subject2, '\BehavAnalysis\'];
fPaths.behav.individualSessAnalysis = ...
    [fPaths.behav.analysis, 'IndividualSessions\'];
fPaths.behav.joinedSessAnalysis = ...
    [fPaths.behav.analysis, 'JoinedSessions\'];

try % Errors if running on laptop, OK.
    % Make the directories, if they don't already exist
    fps = fieldnames(fPaths);
    for fp = 1:length(fps)
        fps2 = fieldnames(fPaths.(fps{fp}));
        for fp2 = 1:length(fps2)
            if ~exist(fPaths.(fps{fp}).(fps2{fp2}), 'dir') ...
                    && ~(exist(fPaths.(fps{fp}).(fps2{fp2}), 'file'))
                mkdir(fPaths.(fps{fp}).(fps2{fp2}));
            end
        end
    end
end

% Behavioural directory
fPaths.behav.data = ['T:\Behavioural Data\', ...
    fParams.subject2, '\'];
% Dropbox source
fPaths.behav.source = ['R:\Dropbox\Data\', ...
    fParams.subject2, '\'];


