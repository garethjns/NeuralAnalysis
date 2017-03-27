classdef Neural
    % Takes Sess as input, which contains paths to neural data and
    % behavioural data
    % Extract neural data (using TDTHelper)
    % Pre-process
    % Filter (using
    % https://uk.mathworks.com/matlabcentral/fileexchange/17061-filtfilthd)
    % Clean
    % Save to disk
    % Analysis:
    % Load from disk - either single or combined
    % Epoch - using Sess or ComboSess data
    % PSTH etc.
    
    properties
        neuralPaths % Will get from Sess
        stage % How far processing as got
        blockName
        blockNum
        % Possibly not needed:
        extractionPaths
        processingPaths
        epochedPaths
        analysisPaths
        extractionObject
    end
    
    properties (Hidden = true)
        
    end
    
    methods
        function obj = Neural(sess)
            % Paths contain .TDT, .Extracted, PreProFilt, .Epoch, .Analysis
            obj.neuralPaths = sess.neuralPaths;
            
        end
        
        function obj = process(obj)
            
            % Stage1
            % Run extraction: .TDT -> extracted
            TDT = TDTHelper(obj.neuralPaths.TDT, obj.neuralPaths.Extracted);
            ok = runExtraction(TDT);
            % Save TDTHelper object for reference and for loading methods
            obj.extractionObject = TDT;
            
            
            % Stage2
            % Run PP (filter and clean)
            EvIDs = {'BB_2', 'BB_3'};
            PP(obj, EvIDs)
            
            % Stage3
            % Epoch
            EvIDs = {'BB_2', 'BB_3', 'Sond', 'Sens'};
            
            % Save to disk
            % Shrink
            % Attach to session
        end
        
        function obj = extract(obj)
            % Extract neural data
        end
        
        function PP(obj, EvIDs)
            % Run PP on neural data
            % Assuming, for now, broadband only ie. BB_1 and BB_2.
            
            nP = numel(EvIDs);
            for e = 1:nP
                id = EvIDs{e};
                
                disp(['Working on ', id])
                
                data = obj.extractionObject.loadEvID(id);
                fs = obj.extractionObject.evIDs{e}{3};
                
                % Filter
                [fData, lfpData] = obj.filter(data, fs);
                
                % Here...
            end
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
    
    
    
    methods (Static)
        
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
            
            % Filtfilthd expects columns
            fData = -filtfilthd(b, a, data);
            
            tt = toc;
            disp(['Done in ', num2str(tt), ' S'])
        end
        
        
        function [fData, tt] = LFPFilter(data, Fs, BP)
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
            % Is this correct? For each point in range, take point 5 behind
            % and 5 in front (not between), mean, compare to amp of point.
            % scaleFact = NaN(length(fIdx), chans);
            % nF = length(fIdx);
            % for ff = 1:nF
            %     scaleFact(ff,:) = ...
            %         spect(fIdx(ff),:) ...
            %         ./ mean(spect([fIdx(ff)-5, fIdx(ff)+5],:),1);
            % end
            % Alt - non-loop - faster
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
    end
end
