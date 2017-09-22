classdef Neural < NeuralPP & NeuralAnalysis
    % This object creates structure for analysis and includes
    % saving and get methods. It's not necessarily speicifc to temporal
    % tasks and imports general methods from NeuralPP and NeuralAnalysis.
    % It is held by session object which is specific to temporal task, and
    % contains behavioural data (and imported methods) and methods to do
    % analysis requiring both behavioural and neural data. Behavioural data
    % is required here for epoching, really only trial times are required -
    % update in future.
    % 
    % Takes parent Sess ohject as input, which contains paths to neural
    % data and behavioural data.
    % Extract neural data (using TDTHelper) to \extracted\block\
    % Pre-process:
    % Filter (using
    % https://uk.mathworks.com/matlabcentral/fileexchange/17061-filtfilthd)
    % to \processing\block\
    % Epoch THEN clean:
    % to \epoched\block\
    % Extract events 
    % to \spikes\block\
    % Check recordings and stimuli presentation
    % to \behavAnlaysis\[session type]\[level]\[id]\analysis.mat
    % Get methods get from this file.
    %
    % Add PSTH etc as methods here? - Added in NeuralAnalysis and importing
    % here
    %
    % To add: Verification functions for usable channels/find switched
    % sides/unplugs/correct simuli etc.
    %
    % Plan is for Sess to load data as needed (using methods here) then do
    % analysis (using methods here?).
    % ComboSesh can use then use the same methods to do the combined
    % analysis.
    
    properties
        neuralPaths % Will get from Sess
        stage = 0 % How far processing as got
        blockName
        blockNum
        % Possibly not needed:
        extractionPaths % Extracted data - stage 1 done
        processingPaths % Filtered data - stage 2 done
        epochedPaths % Epoched and cleaned data - stage 3 done
        spikePaths % Saved file after event detection - stage 4
        analysisPath % .mat with spikes/ok idx in analysis dir
        neuralParams
        force = 0 % Force processing from stage onwards, or 0 for off
        recOK % Recording looks ok
        stimOK = true % Stim were ok (not yet implemented)
        spikes = [] % 
    end
    
    properties (Hidden = true)
        extractionObject
        extractedData = []
        filteredData = []
        epochedData = []
        nSessions = []
    end
    
    methods
        function obj = Neural(sess)
            % Can be created from input of session object or from cell
            % array of existing neural objects to concatenate
            
            switch class(sess)
                case 'Sess' % Check correct
                    % Input is session object containing:
                    % Paths contain .TDT, .Extracted, PreProFilt, .Epoch, 
                    % .Analysis
                    obj.neuralPaths = sess.neuralPaths;
                    obj.neuralParams = sess.subjectParams.PP;
                    obj.nSessions = 1;
                    % Add here a set stage function - needs to check 
                    % which files already exist
                    
                    % Start processing
                    obj.force = sess.forceNeural;
                    if obj.force > 0
                        obj.clearStageOn
                    end
                    
                case 'ComboSess'
                    % Input is combSess object to concatenate together
                    % Assuming neural extraction has already been run 
                    % during import of this data.
                    % Neural objects are in
                    % combSess.sessions.sessionData{n}.NeuralData 
                    % and may or may not be present for all sessions.
                    % Get params from first session object
                    % Title will be used to generate final paths
                    obj.neuralParams = sess.subjectParams.PP;
                    obj.nSessions = numel(sess.sessions.sessionData);
                    
                    obj = obj.concat(sess);
                    
                    % Don't do processing - already done. Just return new
                    % combined object.
            end
            

        end
        
        function obj = concat(obj, sess)
            % Concat neural data
            % For now, setting up for spikes only...
            % TO DO:
            % Load spikes
            % Concatenate
            % Run checks 
            % Save concat version
            
            nS = obj.nSessions;
            nd = cell(1, nS);
            
            sp = cell(1, nS);
            ok = cell(1, nS);
            for n = 1:obj.nSessions
                % Neural object should exist, check that it's processed to
                % spike -> analysis .mat stage
                if sess.sessions.sessionData{n}.neuralData.stage >= 5
                    
                    curObj = sess.sessions.sessionData{n}.neuralData;
                    
                    sp{1, n} = curObj.spikes;
                    ok{1, n} = curObj.recOK;
                    
                else % No neural object
                    % If not, zero out channels
                    % And mark OKIdx as not ok
                    
                    % Need to know expected length of epoch to zero out
                    % spikes (t x c x e)
                    % Can get this info from params:
                    fs = sess.subjectParams.extractEvIDs{1}{4};
                    t = ceil(fs * (abs(sess.subjectParams.PP.EpochPreTime) ...
                        + abs(sess.subjectParams.PP.EpochPostTime)));
                    % Always 32 chans
                    c = 32;
                    % Get number of epochs from number of trials in session
                    e = sess.sessions.sessionData{n}.nTrials;
                    
                    sp{1, n} = false(t, c, e);
                    
                    % Set OK indexes
                    % .OK: [1�c�e logical]
                    % .evPerEP: [1�c�e double]
                    % .ST: [c�e double]
                    ok{1, n}.OK = false(1, c, e);
                    ok{1, n}.evPerEP = zeros(1, c, e);
                    ok{1, n}.ST = zeros(c, e);
                end
            end

            % Data now in memory, rehape...
            sp2 = false(size(sp{1}, 1), 32, sess.nTrials);
            ok2.OK = false(1, 32, sess.nTrials);
            ok2.evPerEP = zeros(1, 32, sess.nTrials, 'single');
            ok2.ST = zeros(32, sess.nTrials, 'single');
            sIdx = 0;
            for n = 1:nS
                disp(['Concatenating block ', num2str(n), '/' num2str(nS)])
                % Spikes
                nAdd = size(sp{1,n},3);
                sp2(:,:,sIdx+1:sIdx+nAdd) = sp{1,n};
                
                % OKs
                ok2.OK(:,:,sIdx+1:sIdx+nAdd) = ok{1,n}.OK;
                ok2.evPerEP(:,:,sIdx+1:sIdx+nAdd) = single(ok{1,n}.evPerEP);
                ok2.ST(:,sIdx+1:sIdx+nAdd) = single(ok{1,n}.ST);
                
                % Increment for next step
                sIdx = sIdx + nAdd;
                
                % Destroy current step to save menory
                sp{n} = [];
                ok{n} = [];
            end
            
            % Leave most paths blank - they are no longer valid
            % Set obj.neuralPaths.Analysis dir
            obj.neuralPaths.Analysis = ...
                [sess.subjectPaths.behav.joinedSessAnalysis, ...
                sess.title, '\'];
            if ~exist(obj.neuralPaths.Analysis, 'file')
                mkdir(obj.neuralPaths.Analysis)
            end
            
            % Set new analysisPath
            obj.analysisPath = [obj.neuralPaths.Analysis ...
                'Analysis.mat'];
            
            % If exist delete for now - ignoring force - no warning!
            if exist(obj.analysisPath, 'file')
                delete(obj.analysisPath)
            end
            
            % Save spikes and oks here
            % Create a file to append to
            a.spikes = sp2; %#ok<STRNU>
            save(obj.analysisPath, 'a', '-v7.3')
            recOK.OK = ok2.OK; %#ok<PROPLC>
            recOK.evPerEP = ok2.evPerEP; %#ok<PROPLC>
            recOK.ST = ok2.ST;  %#ok<STRNU,PROPLC>
            
            % Append to analysis file as concat matrix
            save(obj.analysisPath, 'recOK', '-append');
            
            % Set stage
            obj.stage = 6;
        end
        
        function obj = clearStageOn(obj)
            if obj.force > 0
                % Clear data from expected paths from this stage onwards
                % Not using a force parameter to redo, rather, deleting
                % processing that has already been done before running.
                % Note path getting is different from rest of class, might
                % need standardising.
                disp(['Warning, deleting stage ', ...
                    num2str(obj.force), ' onwards: ']);
                
                if obj.force <= 1
                    d = obj.neuralPaths.Extracted;
                    disp(['Deleting: ', d])
                    if exist(d, 'file')
                        rmdir(d, 's')
                    end
                end
                
                if obj.force <= 2
                    d = obj.neuralPaths.Filtered;
                    disp(['Deleting: ', d])
                    if exist(d, 'file')
                        rmdir(d, 's')
                    end
                end
                
                if obj.force <= 3
                    d = obj.neuralPaths.Epoched;
                    disp(['Deleting: ', d])
                    if exist(d, 'file')
                        rmdir(d, 's')
                    end
                end
                
                if obj.force <= 4
                    d = obj.neuralPaths.Spikes;
                    disp(['Deleting: ', d])
                    if exist(d, 'file')
                        rmdir(d, 's')
                    end
                end
                
            end
        end
        
        function fs = getFs(obj, EvID)
            % Get fs from EvID params in TDT object. Nested cells. Urgh.
            for e = 1:numel(obj.extractionObject.evIDs)
                if strcmp(obj.extractionObject.evIDs{e}{1}, EvID)
                    fs = obj.extractionObject.evIDs{e}{3};
                end
            end
        end
        
        function path = getEpochedDataPath(obj, EvID, type)
            % Get the expected save path for the filtered data
            
            % Generate save path from extraction paths. Here one file for
            % all channels.
            switch EvID
                case {'BB_2', 'BB_3'}
                    fns = obj.processingPaths(...
                        obj.processingPaths.contains(EvID));
                    fn = fns(fns.contains(type));
                    path = fn.replace('\Processing\', '\Epoched\');
                case {'Sens', 'Sond'}
                    % Need to get these from extractedPaths, as no
                    % processing path
                    % Create a processing path without making it
                    fns = obj.extractionPaths(...
                        obj.extractionPaths.contains(EvID));
                    fn = fns(1);
                    fn = fn.replace('_Chan_1', '_Chan_All');
                    path = fn.replace('\Extracted\', '\Processing\');
                    
                    % And convert it to an epoch path
                    path = path.replace('\Processing\', '\Epoched\');
            end
            
            % Create the save folder if it doesn't exist
            folder = fileparts(path.char());
            if ~exist(folder, 'file')
                mkdir(folder)
            end
            
        end
        
        function path = getSpikesDataPath(obj, EvID, type)
            % Get the expected save path for the filtered data
            
            fns = obj.extractionPaths(...
                obj.extractionPaths.contains(EvID));
            fn = fns(1);
            fn = fn.replace('_Chan_1.', ['_', type, '_Chan_All.']);
            path = fn.replace('\Extracted\', '\Spikes\');
            
            % Create the save folder if it doesn't exist
            folder = fileparts(path.char());
            if ~exist(folder, 'file')
                mkdir(folder)
            end
            
        end
        
        function path = getFilteredDataPath(obj, EvID, type)
            % Get the expected save path for the filtered data
            
            % Generate save path from extraction paths. Here one file for
            % all channels.
            fns = obj.extractionPaths(obj.extractionPaths.contains(EvID));
            fn = fns(1);
            fn = fn.replace('_Chan_1', ['_', type, '_Chan_All']);
            path = fn.replace('\Extracted\', '\Processing\');
            
            % Create the save folder if it doesn't exist
            folder = fileparts(path.char());
            if ~exist(folder, 'file')
                mkdir(folder)
            end
            
        end
        
        function [data, fs, ok] = loadAndFsVerify(obj, fn, EvID)
            % Check file is available
            % Load data and fs
            % Verify fs? Removed for now.
            
            % Check fn is available
            if exist(fn, 'file')
                ok = true;
            else
                ok = false;
                data = [];
                fs = [];
                return
            end
            
            % Load
            disp(['Loading ', fn])
            data = load(fn);
            fs = data.fs;
            data = data.data;
            
            % Find fs
            fs_ = getFs(obj, EvID);
            
            % Verify fs
            if fs ~= fs_
                % Removed - might be different (eg. downsampled lfp)
            end
        end
        
        function [data, fs, ok] = loadExtractedData(obj, EvID)
            % Use method from TDT object
            [data, ok] = obj.extractionObject.loadEvID(EvID);
            
            % Find fs
            fs = getFs(obj, EvID);
        end
        
        function [data, fs, ok] = loadFilteredData(obj, EvID, type)
            % Load filtered data from \Processing\:
            % EvID = BB_2 or BB_3
            % type = fData or lfpData
            % Other EvIDs are not filtered and should be loaded with
            % .loadExtractedData
            
            fIdx = obj.processingPaths.contains(EvID) ...
                & obj.processingPaths.contains(type);
            fn = obj.processingPaths(fIdx).char();
            
            % Load
            [data, fs, ok] = loadAndFsVerify(obj, fn, EvID);
            
        end
        
        function [data, fs, ok] = loadEpochedData(obj, EvID, type)
            % Load epoched data from \Epoched\:
            % EvID = BB_2 or BB_3
            % type = fData or lfpData
            
            switch EvID
                case {'BB_2', 'BB_3'}
                    fIdx = obj.epochedPaths.contains(EvID) ...
                        & obj.epochedPaths.contains(type);
                case {'Sens', 'Sond'}
                    fIdx = obj.epochedPaths.contains(EvID);
                    
            end
            fn = obj.epochedPaths(fIdx).char();
            
            % Load
            [data, fs, ok] = loadAndFsVerify(obj, fn, EvID);
            
        end
        
        function [data, fs, ok] = loadSpikeData(obj, EvID, type)
            % Load spike data from \Spikes\:
            % EvID = BB_2 or BB_3
            % type = G or K
            % .loadExtractedData
            
            % Number of EvIDs requested
            if isa(EvID, 'char')
                nE = 1;
            else % Should be cell array
                nE = numel(EvID);
            end
            
            if nE == 1
                % Just one requested, load
                
                fIdx = obj.spikePaths.contains(EvID) ...
                    & obj.spikePaths.contains(type);
                fn = obj.spikePaths(fIdx).char();
                
                % Load
                [data, fs, ok] = loadAndFsVerify(obj, fn, EvID);
                
            else
                % More than one requested, load and concatonat on channel
                % dimension
                loaded = cell(1,2);
                for n = 1:nE
                    fIdx = obj.spikePaths.contains(EvID(n)) ...
                        & obj.spikePaths.contains(type);
                    
                    fn = obj.spikePaths(fIdx).char();
                    
                    % Load
                    [loaded{n}, fs, ok] = ...
                        loadAndFsVerify(obj, fn, EvID{n});
                end
                % Concat
                data = [loaded{1,1}, loaded{1,2}];
                
            end
            
        end
        
        function [data, fs, ok] = ...
                loadSpikeDataFromAnalysis(obj)
            % This is an alternative to Neural.loadSpikeData. For combo
            % sessions, the data is no longer loaded from from \Spikes\,
            % but from the already-concatenated (on channels and sessions)
            % version saved in Analysis.mat, so load from there instead.
            % This function overloads Sess.loadSpikeData
            
            data = [];
            ok = false;
            try
                fs = obj.neuralParams.Fs;
            catch
                fs = 24414.0625;
            end
            
            if ~isempty(obj.analysisPath)
                load([obj.analysisPath]);
                data = a.spikes;
                ok = true;
            end
        end
        
        function [data] = loadFromAnalysis(obj, var)
            % Load individual variables, or presets.
            % Return as variable or structre.
            % NOTE: Replaceing with get methods in NeuralObj.recOK
            
            switch var
                case 'OK'
                    % Load OK variables, return in structure
                    data = load(obj.analysisPath, 'recOK', 'stimOK');
                case 'OKIdx'
                    % Return overall ok index from recOK and stimOK
                    a = loadFromAnalysis(obj, 'OK');
                    % Set indexes to use
                    data = a.stimOK.OK & a.recOK.OK;
                otherwise
                    % Load requested variable, return as variable
                    a = load(obj.analysisPath, var);
                    data = a.(var);
            end
        end
        
        % Write functions - may turn out to be redundent 
        function path = writeFilteredData(...
                obj, data, EvID, type, fs)  %#ok<INUSL,INUSD>
            % Save file for EvID and of type fData (spikes) or lfpData
            path = getFilteredDataPath(obj, EvID, type);
            
            % fs should be specificed as it might have been downsampled
            
            % Save data to file. Keep the variable name data, for
            % simplicity when loading.
            save(path.char(), 'data', 'fs')
        end
        
        function path = writeSpikeData(...
                obj, data, EvID, type, fs) %#ok<INUSL,INUSD>
            % Save file for EvID and of type fData (spikes) or lfpData
            path = getSpikesDataPath(obj, EvID, type);
            
            % Save data to file. Keep the variable name data, for
            % simplicity when loading.
            save(path.char(), 'data', 'fs')
        end
        
        function path = writeEpochedData(...
                obj, data, EvID, type, fs) %#ok<INUSL,INUSD>
            % Save epoched file
            path = getEpochedDataPath(obj, EvID, type);
            
            % Save data to file. Keep the variable name data, for
            % simplicity when loading.
            save(path.char(), 'data', 'fs')
        end
        
        function obj = process(obj, behav)
            % Run through all processing
            % Need to handle data not available from earlier stage (?)
            % Stage 1: Extraction
            % Stage 2: Filtering
            % Stage 3: Epoching and cleaning. Cleaning done after epoching
            % to avoid windowing killing spikes or not-windowing 
            % propagating noise in long sessions.
            % Stage 4: Spike extraction.
            % Stage 5: Checking recording quality and stimulus
            % presentation. Save useable index of epochs to analysisFile
            % (and this object?)
            

            % Stage 1
            % Always run stage 1 - TDT object handles already done, and
            % recreates object to use for loading
            % Run extraction: .TDT -> extracted
            TDT = TDTHelper(obj.neuralPaths.TDT, ...
                obj.neuralPaths.Extracted);
            ok = runExtraction(TDT);
            % Save TDTHelper object for reference and for loading
            % methods
            obj.extractionObject = TDT;
            % Move extraction paths to .extraionPaths
            obj.extractionPaths = obj.extractionObject.extractionPaths;
            % Update stage
            if ok
                obj.stage = 1;
            end
            
            % Stage 2
            % Run PP - filter for LFP and spikes. No cleaning yet.
            EvIDs = {'BB_2', 'BB_3'};
            obj = PP(obj, EvIDs);
            % Update stage
            obj.stage = 2;
            
            % Stage 3 - epoch and clean
            if obj.stage < 3
                % Epoch
                EvIDs = {'BB_2', 'BB_3', 'Sond', 'Sens'};
                
                % Use Neural.epochAndClean to handle running epochData on
                % multiple EvIDs.
                obj = epochAndClean(obj, EvIDs, behav);
                
                % Update stage
                obj.stage = 3;
            end
            
            % Stage 4 - get events
            % Save these in to \Spikes\
            if obj.stage < 4
                % Here
                EvIDs = {'BB_2', 'BB_3'};
                obj = processSpikes(obj, EvIDs);
                obj.stage = 4;
            end
            
            % Stage 5 - prepNeural
            obj = prepNeural(obj);
        end
        
        function obj = PP(obj, EvIDs)
            % Run PP on neural data
            % Assuming, for now, broadband only ie. BB_1 and BB_2.
            
            nP = numel(EvIDs);
            for e = 1:nP
                id = EvIDs{e};
                
                % Check to see if this EvID has been done (both lfp and
                % spikes)
                obj.processingPaths{1,e} = ...
                    getFilteredDataPath(obj, id, 'fData');
                obj.processingPaths{2,e} = ...
                    getFilteredDataPath(obj, id, 'lfpData');
                
                if exist(obj.processingPaths{1,e}.char(), 'file') ...
                        && exist(obj.processingPaths{2,e}.char(), 'file')
                    % Both files already exist, skip
                    disp([id, ' already done.'])
                    continue
                end
                
                disp(['Working on ', id])
                
                % Load data
                [data, fs, ok] = obj.loadExtractedData(id);
                % Stop if data is not available
                if ~ok
                    disp('Extracted TDT data is not available.')
                    continue
                end
                
                % Filter
                [fData, lfpData] = obj.filter(data, fs);
                
                % Resample LFP
                fsNew = 1000; % Temp fixed
                [lfpData, fsNew] = Neural.resampleLFP(lfpData, fs, fsNew);
                
                % Save to disk
                writeFilteredData(obj, ...
                    fData, id, 'fData', getFs(obj, id));
                writeFilteredData(obj, ...
                    lfpData, id, 'lfpData', fsNew);
            end
            
            % Convert processing paths to string
            obj.processingPaths = string(obj.processingPaths);
        end
        
        function obj = processSpikes(obj, EvIDs)
            % Run spike detection specified in obj.neuralParams.evMode
            % Input here will be epoched BB_2 or BB_3
            
            % Set paths
            obj.spikePaths = ...
                [getSpikesDataPath(obj, 'BB_2', 'G'); ...
                getSpikesDataPath(obj, 'BB_3', 'G'); ...
                getSpikesDataPath(obj, 'BB_2', 'K'); ...
                getSpikesDataPath(obj, 'BB_3', 'K')];
            
            % Set function to use
            % Ignoring obj.neuralParams.evMode and doing G and K
            
            % For each EvID
            for e = 1:numel(EvIDs)
                close all
                id = EvIDs{e};
                
                % Check done
                if exist(char(getSpikesDataPath(obj, id, 'G')), 'file') ...
                        && ...
                        exist(char(getSpikesDataPath(obj, id, 'K')), ...
                        'file')
                    disp([id, ' skipping spikes, already done.'])
                    continue
                end
                
                disp([id, ' getting spikes.'])
                % Load
                [fData, fs, ok] = loadEpochedData(obj, id, 'fData');
                % Check if required data is available
                if ~ok
                    disp('Epoched data is not available.')
                    continue
                end
                
                % Get events G
                inputs.plotOn = true;
                inputs.thresh = obj.neuralParams.GDetectThresh;
                inputs.reject = obj.neuralParams.GDetectReject;
                events = Neural.eventDetectG(fData, inputs);
                writeSpikeData(obj, events, id, 'G', fs)
                clear inputs
                
                inputs.plotOn = true;
                inputs.medThresh = obj.neuralParams.medianThresh;
                inputs.artThresh = obj.neuralParams.artThresh;
                events = Neural.eventDetectK(fData, inputs);
                writeSpikeData(obj, events, id, 'K', fs)
                clear inputs
            end
            
        end
        
        function obj = prepNeural(obj, force)
            
            % If neural data from previous stage is not available, don't
            % run
            % Load
            [sp, ~, ok] = loadSpikeData(obj, {'BB_2', 'BB_3'}, 'K');
            % Check if required data is available
            if ~ok
                disp('Spike data not available, skipping.')
                return
            end
            
            % Set analysis path
            obj.analysisPath = obj.neuralPaths.Analysis;
           
            % If exist delete for now - ignoring force - no warning!
            % if exist([obj.analysisPath, 'Analysis.mat'], 'file')
            %     delete([obj.analysisPath, 'Analysis.mat'])
            % end
            
            if ~exist(obj.neuralPaths.Analysis, 'file')
                mkdir(obj.neuralPaths.Analysis)
            end
            
            % Create a file to append to
            a.spikes = sp; %#ok<STRNU>
            save([obj.analysisPath, 'Analysis.mat'], 'a', '-v7.3')
            
            % Run analysis
            % Stage 5 - checking
            if obj.stage < 5
                % Saves indexes to Analysis.mat - recOK.OK, stimOK.OK.
                
                % Check condition of recorded data - unplugs, correct
                % orientation, etc. - recOK
                % Loads from spike folder, 
                % saves to analysis file not object
                obj = obj.checkRecording('K');
                
                % Check stimuli channels - correct stimuli presented? ect.
                % - stimOK
                obj = obj.checkStimuli();
                
                obj.stage = 5;
            end
        end
        
        function recOK = get.recOK(obj)
            % RecOK always comes from .Analysis
            % Load and return, or return single failure for unavailable
            % data
            if exist([obj.analysisPath, 'Analysis.mat'], 'file')
                recOK = load([obj.analysisPath, 'Analysis.mat'], 'recOK');
                recOK = recOK.recOK;
            else
                recOK = false;
            end
            
        end
        
        function spikes = get.spikes(obj)
            
            if isempty(obj.spikes)
                if obj.stage < 6
                    % Load from library
                    [spikes, ~, ~] = ...
                        loadSpikeData(obj, {'BB_2', 'BB_3'}, 'K');
                else
                    % Load from analysis
                    [spikes, ~, ~] = ...
                        loadSpikeDataFromAnalysis(obj);
                end
            end
        end
        
        function obj = checkRecording(obj, type)
            % Run checks on recoreded data
            % - Neural epoch checker on spikes
            
            % Load spike data
            % Run neuralEpochChecker
            
            % Pick spikes to use for verification, if not set
            if ~exist('type', 'var')
                type = 'K';
            end
            
            bbs = [2,3];
            evPerEp = cell(2,1);
            OK = cell(2,1);
            ST = cell(2,1);
            for b = 1:2
                bb = ['BB_', num2str(bbs(b))];
                % Load the spike data for both sides
                [BB, ~, ~] = loadSpikeData(obj, bb, type);
                
                % Run neural epoch checker
                [evPerEp{b}, OK{b}, ST{b}, h] = ...
                    obj.epochCheck(BB, true);
                % Save figures 1 and last
                figure(h(1))
                title(bb)
                fn = [obj.analysisPath, 'spikesPerEP_', bb];
                Neural.hgx(fn)
                figure(h(end))
                title([h(end).Children(2).Title.String, '_', bb])
                fn = [obj.analysisPath, 'spikesPerEP_', bb];
                Neural.hgx(fn)
                close all
            end
            
            recOK.OK = [OK{1}, OK{2}]; %#ok<PROPLC>
            recOK.evPerEP = [evPerEp{1}, evPerEp{2}]; %#ok<PROPLC>
            recOK.ST = [ST{1}; ST{2}];  %#ok<STRNU,PROPLC>
            
            % Append to analysis file as concat matrix
            save([obj.analysisPath, 'Analysis.mat'], 'recOK', '-append');
        end
        
        function obj = checkStimuli(obj)
           % Run checks on stimuli to make sure cables were connected as
           % expected
           %
           % Load Sens data
           %
           % Check stimuli on correct channels as indicated by behavioural
           % data
           %
           % Not implemeted yet
           % Temp version:
           
           % Load Sond data
           [sens, ~, ~] = loadExtractedData(obj, 'Sens');
           [sond, ~, ~] = loadExtractedData(obj, 'Sond');
           
           [sens, ~, ~] =  loadEpochedData(obj, 'Sens');
           [sond, ~, ~] =  loadEpochedData(obj, 'Sond');
           
           stimOK.OK = true(1,32,size(sond,3));
           
           % Append to analysis file as concat matrix
           save([obj.analysisPath, 'Analysis.mat'], 'stimOK', '-append');
           
        end
        
        
        
    end
    
    methods (Static)

    end
end
