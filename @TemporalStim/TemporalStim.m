classdef TemporalStim
    
    properties
        params
        event
        sound = [];
        sound2 = [];
        verifySound = [];
        gapIndex
    end
    
    properties (Hidden)
        Sound
        Sound2
    end
    
    methods
       
        function obj = TemporalStim(params)
            % Set parameters
            
            if exist('params', 'var') && isfield(params, 'type')
                obj = obj.setDefaultParams(params.type);
            else
                obj = obj.setDefaultParams();
            end
            
            switch class(params)
                case 'TemporalStim'
                    % Another stim object (with or without .sound)
                    % If the sound field exist, hold for evaluation
                    if isprop(params, 'sound') ...
                            && ~isempty(params.sound)
                        obj.verifySound = params.sound;
                        obj.sound = [];
                    end
                    
                    % Then apply provided params
                    obj = obj.setParams(params.params);
                    
                case 'struct'
                    % Params structure
                    obj = obj.setParams(params);
                    obj.verifySound = [];
                    
                case 'char'
                    % 'Aud' oir 'Vis'
                    obj.verifySound = [];
            end
            
            % Check params
            res = checkParams(obj);
            if ~res
                return
            end
            
            % Generate event
            obj = generateEvent(obj);
            
            % Generate stim
            obj = generateStim(obj);
            
            % Verify if required
            obj.verifySound = verifyStim(obj);
            
        end
        
        function obj = setParams(obj, params)
            % Set specified parameters
            flds = fields(params);
            nFields = length(flds);
            
            for n = 1:nFields
                fn = flds{n};
                obj.params.(fn) = params.(fn);
            end
            
        end
        
        function obj = setDefaultParams(obj, str)
            % Set default paramters
            
            if exist('str', 'var')
                obj.params.type = str;
            else
                obj.params.type = 'Aud';
            end
            
            cfg.seedDebug = 1;
            cfg.dispWarn = true;
            cfg.eventMag = 1;
            cfg.eventLength = 20;
            cfg.mag = 0;
            cfg.nEvents = 9;
            cfg.gap1 = 60;
            cfg.gap2 = 120;
            cfg.duration = 1000;
            cfg.noiseMag = 0.001;
            cfg.noiseType = 'multipleBlocks';
            cfg.noiseBlock = cfg.eventLength;
            cfg.rideNoise = 1;
            cfg.eventNoise = 0;
            cfg.cull = 0;
            cfg.cutOff = 10000;
            cfg.startBuff = 0;
            cfg.endBuff = 0;
            
            switch obj.params.type
                case {'aud', 'Aud'}
                    cfg.type = 'Aud';
                    cfg.Fs = 24000;
                    cfg.eventType = 'sine';
                    cfg.eventFreq = 220;
                    cfg.addRise = true;
                    cfg.rise = 2;
                    
                case {'vis', 'Vis'}
                    cfg.eventType = 'flat';
                    cfg.addRise = false;
                    cfg.rise = 0;
            end
            
            % Save in object
            obj.params = cfg;
            
        end
        
        function res = checkParams(obj)
            % Additional checks after all params set
            % Check number of events will fit in stimulus duration
            
            res = true;
            
            reqLength1 = ...
                min([obj.params.gap1 obj.params.gap2])*obj.params.nEvents;
            if reqLength1 > obj.params.duration
                if cfg.dispWarn
                    disp('Too many events, not enough time')
                end
                % Fail
                res = false;
            end
            
            reqLength2= ...
                (min([obj.params.gap1 obj.params.gap2]) ...
                + obj.params.eventLength)*obj.params.nEvents;
            
            if reqLength2 > obj.params.duration
                % Don't fail on this one, just warn
                if obj.params.dispWarn
                    disp('Warning: Stim slightly longer than requested')
                end
            end
            
        end
        
        function obj = generateEvent(obj)
            
            eventLength = ceil(obj.params.eventLength/1000*obj.params.Fs);
            mag = db2mag(obj.params.mag);
            eventMag = obj.params.eventMag; %+/- voltage range
            
            switch obj.params.eventType
                case 'flat'
                    % Generate
                    ev = ones(1,eventLength).*eventMag;
                    
                case 'sine' % Sine
                    % Time vector
                    t = 0: 1/obj.params.Fs : (eventLength/obj.params.Fs)...
                        -1/obj.params.Fs;
                    
                    % Generate event - note linear aplpication of
                    % attenuation
                    ev = sin(2*pi*t*obj.params.eventFreq).*eventMag;
                    
                case 'noise'
                    % Make sure eventNoise is off, no point adding noise
                    % to noise
                    obj.params.eventNoise = false;
                    
                    % Set up seed for event
                    if isfield(obj.params, 'seedEvent') ...
                            && ~isempty(obj.params.seedEvent)
                        
                        % Set specified seed
                        obj.params.seedEvent = ...
                            TemporalStim.setSeed(obj.params.seedEvent);
                        
                        
                    else % No
                        % Generate new time based seed and save
                        
                        obj.params.seedEvent = TemporalStim.genSeed();
                        
                    end
                    
                    % Generate
                    % (currentely won't generate all point in range...)
                    ev = wgn(1, eventLength, eventMag/2, 'linear');
            end
            
            % Add additional noise to event if flat or sine
            if obj.params.eventNoise==1
                obj.params.eventNoise = 1;
                obj.params.eventNoisedB = obj.params.eventNoise;
                
                eNdB = obj.params.mag-(0-obj.params.eventNoisedB);
                
                obj.params.eventNoisedBrelMag = eNdB;
                obj.params.eventSNR = obj.params.eventNoisedB;
                
                % Add noise (note noise mag in db)
                ev = ev+wgn(1, length(ev), eNdB);
            else
                obj.params.eventNoise = 0;
                obj.params.eventNoisedB = 0;
                obj.params.eventSNR = NaN;
            end
            
            % Add Rise/fall (defualt: on for sine/flat, off for noise)
            if obj.params.addRise
                
                % Get and save (rounded) rise time
                rise = ceil(obj.params.rise/1000*obj.params.Fs);
                obj.params.rise = rise/obj.params.Fs*1000;
                
                % Generate
                f = linspace(0, pi/2, rise);
                f = cos(f);
                r = linspace(-pi/2, 0, rise);
                r = cos(r);
                
                % Apply to event
                ev(1:rise) = ev(1:rise).*r;
                ev(end-(rise-1):end) = ev(end-(rise-1):end).*f;
                
            end
            
            % Save stuff not yet saved
            obj.params.eventLength = eventLength/obj.params.Fs*1000;
            obj.event = ev.*mag;
        end
        
        function obj = generateStim(obj)
            
            eventLength = length(obj.event);
            
            % Has a MAIN seed been specified?
            if isfield(obj.params, 'seed') ...
                    && ~isempty(obj.params.seed) % Yes
                
                % Set specified seed
                obj.params.seed = TemporalStim.setSeed(obj.params.seed);
                
                % Report
                if obj.params.seedDebug
                    disp('Setting specified seed...')
                    disp('Seed is...')
                    disp(obj.params.seed)
                end
            else % No
                % Generate new time based seed and save

                % Set specified seed
                obj.params.seed = TemporalStim.genSeed();

                % Report
                if obj.params.seedDebug
                    disp('Seed not specified, setting new...')
                    disp('Seed is...')
                    disp(obj.params.seed)
                end
            end
            
            % Convert from ms to pts
            % Required stim length
            duration = ceil(obj.params.duration/1000*obj.params.Fs);
            
            % Length of event (in pts)
            el = length(obj.event);
            
            % Gaps (stim.gaps is in pts)
            % stim.gap 1 is shorter
            % stim.gap2 is longer
            gaps = ceil([obj.params.gap1, obj.params.gap2]...
                /1000*obj.params.Fs);
            gap1 = min(gaps);
            gap2 = max(gaps);
            
            gap_mat = [0:obj.params.nEvents; obj.params.nEvents:-1:0];
            gap_mat = gap_mat';
            
            gap_mat(:,3) = ...
                gap_mat(:,1)*gap1 ...
                + gap_mat(:,2)*gap2...
                + obj.params.nEvents*eventLength;
            
            % Select combination where first > than requested length
            if  sum(gap_mat(:,3)>duration)>=1
                % Try and find a combination longer than requested
                gap_mat = gap_mat(gap_mat(:,3)>duration,:);
            else
                % If not available, take longest
                gap_mat = gap_mat(1,1:3);
            end
            
            % Get number of each event required
            gap1_n = gap_mat(end,1);
            gap2_n = gap_mat(end,2); %#ok<NASGU> 
            % gap2_n not used at the moment
            
            % Randomly select indexs where gap1 should be
            gap1_ind = randsample(1:obj.params.nEvents, gap1_n);
            
            % Create list of order of gaps
            gap_index = ones(1, obj.params.nEvents)+1;
            gap_index(1,gap1_ind) = gap_index(1,gap1_ind)-1;
            
            % Build stim - vectorised - very slightly faster??
            % Interleave events in to index
            gap_index(2,1:obj.params.nEvents) = 3;
            gap_index = reshape(gap_index, 1, []);
            % Preallocate gaps and final sound
            % (matrix of NaNs (longest of gap1, gap2, or event)
            % x 3*stim.nEvents
            gap1_0 = zeros(1, gap1);
            gap2_0 = zeros(1, gap2);
            
            sound1 = NaN(max([gap1 gap2 el]), obj.params.nEvents*2);
            % Place gap1s
            sound1(1:gap1, gap_index==1) = ...
                repmat(gap1_0', 1, sum(gap_index==1));
            % Place gap2s
            sound1(1:gap2, gap_index==2) = ...
                repmat(gap2_0', 1, sum(gap_index==2));
            
            % Copy this matrix to use to create an "event index" (sound2)
            % to use when applying noise later
            sound2 = sound1;
            
            % Place events
            sound1(1:el, gap_index==3) = ...
                repmat(obj.event', 1, sum(gap_index==3));
            % Place index of events (ie. ones where events are)
            sound2(1:el, gap_index==3) = ...
                repmat(ones(el,1), 1, sum(gap_index==3));
            
            % At this point sound 1 contains gaps (zeros), actual events
            % and NaNs to remove Sound 2 contains gaps (zeros), index of
            % events (ones) and NaNs to remove
            
            % Reshape in to one row
            sound1 = reshape(sound1, 1, numel(sound1));
            sound2 = reshape(sound2, 1, numel(sound2));
            
            % Remove NaNs
            sound1 = sound1(~isnan(sound1));
            sound2 = sound2(~isnan(sound2));
            
            % Reverse so event occurs immediatly at onset
            sound1(1:end) = sound1(end:-1:1);
            sound2(1:end) = sound2(end:-1:1);
            
            % And reverse gap_index
            gap_index(1:end) = gap_index(end:-1:1);
            
            % Add buffers (changed to ms buffer)
            sb = round(obj.params.startBuff/1000*obj.params.Fs);
            eb = round(obj.params.endBuff/1000*obj.params.Fs);
            sound1 = [zeros(1,sb), sound1, zeros(1,eb)];
            sound2 = [zeros(1,sb), sound2, zeros(1,eb)];
            
            % Generate background noise
            noiseBlock = ceil(obj.params.noiseBlock/1000*obj.params.Fs);
            
            % Seed still recorded even if nosie is effectively off
            % Has a NOISE seed been specified?
            if isfield(obj.params,'seedNoise') ...
                    && ~isempty(obj.params.seedNoise)
                % disp('Setting specified noise seed')
                
                % Set specified seed
                obj.params.seedNoise = ...
                    TemporalStim.setSeed(obj.params.seedNoise);

                % disp('Noise seed is...')
                % stim.seedNoise
            else % No
                % Generate new time based seed and save
                % disp('Noise seed not specified, setting new...')

                obj.params.seedNoise = TemporalStim.genSeed();
                
                % disp('Noise seed is...')
                % stim.seedNoise
            end
            
            if obj.params.noiseMag > -1000
                % Only bother generating noise if it's actually specified
                noiseMag = db2mag(obj.params.noiseMag);
                
                switch obj.params.noiseType
                    case 'white' % White noise
                        % Noise amplitude is eventMag (max
                        % voltage)-noiseMag (linear)
                        noise = wgn(1,length(sound1), ...
                            eventMag*noiseMag, ...
                            'linear');
                        
                    case 'blocked' % Blocked noise (all same mag)
                        % Create row of noise as long as sound/by block
                        % length +1 on length(sound) ceil used in
                        % conversion to pts, so +1 to make sure it's long
                        % enough                             % Now rel
                        noise = ...
                            wgn(1, ceil((length(sound1)+1)/noiseBlock), ...
                            obj.params.eventMag*obj.params.noiseMag, ...
                            'linear');
                        % check this line next time blocked noise is used
                        % Repeat this so rows are as long as block length
                        noise = repmat(noise, noiseBlock, 1);
                        % Respahe so one low row, now as long as sound
                        noise = reshape(noise, 1, ...
                            size(noise,1)*size(noise,2));
                        
                    case 'multipleBlocks'
                        % Generate the amplitude of the blocks, as above,
                        % using NoiseSeed
                        noiseAmps = ...
                            abs(wgn(1,ceil((length(sound1)+1)...
                            /noiseBlock), ...
                            obj.params.eventMag*obj.params.noiseMag, ...
                            'linear'));
                        
                        % Does a Seed exist for actual noise? This stream
                        % will be used until enough noise contents have
                        % been generated
                        if isfield(obj.params, 'MBNSeedNoise') ...
                                && ~isempty(obj.params.MBNSeedNoise) % Yes
                            
                            % Set specified seed
                            obj.params.MBNSeedNoise = ...
                                TemporalStim.setSeed(...
                                obj.params.MBNSeedNoise);
                            
                        else % No
                            
                            % Generate one and set
                            obj.params.MBNSeedNoise = ...
                                TemporalStim.genSeed();
                            
                        end
                        
                        % But rather than repmatting, use these values as
                        % the amplitudes for blocks of noise of the block
                        % length
                        noise = NaN(noiseBlock, length(noiseAmps));
                        for i = 1:length(noiseAmps)
                            % And generate the next noise block
                            % Using this stream sqeuentially
                            noise(:,i) = ...
                                wgn(noiseBlock, 1, noiseAmps(i), 'linear');
                        end
                        % And reshape into vector
                        noise = ...
                            reshape(noise, 1, size(noise,1)*size(noise,2));
                end
                
                % Add noise to sound output Might not be same length thanks
                % to +1 above, so just add as much as needed sound2 is
                % index of event location
                if ~obj.params.rideNoise
                    % Don't add noise to events
                    
                    % Add noise everywhere events aren't
                    sound1(sound2==0) = ...
                        sound1(sound2==0)...
                        + noise(1:length(sound1(sound2==0)));
                
                else
                    % Do add noise to events
                    
                    sound1 = sound1 + noise(1:length(sound1));
                    
                end
            end
            
            
            % Finish
            % Cull off anything above event range?
            if obj.params.cull > 0
                sound1(sound1>obj.params.cull) = obj.params.cull;
                sound1(sound1<0-obj.params.cull) = 0-obj.params.cull;
            end
            
            % What about values below 0 for Vis?
            % switch cfg.type
            %     case 'Aud'
            %     case 'Vis'
            %         % sound=abs(sound); % Does this half noise power?
            %         % Or?
            %         % sound=sound(sound<0)=0; %?
            % end
            
            % Apply cut off to normalise lengths?
            cO = round(obj.params.cutOff/1000*obj.params.Fs);
            if length(sound1) > cO
                sound1 = sound1(1:cO);
                sound2 = sound2(1:cO);
            end
            
            obj.sound = sound1;
            obj.sound2 = sound2;
            obj.gapIndex = gap_index;
            
        end
        
        function res = verifyStim(obj)
            
            if isempty(obj.verifySound)
                % Nothing to verify
                res = [];
                return
            end
            
            if sum(obj.sound ~= obj.verifySound) > 0
                % Generated sound doesn't match original sound
                % Return original cfg including sound
                disp('Mismatch!')
                res = 0;
            else
                disp('Stim OK')
                res = 1;
            end
            
        end
        
        function plot(obj, s)
            figure
            
            subplot(2,1,1)
            plot(obj.sound)
            subplot(2,1,2)
            plot(obj.sound2)
            
            if exist('s', 'var')
                title(s)
            else
                title(obj.params.type)
            end
            
        end
        
        function out = get.Sound(obj)
            % If the wrong case is used - ie. .Sound instead of .sound,
            % return correct propery
            out = obj.sound;
        end
        
        function out = get.Sound2(obj)
            % If the wrong case is used - ie. .Sound2 instead of .sound2,
            % return correct propery
            out = obj.sound2;
        end
        
    end
    
    methods (Static)
        
        function seed2 = setSeed(seed)
            % Set specified seed in reliable way and return

            seed2 = rng(seed); %#ok<NASGU> necessary
            seed2 = rng(seed);
            rng(seed2);
            rng(seed2);
            
        end
        
        function s = genSeed
            % Generate new time based seed and return
            
            s = rng('shuffle'); %#ok<NASGU> necessary
            s = rng('shuffle');
            rng(s);
            rng(s);
            
        end
        
        % Nellie version
        stim = TSLegacyNellie(params)
    end
    
end