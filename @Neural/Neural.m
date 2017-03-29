classdef Neural < ggraph
    % Takes Sess as input, which contains paths to neural data and
    % behavioural data
    % Extract neural data (using TDTHelper) to \extracted\block\
    % Pre-process:
    % Filter (using
    % https://uk.mathworks.com/matlabcentral/fileexchange/17061-filtfilthd)
    % to \processing\block\
    % Epoch THEN clean:
    % to \epoched\block\
    % Extract events -> AnalysisFile
    % to \spikes\block\
    %
    % Add PSTH etc as methods here?
    %
    % Plan is for Sess to load data as needed (using methods here) then do
    % analysis (using methods here?).
    % ComboSesh can use then use the same methods to do the combined
    % analysis.
    %
    % TO DO
    % Add event detection, path setting, saving etc.
    
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
        neuralParams
        force = 0 % Force processing from stage onwards, or 0 for off
        
    end
    
    properties (Hidden = true)
        extractionObject
        extractedData = []
        filteredData = []
        epochedData = []
    end
    
    methods
        function obj = Neural(sess)
            % Paths contain .TDT, .Extracted, PreProFilt, .Epoch, .Analysis
            obj.neuralPaths = sess.neuralPaths;
            obj.neuralParams = sess.subjectParams.PP;
            % Add here a set stage function - needs to check which files
            % already exist
            
            obj.force = sess.forceNeural;
            if obj.force > 0
                obj.clearStageOn
            end
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
            fn = fn.replace('_Chan_1_', [type, '_Chan_All']);
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
        
        function [data, fs] = loadAndFsVerify(obj, fn, EvID)
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
                % keyboard
            end
        end
        
        function [data, fs] = loadExtractedData(obj, EvID)
            % Use method from TDT object
            data = obj.extractionObject.loadEvID(EvID);
            
            % Find fs
            fs = getFs(obj, EvID);
        end
        
        function [data, fs] = loadFilteredData(obj, EvID, type)
            % Load filtered data from \Processing\:
            % EvID = BB_2 or BB_3
            % type = fData or lfpData
            % Other EvIDs are not filtered and should be loaded with
            % .loadExtractedData
            
            fIdx = obj.processingPaths.contains(EvID) ...
                & obj.processingPaths.contains(type);
            fn = obj.processingPaths(fIdx).char();
            
            % Load
            [data, fs] = loadAndFsVerify(obj, fn, EvID);
            
        end
        
        function [data, fs] = loadEpochedData(obj, EvID, type)
            % Load filtered data from \Processing\:
            % EvID = BB_2 or BB_3
            % type = fData or lfpData
            % Other EvIDs are not filtered and should be loaded with
            % .loadExtractedData
            
            switch EvID
                case {'BB_2', 'BB_3'}
                    fIdx = obj.epochedPaths.contains(EvID) ...
                        & obj.epochedPaths.contains(type);
                case {'Sens', 'Sond'}
                    fIdx = obj.epochedPaths.contains(EvID);
                    
            end
            fn = obj.epochedPaths(fIdx).char();
            
            % Load
            [data, fs] = loadAndFsVerify(obj, fn, EvID);
            
        end
        
        % Write functions - may turn out to be redundent 
        function path = writeFilteredData(obj, data, EvID, type, fs)  %#ok<INUSL,INUSD>
            % Save file for EvID and of type fData (spikes) or lfpData
            path = getFilteredDataPath(obj, EvID, type);
            
            % fs should be specificed as it might have been downsampled
            
            % Save data to file. Keep the variable name data, for
            % simplicity when loading.
            save(path.char(), 'data', 'fs')
        end
        
        function path = writeSpikeData(obj, data, EvID, type, fs) %#ok<INUSL,INUSD>
            % Save file for EvID and of type fData (spikes) or lfpData
            path = getSpikesDataPath(obj, EvID, type);
            
            % Save data to file. Keep the variable name data, for
            % simplicity when loading.
            save(path.char(), 'data', 'fs')
        end
        
        function path = writeEpochedData(obj, data, EvID, type, fs) %#ok<INUSL,INUSD>
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
            % Stage 3: Epoching
            % Stage 4: Cleaning. Cleaning done after epoching to avoid
            % windowing killing spikes or not-windowing propagating noise
            % in long sessions.
            
            % Stage1
            % Always run stage 1 - TDT object handles already done, and
            % recreates object to use for loading
            % Run extraction: .TDT -> extracted
            TDT = TDTHelper(obj.neuralPaths.TDT, ...
                obj.neuralPaths.Extracted);
            runExtraction(TDT);
            % Save TDTHelper object for reference and for loading
            % methods
            obj.extractionObject = TDT;
            % Move extraction paths to .extraionPaths
            obj.extractionPaths = obj.extractionObject.extractionPaths;
            % Update stage
            obj.stage = 1;
            
            % Stage 2
            % Run PP - filter for LFP and spikes. No cleaning yet.
            EvIDs = {'BB_2', 'BB_3'};
            obj = PP(obj, EvIDs);
            % Update stage
            obj.stage = 2;
            
            % Behavioural times required from this point on. Don't continue
            % if not available
            if ~exist('behav', 'var') || isempty(behav)
                return
            end
            
            % Stage 3 - epoch and clean
            if obj.stage < 3
                % Epoch
                EvIDs = {'BB_2', 'BB_3', 'Sond', 'Sens'};
                obj = epochAndClean(obj, EvIDs, behav);
                
                % Update stage
                obj.stage = 3;
            end
            
            % Stage 4 - get events
            % Save these in to \Spikes\
            if obj.stage < 4
                % Here
                EvIDs = {'BB_2', 'BB_3'};
                obj = spikes(obj, EvIDs);
                obj.stage = 4;
            end
            
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
                [data, fs] = obj.loadExtractedData(id);
                
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
        
        function obj = spikes(obj, EvIDs)
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
                [fData, fs] = loadEpochedData(obj, id, 'fData');
                
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
        
    end
    
    methods (Static)
        
        function spikes = eventDetectG(data, inputs)
            % Unpack inputs
            % Note, may contain second value in each field - not using
            thresh = inputs.thresh(1);
            reject = inputs.reject(1);
            plotOn = inputs.plotOn;
            
            % Detect events based on RMS
            RMS = rms(data);
            thr = thresh.*RMS; % Used for events and plotting
            thrArt = reject.*RMS;
            % Don't use abs(data) to avoid detecting both phases
            spikes = data>thr & data<thrArt;
            
            
            % Verification plot
            Neural.eventPlot(data, spikes, thr, thrArt, plotOn, [10, 10]);
        end
        
        function [spikes, artThresh] = eventDetectK(data, inputs)
            
            % Unpack inputs
            medianThresh = inputs.medThresh;
            artThresh = inputs.artThresh;
            plotOn = inputs.plotOn;
            noiseThresh = 0.6745;
            
            % For each chan, epoch
            % bsxfun should work here regardless of nChans and nEpochs
            sigStd = median(abs(data)./noiseThresh);
            thr = medianThresh.*sigStd;
            thrArt = artThresh.*sigStd;
            
            % Get > thr
            sp = bsxfun(@gt, data, thr);
            % Get > thrArt
            rj = bsxfun(@gt, data, thrArt);
            % Drop above > theArt
            spikes = sp & ~rj;
            
            % To check:
            % Alternative code. This does the same - but won't work in
            % versions of MATLAB before 2016b due to lack of support of
            % implicit expansion?
            % spikes2= (data > thr) & (data < thrArt);
            
            % Verification plot
            Neural.eventPlot(data, spikes, thr, thrArt, plotOn, [10, 10])
            
        end
        
        function h = eventPlot(data, spikes, thr, thrArt, plotOn, dims)
            if ~plotOn
                return
            end
            
            h = figure;
            
            if exist('dims', 'var')
                % Plot specified channel/epoch
                c = dims(1);
                e = dims(2);
            else
                % Plot a random channel/epoch
                e = randi(size(data, 3));
                c = randi(size(data, 2));
            end
            
            % Plot original data
            plot(data(:,c,e) , 'color', 'k')
            hold on
            % Plot spikes
            plot((spikes(:,c,e)*10)', 'color', [0, 0.447, 0.741])
            % Plot above thr_art
            plot(data(:,c,e)>thrArt(:,c,e)*10, 'color', 'r')
            % Draw reject threshold
            line([1, length(data(:,c,e))*1.1], ...
                [thrArt(:,c,e), thrArt(:,c,e)], ...
                'color', 'r', 'LineStyle', '--')
            % Draw event threshold
            line([1, length(data(:,c,e))*1.1], ...
                [thr(:,c,e), thr(:,c,e)], ...
                'color', 'k', 'LineStyle', '--')
            
            title([num2str(sum(spikes(:,c,e))), ' events'])
            axis([0, length(data(:,c,e))*1.3, ...
                -abs(max(data(:,c,e))*1.1), ...
                abs(max(data(:,c,e))*1.1)])
            xlabel('Time, pts')
            ylabel('Mag')
            % Create legend
            leg = { ...
                'Original Data', ...
                ['EventInds: ', ...
                num2str(sum(spikes(:,c,e)))], ...
                ['RejectInds: ', ...
                num2str(sum(data(:,c,e)>thrArt(:,c,e)))], ...
                ['Reject thresh: ', ...
                num2str(round(thrArt(:,c,e),1))], ...
                ['Event thresh: ', ...
                num2str(round(thrArt(:,c,e),1))], ...
                };
            legend(leg);
            Neural.ng('eventPlot');
            
            drawnow
            
        end
        
        function cleanData = clean(fData)
            % Clean every epoch of fData (1 epoch if data isn't epoched)
            % Need to work in at least singles here.
            
            nEpochs = size(fData,3);
            % Need nChans as CleanData returns two PCA columns.
            nChans = size(fData, 2);
            
            cleanData = NaN(size(fData), 'single');
            for e = 1:nEpochs
                disp(['Epoch ', num2str(e), '/' num2str(nEpochs)])
                cleanDataTmp = Neural.CleanData(single(fData(:,:,e)));
                
                cleanData(:,:,e) = cleanDataTmp(:,1:nChans);
            end
        end
        
        function [fData, lfpData] = filter(data, fs)
            disp('Filtering...')
            
            % Params
            % Spikes
            BPs = [300, 5000];
            % LFP
            BPl = [3, 150];
            
            % Apply both filters
            % Do in parallel if not too big
            info = whos('data');
            par = info.bytes < 0.000000000003*1024*1024*1024; % Disabled
            % parfor slower - fewer cores available to fft and ifft?
            % ~70s vs 73s.
            
            if par
                a = tic;
                out = cell(1,2);
                parfor s = 1:2
                    switch s
                        case 1
                            % Spikes
                            out{s} = Neural.BPFilter(data, fs, BPs);
                        case 2
                            % LFP
                            out{s} = Neural.LFPFilter(data, fs, BPl);
                    end
                end
                fData = out{1};
                lfpData = out{2};
                clear out
                toc(a)
            else
                a = tic;
                % Spikes
                fData = Neural.BPFilter(data, fs, BPs);
                % LFP
                lfpData = Neural.LFPFilter(data, fs, BPl);
                toc(a);
            end
        end
        
        function [fData, tt] = BPFilter(data, Fs, BP)
            % Create filter and apply with filtfilthd
            
            disp([num2str(BP(1)), '-> <-' num2str(BP(2)), ' Hz on ', ...
                num2str(size(data,2)), ' channels'])
            tic
            
            % Create filter
            [b, a] = ellip(6, 0.1, 40, [BP(1),BP(2)]/(Fs/2));
            
            % Filtfilthd expects columns. Removed '-' from here (?)
            % fData = -filtfilthd(b, a, data);
            fData = filtfilthd(b, a, data);
            
            tt = toc;
            disp(['Done in ', num2str(tt), ' S'])
        end
        
        function fData = LFPFilter(data, Fs, BP)
            % Filter for LFP using LFPprocessBand and LFPRemove50
            
            % Band pass
            fData = Neural.LFPProcessBAND(data, Fs, BP(2), BP(1));
            % Band stop
            fData = Neural.LFPRemove50(fData, Fs);
        end
        
        function fData = LFPProcessBAND(data, fs, lowPass, highPass)
            % Filters at frequency lowpass and baseline corrects data
            % (mean)
            
            tic
            disp([num2str(lowPass), '-> <-' num2str(highPass), ' Hz on ', ...
                num2str(size(data,2)), ' channels'])
            
            % Create filter
            Wp = lowPass;
            [z, p, k] = butter(5,[highPass/(fs/2) Wp/(fs/2)]);
            [sos, g] = zp2sos(z, p, k);
            Hd = dfilt.df2tsos(sos, g);
            
            % Filter
            fData = filtfilthd(Hd, data);
            
            % Correct baseline
            % Note change here to maintain integers - baseline shift is
            % very small here as it's already been filtered.
            fData = fData - int16(mean(fData, 1));
            
            tt = toc;
            disp(['Done in ', num2str(tt), ' S'])
        end
        
        function fData = LFPRemove50(data, sampleRate)
            % Remove 50 Hz with BS filter.
            %
            % Assumes there is an additive, constant artifact at that
            % frequency which can be removed by setting
            % the maplitude of f equal to the average amplitude on either
            % side of f.
            tic
            
            chans = size(data, 2);
            disp(['Removing 50 Hz on ', ...
                num2str(chans), ' channels'])
            
            % Use an even number of points
            if mod(size(data, 1), 2)
                data = data(1:end-1,:);
            end
            
            % Frequency range to process
            fStop = [49, 51];
            
            % FFT
            % Need to convert to float here
            spect = fft(single(data));
            
            % Find index (rows) of fStop frequencies
            fIdx = round(fStop/sampleRate * (size(data,1)-1))+1;
            fIdx = fIdx(1):1:fIdx(end);
            
            % Calculate scale factor
            scaleFact = spect(fIdx,:) ...
                ./ mean(cat(3, spect(fIdx-5,:), spect(fIdx+5,:)), 3);
            
            % Apply scale factor
            spect(fIdx,:) = spect(fIdx,:)./scaleFact;
            spect(end-fIdx+2,:) = ...
                spect(end-fIdx+2,:)./scaleFact;
            
            % Inverse FFT
            % Also return to int16
            fData = int16(real(ifft(spect)));
            
            tt = toc;
            disp(['Done in ', num2str(tt), ' S'])
        end
        
        function [fData, fsNew] = resampleLFP(data, fs, fsNew)
            
            % TDT fs may not be integer
            fs = round(fs);
            
            % Resample
            fData = int16(resample(double(data), fsNew, fs));

        end
        
        % http://www.med.upenn.edu/mulab/programs.html
        [out, biglist] = CleanData(action, tdata)
        
    end
end
