classdef BehavAnalysis < ggraph
    % Container for behav analysis methods.
    % This object is specific to this analysis.
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
        
    function col = typeColour(obj, type)
         % Get colour for type from obj.figInfo
         % For [2,3,4] just returns corresponding row. 
         % For offsets/AsMs in 5, extend to return spread of colours (not
         % added yet)
         col = obj.figInfo.colours(type,:);
    end
    
    end
    
    
    methods (Static)
        
        function [uR, nR] = unqRates(behavData)
            % From table of behavioural data, return unique rates from A
            % and V, removing NaNs.
            uR =  unique([behavData.nEventsA; behavData.nEventsV]);
            uR = uR(~isnan(uR));
            nR = numel(uR);
        end
        
        function rateIdx = setRateIdx(behavData, rate)
            % From table of behavioural data, return index where either A
            % or V matches specified rate.
            % Makes sense for [2,3,4,5] as rates always match.
            % Required because [2,3] have NaNs for off-modality.
            % Will work if rates don't match, but need to be careful with
            % overlap
            rateIdx = any(...
                [behavData.nEventsA==rate, behavData.nEventsV==rate], ...
                2);
        end
        
        function str = stimDetailsRow(behavRow)
           % From a single stim, return string of basic information using
           % data from row but not struct
           % Checking type, nEvents, not: seed, noise.
           
           % Get number of events
           switch behavRow.Type
               case 3
                   ev = behavRow.nEventsV;
               case {2, 4, 5}
                   ev = behavRow.nEventsA;
               otherwise
                   % Non-matching rates, not added yet
           end
           
           str = string(...
               {'T:', num2str(behavRow.Type); ...
               'R:', num2str(ev)}...
               );
        end
        
        function str = stimDetailsStruct(stim)
            % From a stim structure, return basic information as str
                      
            if ~isstruct(stim)
                str = '';
                return
            end
            
            % Create string for each stim
            str = string(...
                {'T:', num2str(stim.type); ...
                'R:', num2str(stim.nEvents);...
                'S:', num2str(stim.seed.Seed);...
                'GI:', string(stim.gap_index).join('')...
                });
            
            % Create combined string - verify on multisensory
            
        end
        
        function [ok, str] = stimCheck(behavTrials)
           % From a behavioural table, check stim for rows are all the same
           % eg for behavTrials(trialIdx,:)
           
           nT = height(behavTrials);
           
           list = cell(1);
           
           for r = 1:nT
               % Row verifcation
               str1 = ...
                   BehavAnalysis.stimDetailsRow(behavTrials(r,:));
               
               % Aud verification
               strA = ...
                   BehavAnalysis.stimDetailsStruct(behavTrials.aStim{r,:});
               % Vis verification
               strV = ...
                   BehavAnalysis.stimDetailsStruct(behavTrials.vStim{r,:});
               
               % Recheck type and update Aud and Vis verification types
               if ~isempty(strA) && isempty(strV)
                   % Aud
                   strAV = strA;
                   strAV(1,2) = 2;
               elseif isempty(strA) && ~isempty(strV)
                   % Vis
                   strAV = strV;
                   strAV(1,2) = 3;
               elseif isempty(strA) && ~isempty(strV)
                   % AV
                   if (strA(3,2) == strV(3,2)) ...
                           && (strA(2,2) == strV(2,2))
                       % Seeds match, events match sync
                       strAV = strA;
                       strAV(1,2) = 4;
                   elseif (strA(3,2) ~= strV(3,2)) ...
                           && (strA(2,2) == strV(2,2))
                       % Seeds don't match, events match async
                       strAV = strA;
                       strAV(1,2) = 5;
                   else
                       % ??
                       keyboard
                   end
               end
               
               % Check row matches stuct
               if str1(1,2) ~= strAV(1,2) ...
                       || str1(2,2) ~= strAV(2,2) 
                   keyboard
               end
               
               % Save to list of stim
               list{1,r} = strAV;
           end
           
           % Check all match in list
           
        end
               
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