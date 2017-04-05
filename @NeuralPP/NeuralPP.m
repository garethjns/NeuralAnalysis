classdef NeuralPP 
    properties
    end
    methods
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