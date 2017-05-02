function [met, det] = asyncMetric(params, stimA, stimV, varargin)
% Enter stim or cfgs
% Varagrin can contain reneration function
% If varag in is empty, attempt straight compairsion with matching .sounds
% If vararg contains function, regen basic stim with this function

if isempty(varargin)
    % No function speficied, attempt straight comparison
    % (Requires same sampling rate?)
    if (isfield(stimA, 'sound') && ~isempty(stimA.sound)) ...
            && (isfield(stimV, 'sound') && ~isempty(stimV.sound))
        % .sounds exist
        if length(stimA.sound) == length(stimV.sound)
            % And are the same length
            mode = 1; %#ok<NASGU>
            if params.dispOn
                disp('Length of .sounds match, computing comparison at current Fs (A)')
                disp('Not yet implemeted')
            end
            Fs = stimA.Fs; %#ok<NASGU>
            % Not yet implemented: Need to add code to find midpoints
            % correctly. It's more complicated and probably not worth it
            met = NaN; det = NaN;
            return
        else
            if params.dispOn
                disp('Length of .sounds not matched, need to regen')
            end
            met = NaN; det = NaN;
            return
        end
    else
        if params.dispOn
            disp('.sounds ,missing, need to regen')
        end
        met = NaN; det = NaN;
        return
    end
    
else
    % Function speficied, regenerate and compare
    if params.dispOn
        disp('Regen function supplied, regenenerating basic using specificed Fs and comparing')
    end
    C2Fun = varargin{1};
    mode = 2;
    
    Fs = params.Fs;
    
end

%% Regen as is

if mode == 2
    % stimA.sound = [];
    % stimV.sound = [];
    
    if params.dispOn
        % Run with Church2 console outputs enabled
        stimA = C2Fun(stimA);
    else
        % Run silently
        [~, stimA] = evalc('C2Fun(stimA);');
    end
    v1Orig = stimA.sound;
    
    if params.dispOn
        stimV = C2Fun(stimV);
    else
        [~, stimV] = evalc('C2Fun(stimV);');
    end
    v2Orig = stimV.sound;
    
end

%% Regen basic

if mode == 2
    
    stimA.sound = [];
    stimV.sound = [];
    
    
    % Generate simplified auditory stim
    cfgA = stimA;
    cfgA.Fs = Fs;
    cfgA.eventType = 'flat';
    cfgA.noiseType = 'blocked';
    cfgA.eventMag = 1;
    cfgA.mag = 0;
    cfgA.noiseMag = -300;
    cfgA.rise = 0;
    if params.dispOn
        stimA = C2Fun(cfgA);
    else
        [~, stimA] = evalc('C2Fun(cfgA);');
    end
    
    % Generate simplified visual stim
    cfgV = stimV;
    cfgV.Fs = Fs;
    cfgV.eventType = 'flat';
    cfgV.noiseType = 'blocked';
    cfgV.eventMag = 1;
    cfgV.mag = 0;
    cfgV.noiseMag = -300;
    cfgV.rise = 0;
    if params.dispOn
        stimV = C2Fun(cfgV);
    else
        [~, stimV] = evalc('C2Fun(cfgV);');
    end
end


%% Prepare

v1 = stimA.sound;
v2 = stimV.sound;
params.Fs = Fs;


%% Plot

if params.plotOn
    figure
    % v1 Original
    subplot(2,2,1), plot(v1Orig, 'color', [0, 0.45, 0.74])
    title('v1 original')
    ylabel('mag')
    yAdj = (max(v1Orig)-min(v1Orig)) * 0.1;
    ylim([min(v1Orig)-yAdj, max(v1Orig)+yAdj])
    xAdj = length(v1Orig) * 0.05;
    xlim([0-xAdj, length(v1Orig)+xAdj])
    
    % v1 Simplified
    subplot(2,2,3), plot(v1, 'color', [0, 0.45, 0.74])
    title('v1 simplified')
    xlabel('pts')
    ylabel('mag')
    yAdj = (max(v1)-min(v1)) * 0.1;
    ylim([min(v1)-yAdj, max(v1)+yAdj])
    xAdj = length(v1) * 0.05;
    xlim([0-xAdj, length(v1)+xAdj])
    
    % v2 Original
    subplot(2,2,2), plot(v2Orig, 'color', [0.85, 0.33, 0.1])
    title('v2 original')
    ylabel('mag')
    yAdj = (max(v2Orig)-min(v2Orig)) * 0.1;
    ylim([min(v2Orig)-yAdj, max(v2Orig)+yAdj])
    xAdj = length(v2Orig) * 0.05;
    xlim([0-xAdj, length(v2Orig)+xAdj])
    
    % v2 Simplified
    subplot(2,2,4), plot(v2, 'color', [0.85, 0.33, 0.1])
    title('v2 simplified')
    xlabel('pts')
    ylabel('mag')
    yAdj = (max(v2)-min(v2)) * 0.1;
    ylim([min(v2)-yAdj, max(v2)+yAdj])
    xAdj = length(v2) * 0.05;
    xlim([0-xAdj, length(v2)+xAdj])
    
    suptitle('Comparing these vectors:')
    
    if exist('ng','file')
        ng;
    end
end


%% Run

[met, det] = compVec(params, v1, v2);


function [met, det] = compVec(params, v1, v2)
% Does two things:
%
% Preprocess: Computes envelope over events if requested
% TWI: Applies temporal window around events, function and parameters
% specified in params.TWIWidth, .TWIFun,
%
% Compute: Runs actual comaprsion
%
%

Fs = params.Fs;

%% Preprocess

% NB: changing names around
% Also might as well avoid an inaccuracy error here
% Vectors can be different lengths if sampling rate is low, must be a
% rounding error?
% Trim as needed
use = min([length(v1), length(v2)]);
vs = [v1(1:use); ...
    v2(1:use)];
switch params.PreProType
    case 'TWI'
        % Loop over both v1 and v2
        % Inside loop, always called v1
        for v = 1:2
            
            % Create TWI functions over each
            
            % Get and first append 0 to start
            % This is to avoid missing first "up" if first value is 1
            v1 = [0, vs(v,:), 0];
            
            if params.plotOn
                figure
                subplot(3,1,1), plot(v1)
                ylabel('mag')
                title('stim')
                yAdj = (max(v1)-min(v1)) * 0.1;
                ylim([min(v1)-yAdj, max(v1)+yAdj])
                xAdj = length(v1) * 0.05;
                xlim([0-xAdj, length(v1)+xAdj])
                
                d = diff(v1);
                subplot(3,1,2), plot(d)
                title('diff(stim)')
                yAdj = (max(d)-min(d)) * 0.1;
                ylim([min(d)-yAdj, max(d)+yAdj])
                xlim([0-xAdj, length(v1)+xAdj])
                
            end
            
            % Find centre of each event
            % Use threshold - even with rise = 0, multiple points may
            % contribute to rise depending on sampling rate.
            % Set a reasoable limit based on max amplitude for detecting start
            % and end of events
            % eg
            lim = (max(v1)-min(v1)) * 0.1;
            
            % Indexes of ups - makes sure first isn't missed by appending 0
            ups = find(diff(v1)>lim);
            % Indexes of downs
            downs = find(diff(v1)<-lim);
            % Middle indexes
            mps = round(mean([ups;downs]));
            
            % Logical middle points
            mpsLog = zeros(1, numel(v1));
            mpsLog(mps) = 1;
            
            if params.plotOn
                subplot(3,1,1), hold on
                scatter(mps, mpsLog(mpsLog==1), 'FillColor', 'red')
            end
            
            % Use these midpoints for place TWI functions
            % Create empty vector for whole stim
            v1TWI = zeros(1, numel(v1));
            % Find width required in points
            widthPts = round(params.TWIWidth/1000 * Fs);
            % Create range for one window
            x = linspace(-1,1,widthPts);
            % Generate window
            switch func2str(params.TWIFun)
                case {'normpdf',' normcdf'}
                    y = params.TWIFun(x, params.mu, params.sig);
                case {'poisspdf', 'poisscdf'}
                    y = params.TWIFun(x, params.lambda);
            end
            % Note: SD? Set to extend across window
            
            % Min max normalise back to max 1
            y = (y - min(y)) / (max(y) - min(y));
            if params.plotOn
                subplot(3,1,3), hold on
                area(y)
                ylabel('mag')
                xlabel('Pts')
                title('Single temporal window envelope')
            end
            
            % Plonk these windows on the mps
            % What if guass extends to before stim start?
            for mp = 1:numel(mps)
                
                % startLim = 0; Don't need
                endLim = 0;
                
                % Limit start idx to >=1
                sIdx = mps(mp) - widthPts/2;
                if sIdx < 1
                    sIdx = 1;
                    % startLim = 1; Don't need
                end
                sIdx = round(sIdx);
                
                % Limit end idx to <= numel(v1)
                % eIdx = min([(mps(mp) + widthPts/2), numel(v1)]) - 1;
                eIdx = mps(mp) + widthPts/2;
                if eIdx > numel(v1)
                    eIdx = numel(v1);
                    endLim = 1;
                end
                eIdx = round(eIdx - 1);
                
                % Get actual distance to use - might be less than widthPts
                % if
                % window is extending beyond start or end of stim
                % and needs to be
                % trimmed
                % placing this much of the window at this mp:
                dist = (eIdx-sIdx); % Should be all of it in it most cases
                % Also need to check not replacing part of last placed
                % window
                % So place max of window and current contents
                if endLim
                    % This line works when an end limit is required
                    v1TWI(sIdx+1:eIdx+1) = max([y(1:dist+1); ...
                        v1TWI(sIdx+1:eIdx+1)]);
                else
                    % This line works for mps limited at start, and normal
                    % lines
                    v1TWI(sIdx:eIdx) = max([y(end-dist:end); ...
                        v1TWI(sIdx:eIdx)]);
                end
            end
            
            if params.plotOn
                subplot(3,1,1), hold on
                plot(v1TWI, 'k')
                legend({'Stim', 'mid points', 'TWIs'})
                suptitle(['Stimulus: ', num2str(v)])
                
                if exist('ng','file')
                    ng;
                end
            end
            
            % Save
            % Drop added zeros
            vs(v,:) = v1TWI(2:end-1);
        end
end

% Rename back to v1 and v2
v1 = vs(1,:);
v2 = vs(2,:);


%% Run comparision

pts = numel(v1);
switch params.compType
    case 'AbsDiff'
        % This is the (abs) area under the curve:
        % For each point the area is mag * width (1pt) / nPts
        % This is the same thing
        % det = abs(v1-v2)/pts;
        
        % Might need to rethink this measure
        % When there's a long stim due to big start and/or end buff, value
        % is low even when no events overlap, because there are more points
        % but some are irrelevant
        
        % Better to divde by Fs, not number of points?
        det = abs(v1-v2)/Fs;
        
    case 'Diff'
        % det = (v1-v2)/pts;
        det = abs(v1-v2)/Fs;
        
end
met = sum(det);

if params.plotOn
    figure
    subplot(3,1,1),
    h = area(v1);
    h.FaceColor = [0, 0.45, 0.74];
    h.FaceAlpha = 0.5;
    hold on;
    h = area(v2);
    h.FaceColor = [0.85, 0.33, 0.1];
    h.FaceAlpha = 0.5;
    legend({'Stim 1', 'Stim 2'})
    title('Stim TWI envelopes')
    ylabel('mag')
    yAdj = (max(v1)-min(v1)) * 0.1;
    ylim([min(v1)-yAdj, max(v1)+yAdj])
    xAdj = length(v1) * 0.05;
    xlim([0-xAdj, length(v1)+xAdj])
    
    subplot(3,1,2), 
    y1 = v1-v2;
    y1(y1>0) = 0;
    y2 = v1-v2;
    y2(y1<0) = 0;
    
    h = area(y1);
    h.FaceColor = [0.85, 0.33, 0.1];
    h.FaceAlpha = 0.5;
    hold on
    h = area(y2);
    h.FaceColor = [0, 0.45, 0.74];
    h.FaceAlpha = 0.5;
    ylabel('mag')
    title('Stim 1 - Stim2')
    xAdj = length(v1) * 0.05;
    xlim([0-xAdj, length(v1)+xAdj])
    
    subplot(3,1,3),
    h = area(det);
    h.FaceColor = [0.5, 0.18, 0.13];
    h.FaceAlpha = 0.7;
    xAdj = length(v1) * 0.05;
    xlim([0-xAdj, length(v1)+xAdj])
    
    title([params.compType, ': AUC = ', num2str(met)])
    xlabel('Pts')
    ylabel('Inst. Async-ness')
    
    if exist('ng','file')
        ng;
    end
end
