classdef NeuralAnalysis < ggraph
    % Nerual analysis methods
    % This object is not specific to any analysis. 
    %
    % Includes:
    % epochChecker - find bad channels/trials
    % raster, PSTH
    % plot raster, PSTH
    
    properties
    end
    
    methods
        function obj = NerualAnalysis(obj)
            
        end
        
    end
    
    methods (Static)
        
        [evPerEp, OK, survivedTest, h] = epochCheck(spikes, plotOn)
        
        % [raster, psth] = PSTH(epochedData, behavTimes)
        
        function [raster, tVec, nEpochs] = raster(eSpikes, fs)
            % Expects input [time x chan x epoch]
            % Output raster is [epochs x time x chans]
            % Calculates and returns non-NaN n included in raster in
            % nTrials [1x chans]
            
            % If fs is specified, generate a time vector in ms
            nT = size(eSpikes, 1);
            if exist('fs', 'var')
                tVec = NeuralAnalysis.toMs(nT, fs);
            else
                % Else retrun list of points
                tVec = 1:nT;
            end
            
            % Generate raster by rearranging to epoch x time
            raster = permute(eSpikes, [3,1,2]);
            
            % Count good epochs
            % Kill time dimension; if any NaNs, return NaN. Should either
            % be all number or all NaNs...
            eMean = mean(raster,2);
            nEpochs = permute(sum(~isnan(eMean)), [1,3,2]);

        end
        
        function tVec = toMs(nPts, fs)
            tVec = (1:nPts).* (1/fs) * 1000;
        end
        
        function RC = spaceSubPlots(nPlots)
            % Find sensible rows/cols for plot
            [~, RC] = min(abs(nPlots - (1:nPlots).*(1:nPlots)));
            
        end
        
        function [PSTH, tVec2] = PSTH(raster, fs, binSize)
            % Create PSTH from raster using specified binSize.
            % Input raster should be [epochs x time x chans]
            
            nE = size(raster, 1);
            nC = size(raster, 3);
            
            % Generate a time vector in ms
            tVec = NeuralAnalysis.toMs(size(raster, 2), fs);
            
            % Generate PSTH
            % nansum returns zeros for all NaNs
            % >0 for some nans, no nans - refer to nEpochs from raster to
            % check actual n
            
            PSTH1ms = nansum(raster, 1);
            
            % Remove extra dimension
            PSTH1ms = squeeze(PSTH1ms);
            
            if nC==1
                PSTH1ms = PSTH1ms';
            end
            
            % Round tVec to bin size steps
            tVec2 = round(tVec./binSize).*binSize;
            % Convert to integer bins instead of ms
            [tVec2, ~, ac] = unique(tVec2);
            
            PSTH = NaN(length(tVec2), size(raster,3));
            for c = 1:size(raster,3)
                PSTH(:,c) = accumarray(ac, PSTH1ms(:,c));
            end
        end
        
        function h = plotPSTH(PSTH, tVec, nEpochs, col)
            % Plot PSTH on specficed timeVec (second output from PSTH).
            % nEpochs (non-NaN n from raster) and col are optional inputs 
            % for adding to graph
            
            % Get nChans
            nC = size(PSTH, 2);
           
            % Set nEpochs if provided - just used to write n on plot
            if exist('nEpochs', 'var') && ~isempty(nEpochs)
                if length(nEpochs) == 1
                    % Assume all the same
                    nE = repelem(string(nEpochs), nC);
                else
                    % Assume non-nan n from raster
                    nE = string(nEpochs);
                end
            else
                nE = repelem(string('?', nC));
            end
            
            % Set colour
            if ~exist('col', 'var')
                % Set plot colour
                col = 'b';
            end
            
            % Find sensible rows/cols for plot
            spRC = NeuralAnalysis.spaceSubPlots(nC);
            
            h = figure;
            for c = 1:nC
                subplot(spRC, spRC, c)
                plot(tVec, PSTH(:,c), 'color', col)
                
                % Check n, write 0 to plot if PSTH is NaNs
                
                legend(['c=', num2str(c), ', n=', nE(c).char])
            end
       end
        
        function h = plotRaster(raster, fs)
            % Get nEpochs and nChans
            nC = size(raster, 3);
            
            % Find sensible rows/cols for plot
            spRC = NeuralAnalysis.spaceSubPlots(nC);
            
            % If fs is supplied, convert xaxis to ms
            if ~exist('fs', 'var')
                 fs = 1000;
            end
            
            h = figure;
            for c = 1:nC
                hAx = subplot(spRC, spRC, c);
                imagesc(raster(:,:,c))
                hAx.XTickLabels = round(hAx.XTick./fs .* 1000, -3);
            end
        end
        
        
    end
    
end