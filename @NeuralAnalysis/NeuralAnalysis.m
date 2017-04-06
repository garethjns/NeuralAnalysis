classdef NeuralAnalysis < ggraph
    % Nerual analysis methods
    % PSTH
    
    properties
    end
    
    methods
        function obj = NerualAnalysis(obj)
            
            % Add 0.3 colour to colours
            colours = linspecer(6);
            colours = [0.3, 0.3, 0.3; colours];
            
            % Prepare figInfo
            figWidth = 1024;
            figHeight = 768;
            rect = [0 20 figWidth figHeight+20];
            colours = linspecer(6);
            validCondTits = {...
                'All data', ...
                'Auditory only (single)', ...
                'Visual only (single)', ...
                'AV sync (matched)', ...
                'AV async (matched)', ...
                'AV async (vis bonus)', ...
                'AV async (aud bonus)', ...
                'AV async (conflict)' ...
                };
            validCondTitsComp = {...
                'All', ...
                'A', ...
                'V', ...
                'AVsync', ...
                'AVasync', ...
                'VBonus', ...
                'ABonus', ...
                'Conflict' ...
                };
            validCondTitsAlt = {...
                'All data', ...
                'Auditory only', ...
                'Visual only', ...
                'AV sync', ...
                'AV async', ...
                'V bonus', ...
                'A bonus', ...
                'AV async (conflict)' ...
                };
            
            % Package to pass to functions later
            % File name string - before passing
            obj.figInfo.rect = rect; % Figure position/size
            obj.figInfo.colours = colours; % Colours to used in plot
            obj.figInfo.validCondTits = validCondTits; % Titles
            obj.figInfo.validCondTitsComp = validCondTitsComp;
            obj.figInfo.validCondTitsAlt = validCondTitsAlt;
            obj.figInfo.fName = ''; % Subject Name
            obj.figInfo.fns = ''; % Graph file name
            obj.figInfo.titleAppend = ''; % Add this to plot title
        end
        
    end
    
    methods (Static)
        
        [evPerEp, OK, survivedTest, h] = epochCheck(spikes, plotOn)
        
        % [raster, psth] = PSTH(epochedData, behavTimes)
        
        function [raster, tVec] = raster(eSpikes, fs)
            % Expects input time x chan x epoch
            
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
            
        end
        
        function tVec = toMs(nPts, fs)
            tVec = (1:nPts).* (1/fs) * 1000;
        end
        
        function RC = spaceSubPlots(nPlots)
            % Find sensible rows/cols for plot
            [~, RC] = min(abs(nPlots - (1:nPlots).*(1:nPlots)));
            
        end
        
        function [PSTH, tVec2] = PSTH(raster, fs, binSize)
            
            % Generate a time vector in ms
            tVec = NeuralAnalysis.toMs(size(raster, 2), fs);
            
            % Generate PSTH
            % Reduce raster
            PSTH1ms = sum(raster);
            % Remove extra dimension
            PSTH1ms = squeeze(PSTH1ms);
            
            % Round tVec to bin size steps
            tVec2 = round(tVec./binSize).*binSize;
            % Convert to integer bins instead of ms
            [tVec2,~,ac] = unique(tVec2);
            
            PSTH = NaN(length(tVec2), size(raster,3));
            for c = 1:size(raster,3)
                PSTH(:,c) = accumarray(ac, PSTH1ms(:,c));
            end
        end
        
        function h = plotPSTH(PSTH, tVec)
            % Get nEpochs and nChans
            nC = size(PSTH, 2);
            
            % Find sensible rows/cols for plot
            spRC = NeuralAnalysis.spaceSubPlots(nC);
            
            h = figure;
            for c = 1:nC
                subplot(spRC, spRC, c)
                plot(tVec, PSTH(:,c))
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