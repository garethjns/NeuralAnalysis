classdef TDTHelper
    % Extract from raw TDT data to .mats - .mat per channel
    % Checks if outputs exist before processing, force=true to overwrite.
    properties
        blockName
        blockNum
        evIDs = {...
            {'BB_2', 1:16, 24414.0625, 24414.0625}, ...
            {'BB_3', 1:16, 24414.0625, 24414.0625}, ...
            {'dBug', 1:3, 6103.515625, 6103.515625}, ...
            {'Sens', 1:3, 762.939254, 762.939453}, ...
            {'Sond', 1:3, 762.939254, 762.939453}, ...
            {'Valv', 1:3, 762.939254, 762.939453}, ...
            };
        extractionPaths
    end
    
    properties (Hidden = true)
        force = 0
        outPath
        inPath
    end
    
    methods
        function obj = TDTHelper(inPath, outPath, force)
            % inPath is block folder
            % outPath is extracted\
            
            % Tmp
            % inPath = 'T:\Analysis\Behaving\Temporal\F1403_Snow\Block8-4\';
            % outPath = 'T:\Analysis\Behaving\Temporal\F1403_Snow\Extracted\Block8-4\';
            
            if exist('force', 'var')
               obj.force = force; 
            end
            
            % Extract block name and num from paths
            obj.inPath = string(inPath);
            obj.outPath = string(outPath);
            
            if ~exist(obj.outPath.char(), 'file')
                mkdir(obj.outPath.char())
            end
            
            bn = obj.inPath.extractBetween('Block', '\');
            obj.blockNum = bn.replace('-','.').double();
            
            bn = [string('Block'), bn];
            obj.blockName = bn.join('');
            
            % Set output paths - needed?
            obj.extractionPaths =  obj.generatePaths(outPath, obj.evIDs);
        end
        
        function ok = runExtraction(obj)
            
            % Open connection to tank
            TT = actxcontrol('TTank.X');
            ok = TT.ConnectServer('Local','Me');
            % Open tank
            t = obj.inPath.extractBefore('\Block').char();
            ok = TT.OpenTank(t, 'R');
            % Open block
            ok = TT.SelectBlock(obj.blockName.char());
            
            % Set reading parameters
            nMax    = 500000;
            srtCode = 0; % 0 disregrads sort codes
            Tstart  = 0; % 0 = start of block
            Tend    = 0; % 0 = end of block
            options = 'ALL'; % Get all data
            
            if ~ok 
                % For debugging: This prevents skipping files that aren't 
                % available, which isn't ideal. 
                disp('TDT data not available')
                return
                % Replace with skip on fail?
            end
            
            for e = 1:numel(obj.evIDs)
                id = obj.evIDs{e}{1};
                chans = obj.evIDs{e}{2};
                
                for c = chans
                    outFile = obj.outPath + id + '_Chan_' + c + '.mat';
                    disp(['Extracting ', id, ', Chan_', num2str(c), ...
                        ' to ',  outFile.char()])
                    
                    if exist(outFile.char(), 'file') && ~obj.force
                        % Already done and not set to force
                        disp('Skipping, already done')
                        continue
                    end
                    
                    % Read events
                    ev = ...
                        TT.ReadEventsV(nMax, id, c, srtCode, ...
                        Tstart, Tend, options);
                    
                    % Parse events
                    x = TT.ParseEvV(0, ev);
                    
                    % De-concatenate Parse Event matrix
                    n_x = numel(x);
                    output = reshape(x, n_x, 1); %#ok<NASGU>
                    clear x ev
                    
                    % Write output to disk
                    save(outFile.char(), 'output')
                    
                    clear output
                end
            end
            
            % Close tank
            TT.CloseTank
            TT.ReleaseServer
            clear TT
            pause(0.05)
        end
        
        function [data, ok] = loadEvID(obj, name)
            try % Instead of exist check, for now
                % Load named EvId eg. obj.loadEvID('BB_2')
                disp(['Loading ', name, '...'])
                loadIdx = obj.extractionPaths.contains(name);
                
                loadPaths = obj.extractionPaths(loadIdx);
                nLoad = sum(loadIdx);
                
                % Load first
                d = load(loadPaths(1).char());
                
                % Expect all to be same length, preallocate now as same type
                data = zeros(size(d.output,1), nLoad, class(d.output));
                data(:,1) = d.output;
                
                % Load the rest
                for p = 2:nLoad
                    d = load(loadPaths(p).char());
                    data(:,p) = d.output;
                end
                
                ok = true;
            catch
                % Assuming error here is due to one or more file not being
                % available
                ok = false;
                data = [];
            end
            
        end
        
    end
    
    methods (Static)
        function paths = generatePaths(outPath, evIDs)
            % for each EvID to extract, create a path for the channels
            paths = [];
            for e = 1:numel(evIDs)
                paths = [paths; ...
                    outPath + string(evIDs{e}{1}) + ...
                    '_Chan_' + evIDs{e}{2}' + '.mat']; %#ok<AGROW>
            end
            
       end
    end
    
end

