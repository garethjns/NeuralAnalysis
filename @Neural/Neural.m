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
    end
    
    properties (Hidden = true)
        extractionObject
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
        
        function PP(EvIDs)
            % Run PP on neural data
            nP = numel(EvIDs);
            for e = 1:nP
                id = EvIDs{e};
                data = obj.extractionObject.loadEvIDs(id);
                
            end
            
        end
        
        function [fData, lfpData] = filter(obj, data)
            disp('Filtering...')
            
            % Do in parallel if not too big
            info = whos('data');
            par = info.bytes < 3*1024*1024*1024;
            % Not added yet
            
            %
            BP = [300, 5000];
            fData = Neural.BPFilter(matData, Fs1, BP);
            BP = [3, 150];
            lfpData = Neural.BPFilter(matData, Fs1, BP);
            
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
        
        function [fData, tt] = BPFilter(data, Fs, BP)
            % Create filter and apply with filtfilthd
            
            tic
            
            % Create filter
            [b, a] = ellip(6, 0.1, 40, [BP(1),BP(2)]/(Fs/2));
            
            % Filtfilthd expects columns
            fData = -filtfilthd(b, a, data);
            
            tt = toc;
        end
        
        
        function [fData, tt] = LFPFilter(data, Fs, BP)
            % Filter for LFP using LFPprocessBand and LFPRemove50
            
            tic
            
            dataf = NaN(size(matData));
            for i = 1:size(matData,1)
                disp(['Filtering channel ', num2str(i), ...
                    ': ->', num2str(BP), '<-, Hz'])
                % Vector 1 x Pts
                datafTMP = LFPprocessBAND(matData(i,:), Fs, BP(2), BP(1));
                disp('Removing 50 Hz')
                % Structure: .lfp=original lfp, .lpf2=lfp after 50 removal
                datafTMP2 = LFPremove50(datafTMP, Fs);
                
                dataf(i,:) = datafTMP2.lfp2;
                
                clear datafTMP datafTMP2
            end
            
            tt = toc;
            
        end
        
        function fData = LFPremove50(data, sampleRate)
            % Remove 50 Hz with BS filter.
            %
            %  Assumes there is an additive, constant artifact at that
            %  frequency which can be removed by setting
            %  the maplitude of f equal to the average amplitude on either
            %  side of f.
            
            % Use an even number of points
            if mod(size(data,2), 2)
                data = data(:,1:end-1);
            end
            
            fStop = [49, 50, 51]; 
      
            for ii=1:size(l.lfp,1)
                spect=fft(l.lfp(ii,:));
                % On the absciss of the Discrete Fourrier Transform:
                % 1 step correspond to 1/TotalRecordingTime Hz= sampleRate/Nb
                %Data Hz % => number of steps corresponding to
                %f: f/(sampleRate/NbData) =
                % f*(NbData/sampleRate)
                fIdx=round(f/sampleRate*(length(l.lfp(ii,:))-1))+1;
                fIdx=[fIdx(1):1:fIdx(end)];
                for ff=1:length(fIdx),
                    scaleFact(ff)=spect(fIdx(ff))/mean(spect([fIdx(ff)-5,fIdx(ff)+5]));
                end
                
                % now run through the data and scale down frequency f in the fourier domain
                
                for ff=1:length(fIdx),
                    spect(fIdx(ff))=spect(fIdx(ff))/scaleFact(ff);
                    spect(end-fIdx(ff)+2)=spect(end-fIdx(ff)+2)/scaleFact(ff);
                end;
                l.lfp2(ii,:)=real(ifft(spect));
            end;
            data=l;
        end
        
        function outSig = LFPprocessBAND(inSig, fs, lowPass, highpass)
            % insig should be a trials x times matrix sampled at Fs Hz.
            %filters at frequency lowpass and baseline corrects data
            %resample with jenny_resample
            %JKB 08/09
            
            % low pass freq
            Wp = lowPass;
            [z,p,k] = butter(5,[highpass/(fs/2) Wp/(fs/2)]);
            [sos,g] = zp2sos(z,p,k);
            Hd = dfilt.df2tsos(sos,g);
            
            % and filter with it
            for ii=1:size(inSig,1)
                outSig(ii,:)=filtfilthd(Hd,inSig(ii,:));
                outSig(ii,:)=outSig(ii,:)-mean(outSig(ii,:));
            end
        end
        
    end
    
end