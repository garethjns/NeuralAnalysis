classdef BehavAnalysis < ggraph
    % Container for behav analysis methods.
    % In prcoess of tidying and updating.
    %
    % Requirements:
    % Inherits ng and hgx from ggraph.
    % Also uses linspecer to make colours
    
    
    properties (Hidden)
        % Handy things, like specific axis labels, condition labels,
        % legends etc. Set in constructor.
        figInfo
    end
    
    methods
        
        function obj = BehavAnalysis()
            
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
        
        % Level macros
        obj = level8(obj)
        obj = level9(obj)
        obj = level10(obj)
        obj = level11(obj)
        
    end
    
    methods (Static)
        
        % Find psychometric threshold
        thresh = threshold(allData, trialInd, figInfo)
        
        % Race model
        raceStats = runRace(RTs)
        
        % Reaction times
        [RTsCI, RTsV] = plotRTs(allData, trialInd, figInfo)
        
        % Calculate percent correct
        PCCor = PCCorrect(allData, trialInd, figInfo);
        
        % Calculate percent correct: Both offset and asm for asyncs
        [PCCorAsM, PCCorOff] = PCCorrectAs(allData, trialInd, figInfo, fParams)
        
        % Plot psychometric curves
        [fastPropFitted, bsAvg] = ...
            plotPsych(allData, fastProp, trialInd, figInfo)
        
        % Plot psychometric curves (async metric)
        [fastPropFitted, bsAvg] = ...
            plotPsychAs(allData, fastProp, trialInd, figInfo, bDiv)
        
        % Calculate fastProp
        fastProp = calcFastProp(allData, trialInd, figInfo)
        
        % Calculate fastProp2
        fastProp = calcFastProp2(allData, trialInd, figInfo, bDiv)

        % Summary statistics - trialInd
        sumStats(allData, trialInd, level, dateRange, figInfo)
        
        % Summary statistics
        overallSummary(allData, level, fPaths)
        
    end
    
end