function stim = TSLegacyNellie(cfg)
% Version of code used in Nelie for Temporal neural experiemnts
% Before conversion to class
%
% Generate event and stimulus with parameters specified in cfg.
% Outputs stim structure, containing info about stim and ouput (.sound)
%
% Noise is supposed to be relative to eventMag, but it doesn't work
% properly??
% For example, using 255V for visual = much smaller noise, relative to say
% 3V range
%
% If no paramters set at all, generates a 'default' stim which has no noise
% and a voltage range of -1:1V, 9 events, 1 s duration, sine event@220 Hz
% etc.
%
% Without .sound field, other contents of stim can be used to recreate
% EXACT stimulus: stim = Church2(stim)
%
% Seed is set before each rand call, so the first entry in stream is used.
% This is to ensure no other calls to rand cause trials to misalign with
% stream. If no seed is set, time based one generated.
% Except in case of multipleBlocks noise:
% Block amplitudes are set using seedNoise, then MBNSeed is set and stream
% is used multiple times to generate actual noise in each block.
%
% Required input - in ms or Hz
% cfg.Fs = 24000; % Sampling rate
% cfg.eventLength = 20; % Duration of event
% cfg.mag = 0; % mag or ATTEN of event in dB. 0dB=-eventMag:eventMag.
% ie. positive value makes stim bigger than eventMag (voltage range),
% -value makes it smaller.
% Makes sense for this value to be 0 or negative!
% cfg.eventMag = 1 %+/- voltage range
% cfg.eventType = 'sine'; % 'sine' or 'flat'
% cfg.eventFreq = 200; % If 'sine', frequency
% cfg.nEvents = 9; % Total number of events
% cfg.gap1 = 60; % Gap durations
% cfg.gap2 = 120;
% cfg.duration = 1000; % Target stim duration
% cfg.startBuff = in ms, buffer for start and end (can be cutOff)
% cfg.endBuff
%
% % Optional input
% cfg.rideNoise=0 % 1=events ride noise, 0 events in noise (added to 0)
% cfg.rise = 2; % Event rise/fall time
% cfg.noiseMag=0; % dB, 0 dB relative to 1 Mag. Positive values = greater
% than voltage range possible
% cfg.noiseType = 'blocked' % 'blocked' or 'white'
% cfg.noiseBlock = cfg.eventLength; % Block duration (usually same as
% % (eventLength)
%
% % Option seed inputs
% cfg.seed = rng('shuffle')% Seed used to generate gap distribution
% cfg.seedNoise = rng('shuffle') % Seed used to generate noise
%
% % Event noise inputs
% cfg.eventNoise=1 turn on event noise
% cfg.eventNoisedB=2; magnitude relative to cfg.mag. Can be positive but could go out of voltage range ie. -2 when
% cfg.mag=35, = 33. (in which case, stim would just be swamped with noise)
% 0 = noise, -50 = sounds like sound, -30 noisy sound

%% 1) Set up parameters
tic
% Check this one first!
if ~isfield(cfg,'dispWarn') || isempty(cfg.dispWarn)
    cfg.dispWarn=1;
    disp('Warning: Displaying warnings!')
end
stim.dispWarn=cfg.dispWarn; %#ok<STRNU>

% Check stimulus already exists
if isfield(cfg,'sound') && ~isempty(cfg.sound)% If sound field exists and it isn't empty...
    % Check existing sound is correct...
    % Save sound for checking later
    check_me=cfg.sound;
    cfg.sound=[];
end

if ~isfield(cfg,'type') || isempty(cfg.type)
    cfg.type='Aud';
    if cfg.dispWarn==1
        disp('Warning: No modality specified, setting cfg.type=Auditory')
    end
end

% Check specified paratemters and assume unspecified parameters
% If sampling rate is unspecified, set default and warn
if ~isfield(cfg,'Fs') || isempty(cfg.Fs)
    switch cfg.type
        case 'Aud'
            cfg.Fs=24000;
        case 'Vis'
            cfg.Fs=60;
    end
    if cfg.dispWarn==1
        disp(['Warning: No sampling rate specified, setting cfg.Fs=', num2str(cfg.Fs), ' Hz.'])
    end
end

if ~isfield(cfg,'eventLength') || isempty(cfg.eventLength)
    cfg.eventLength=20;
    if cfg.dispWarn==1
        disp('Warning: No event length, setting cfg.eventLength=20 ms.')
    end
end

if ~isfield(cfg,'mag') || isempty(cfg.mag)
    cfg.mag=0;
    if cfg.dispWarn==1
        disp('Warning: No magnitude specified, setting cfg.mag=0 dB ie. 0 dB attenuation of cfg.eventMag (voltage range).')
    end
end

if ~isfield(cfg,'eventMag') || isempty(cfg.eventMag)
    cfg.eventMag=1;
    if cfg.dispWarn==1
        disp('Warning: No voltage range specified, setting cfg.eventMag=1 V. ie. RM1 range: -1:1 V')
    end
end

% Check eventType and eventFreq
if ~isfield(cfg,'eventType') || isempty(cfg.eventType)
    switch cfg.type
        case 'Aud'
            cfg.eventType='sine';
            if cfg.dispWarn
                disp('Warning: No event type specified, setting cfg.eventType=''sine'' ...')
            end
        case 'Vis'
            % If vis, set to event type flat and remove eventFreq field.
            cfg.eventType='sine';
            % cfg.eventFreq=0;
            if cfg.dispWarn
                disp('Warning: No event type specified, setting cfg.eventType=''flat'' ...')
            end
    end
end

if (~isfield(cfg,'eventFreq') || isempty(cfg.eventFreq)) && strcmp(cfg.eventType,'sine');
    cfg.eventFreq=220;
    if cfg.dispWarn
        disp('Warning: No event freq specified either, setting cfg.eventFreq=220 V.')
    end
end

if ~isfield(cfg,'addRise') || isempty(cfg.addRise)
    % Turn on "addRise"
    cfg.addRise=1;
    if cfg.dispWarn
        disp('Warning: No rise time specified, setting cfg.rise=2 ms')
    end
    if ~isfield(cfg,'rise') || isempty(cfg.rise)
        % And set to 2 ms
        cfg.rise=2;
    end
end
if cfg.addRise==0
    if cfg.dispWarn
        disp('Warning: No rise time requested, setting cfg.rise=0 ms')
    end
    cfg.rise=0;
end

if ~isfield(cfg,'nEvents') || isempty(cfg.nEvents)
    cfg.nEvents=9;
    if cfg.dispWarn
        disp('Warning: No n events specified, setting cfg.nEvents=9')
    end
end

if ~isfield(cfg,'gap1') || isempty(cfg.gap1)
    cfg.gap1=60;
    if cfg.dispWarn
        disp('Warning: No gap1 specified, setting cfg.gap1=60 ms')
    end
end
if ~isfield(cfg,'gap2') || isempty(cfg.gap2)
    cfg.gap2=120;
    if cfg.dispWarn
        disp('Warning: No gap2 specified, setting cfg.gap2=120 ms')
    end
end
if ~isfield(cfg,'duration') || isempty(cfg.duration)
    cfg.duration=1000;
    if cfg.dispWarn
        disp('Warning: No duration specified, setting cfg.duration=1000 ms')
    end
end

if ~isfield(cfg,'noiseMag') || isempty(cfg.noiseMag)
    cfg.noiseMag=-1000;
    if cfg.dispWarn
        disp('Warning: No noise specified, setting cfg.noiseMag=-1000 dB (0)')
    end
end

if ~isfield(cfg,'noiseType') || isempty(cfg.noiseType)
    cfg.noiseType='blocked';
    if cfg.dispWarn
        disp('Warning: No noise type specified, setting noiseType=''blocked''.')
    end
end

if ~isfield(cfg,'noiseBlock') || isempty(cfg.noiseBlock)
    cfg.noiseBlock=cfg.eventLength;
    if cfg.dispWarn
        disp(['Warning: No noise block specified, setting to same as event length: cfg.noiseBlock=', num2str(cfg.eventLength), ' ms.'])
    end
end

if ~isfield(cfg,'rideNoise') || isempty(cfg.rideNoise)
    cfg.rideNoise=0;
    if cfg.dispWarn
        disp('Warning: ride noise option not specified, setting cfg.rideNoise=0 (no effect if no noise)')
    end
end

if ~isfield(cfg,'eventNoise') || isempty(cfg.eventNoise)
    cfg.eventNoise=0;
    if cfg.dispWarn
        disp('Warning: No event noise specified, setting cfg.eventNoise=0')
    end
end

if ~isfield(cfg,'cull') || isempty(cfg.cull)
    cfg.cull=0;
    if cfg.dispWarn
        disp('Warning: No cull specified. Not culling any out of range bits')
    end
end

if ~isfield(cfg,'cutOff') || isempty(cfg.cutOff)
    cfg.cutOff=10000;
    if cfg.dispWarn
        disp('Warning: Cut off for length equalisation specified, setting very long cfg.cutOff=10000')
    end
end
if ~isfield(cfg,'startBuff') || isempty(cfg.startBuff)
    cfg.startBuff=0;
    if cfg.dispWarn
        disp('Warning: No noise buffer at start specified, setting cfg.startBuff=0')
    end
end
if ~isfield(cfg,'endBuff') || isempty(cfg.endBuff)
    cfg.endBuff=0;
    if cfg.dispWarn
        disp('Warning: No noise buffer at end specified, setting cfg.endBuff=0')
    end
end

% Template for adding checks...
% if ~isfield(cfg,'') || isempty(cfg.)
%     cfg.
%     disp('Warning:')
% end

% Additional checks after all params set
% Check number of events will fit in stimulus duration
req_length1=min([cfg.gap1 cfg.gap2])*cfg.nEvents;
if req_length1>cfg.duration
    req_length1 %#ok<NOPRT>
    cfg.duration
    if cfg.dispWarn
        disp('Too many events, not enough time')
    end
    % stim=[];
    % return
end

req_length2=(min([cfg.gap1 cfg.gap2])+cfg.eventLength)*cfg.nEvents;
if req_length2>cfg.duration
    if cfg.dispWarn
        req_length2 %#ok<NOPRT>
        disp('Warning: Stim slightly longer than requested')
    end
end

stim=cfg;


%% 2) Generate event
% Get parameters and convert from ms to points

eventLength=ceil(cfg.eventLength/1000*cfg.Fs);
mag=db2mag(cfg.mag);
eventMag=cfg.eventMag; %+/- voltage range

switch cfg.eventType
    case 'flat'% If flat event
        stim.eventType='flat';
        
        % Generate
        event=ones(1,eventLength).*eventMag;
    case 'sine' % Sine
        stim.eventType='sine';
        stim.eventFreq=cfg.eventFreq;
        
        % Time vector
        t=0:1/cfg.Fs:(eventLength/cfg.Fs)-1/cfg.Fs;
        
        % Generate event - note linear aplpication of attenuation
        event=sin(2*pi*t*cfg.eventFreq).*eventMag;
    case 'noise'
        stim.eventType='noise';
        
        % Make sure eventNoise is off, no point adding noise to noise
        cfg.eventNoise=0;
        stim.eventNoise=0;
        
        % Set up seed for event
        if isfield(cfg,'seedEvent') && ~isempty(cfg.seedEvent) % Yes
            % Set specified seed
            stim.seed=rng(cfg.seedEvent);
            stim.seed=rng(cfg.seedEvent);
            rng(cfg.seedEvent);
            rng(cfg.seedEvent);
        else % No
            % Generate new time based seed and save
            s=rng('shuffle'); %#ok<NASGU>
            s=rng('shuffle');
            stim.seedEvent=s;
            rng(s);
            rng(s);
        end
        
        % Generate (currentely won't generate all point in range...)
        event=wgn(1,eventLength,eventMag/2,'linear');
end

% Add additional noise to event if flat or sine
if cfg.eventNoise==1
    stim.eventNoise=1;
    stim.eventNoisedB=cfg.eventNoise;
    eNdB = cfg.mag-(0-cfg.eventNoisedB);
    stim.eventNoisedBrelMag = eNdB;
    stim.eventSNR=stim.eventNoisedB;
    
    % Add noise (note noise mag in db)
    event=event+wgn(1,length(event),eNdB);
else
    stim.eventNoise=0;
    stim.eventNoisedB=0;
    stim.eventSNR=NaN;
end

% Add Rise/fall (defualt: on for sine/flat, off for noise)
if cfg.addRise==1
    stim.addRise=1;
    
    % Get and save (rounded) rise time
    rise=ceil(cfg.rise/1000*cfg.Fs);
    stim.rise=rise/cfg.Fs*1000;
    
    % Generate
    f=linspace(0,pi/2,rise);
    f=cos(f);
    r=linspace(-pi/2,0,rise);
    r=cos(r);
    
    % Apply to event
    event(1:rise)=event(1:rise).*r;
    event(end-(rise-1):end)=event(end-(rise-1):end).*f;
    
    % % Apply mag - Now done above (?)
    event=event.*mag;
else
    stim.addRise=0;
end

% Save stuff not yet saved
stim.eventLength=eventLength/cfg.Fs*1000;


%% 3) Generate stim

% Has a MAIN seed been specified?
if isfield(cfg,'seed') && ~isempty(cfg.seed) % Yes
    % disp('Setting specified seed')
    
    % Set specified seed
    stim.seed=rng(cfg.seed);
    stim.seed=rng(cfg.seed);
    rng(cfg.seed);
    rng(cfg.seed);
    
    % disp('Seed is...')
    % stim.seed
else % No
    % Generate new time based seed and save
    % disp('Seed not specified, setting new...')
    
    s=rng('shuffle');
    stim.seed=s;
    rng(s);
    rng(s);
    
    % disp('Seed is...')
    % stim.seed
end

% Convert from ms to pts
% Required stim length
duration=ceil(cfg.duration/1000*cfg.Fs);

% Required stim events
% stim.nEvents=cfg.nEvents; % Already exists

% Length of event (in pts)
el=length(event);

% Gaps (stim.gaps is in pts)
% stim.gap 1 is shorter
% stim.gap2 is longer
gaps = ceil([cfg.gap1, cfg.gap2]/1000*cfg.Fs);
gap1=min(gaps);
gap2=max(gaps);

gap_mat=[0:stim.nEvents;stim.nEvents:-1:0];
gap_mat=gap_mat';

gap_mat(:,3)=gap_mat(:,1)*gap1+gap_mat(:,2)*gap2+stim.nEvents*eventLength;

% Select combination where first > than requested length
if  sum(gap_mat(:,3)>duration)>=1% Try and find a combination longer than requested
    gap_mat=gap_mat(gap_mat(:,3)>duration,:);
else % If not available, take longest
    gap_mat=gap_mat(1,1:3);
end
% Get number of each event required
gap1_n = gap_mat(end,1);
gap2_n = gap_mat(end,2); %#ok<NASGU> gap2_n not used at the moment

% Randomly select indexs where gap1 should be
gap1_ind=randsample(1:stim.nEvents,gap1_n);

% Create list of order of gaps
gap_index=ones(1,stim.nEvents)+1;
gap_index(1,gap1_ind)=gap_index(1,gap1_ind)-1;

% Build stim    -vectorised - very slightly faster??
% Interleave events in to index
gap_index(2,1:stim.nEvents)=3;
gap_index=reshape(gap_index,1,[]);
% Preallocate gaps and final sound (matrix of NaNs (longest of gap1, gap2, or event) x 3*stim.nEvents
gap1_0=zeros(1,gap1);
gap2_0=zeros(1,gap2);
sound=NaN(max([gap1 gap2 el]),stim.nEvents*2);
% Place gap1s
sound(1:gap1, gap_index==1)=repmat(gap1_0',1,sum(gap_index==1));
% Place gap2s
sound(1:gap2, gap_index==2)=repmat(gap2_0',1,sum(gap_index==2));

% Copy this matrix to use to create an "event index" (sound2) to use when
% applying noise later
sound2=sound;

% Place events
% el=length(event); % Already exists
sound(1:el, gap_index==3)=repmat(event',1,sum(gap_index==3));
% Place index of events (ie. ones where events are)
sound2(1:el, gap_index==3)=repmat(ones(el,1),1,sum(gap_index==3));

% At this point sound 1 contains gaps (zeros), actual events and NaNs to remove
% Sound 2 contains gaps (zeros), index of events (ones) and NaNs to remove

% Reshape in to one row
sound=reshape(sound,1,numel(sound));
sound2=reshape(sound2,1,numel(sound2));

% Remove NaNs
sound=sound(~isnan(sound));
sound2=sound2(~isnan(sound2));

% Reverse so event occurs immediatly at onset
sound(1:end)=sound(end:-1:1);
sound2(1:end)=sound2(end:-1:1);

% And reverse gap_index
gap_index(1:end)=gap_index(end:-1:1);

% Add buffers (el buffer)
% stim.startBuff = cfg.startBuff;
% sound=[zeros(1,el*cfg.startBuff), sound, zeros(1,el*cfg.endBuff)];
% sound2=[zeros(1,el*cfg.startBuff), sound2, zeros(1,el*cfg.endBuff)];
% stim.endBuff = cfg.endBuff;

% Add buffers (changed to ms buffer)
stim.startBuff = cfg.startBuff;
stim.endBuff = cfg.endBuff;
sb=round(cfg.startBuff/1000*cfg.Fs);
eb=round(cfg.endBuff/1000*cfg.Fs);
sound=[zeros(1,sb), sound, zeros(1,eb)];
sound2=[zeros(1,sb), sound2, zeros(1,eb)];


%% 4) Generate background noise

noiseBlock=ceil(cfg.noiseBlock/1000*cfg.Fs);

% Seed still recorded even if nosie is effectively off
% Has a NOISE seed been specified?
if isfield(cfg,'seedNoise') && ~isempty(cfg.seedNoise) % Yes
    % disp('Setting specified noise seed')
    
    % Set specified seed
    stim.seedNoise=rng(cfg.seedNoise);
    stim.seedNoise=rng(cfg.seedNoise);
    rng(cfg.seedNoise);
    rng(cfg.seedNoise);
    
    % disp('Noise seed is...')
    % stim.seedNoise
else % No
    % Generate new time based seed and save
    %disp('Noise seed not specified, setting new...')
    
    s=rng('shuffle');
    stim.seedNoise=s;
    rng(s);
    rng(s);
    
    % disp('Noise seed is...')
    % stim.seedNoise
end

if cfg.noiseMag>-1000 % Only bother generating noise if it's actually specified
    
%     switch cfg.type
%         case 'Aud'
%             noiseMag=db2mag(cfg.noiseMag);
%         case 'Vis'
%             noiseMag=db2mag(cfg.noiseMag)*2;
%     end
     noiseMag=db2mag(cfg.noiseMag);
    
    switch cfg.noiseType
        case 'white' % White noise
            % Noise amplitude is eventMag (max voltage)-noiseMag (linear)
            noise=wgn(1,length(sound),eventMag*noiseMag,'linear');
        case 'blocked' % Blocked noise (all same mag)
            % Create row of noise as long as sound/by block length
            % +1 on length(sound) ceil used in conversion to pts, so +1 to make
            % sure it's long enough                             % Now rel
            noise=wgn(1,ceil((length(sound)+1)/noiseBlock),eventMag*noiseMag,'linear'); % check this line next time blocked noise is used
            % Repeat this so rows are as long as block length
            noise=repmat(noise,noiseBlock,1);
            % Respahe so one low row, now as long as sound
            noise=reshape(noise,1,size(noise,1)*size(noise,2));
        case 'multipleBlocks'
            % Generate the amplitude of the blocks, as above, using
            % NoiseSeed
            noiseAmps=abs(wgn(1,ceil((length(sound)+1)/noiseBlock),eventMag*noiseMag,'linear'));
            
            % Does a Seed exist for actual noise?
            % This stream will be used until enough noise contents have
            % been generated
            if isfield(cfg,'MBNSeedNoise') && ~isempty(cfg.MBNSeedNoise) % Yes
                % Set specified seed
                stim.MBNSeedNoise=rng(cfg.MBNSeedNoise);
                stim.MBNSeedNoise=rng(cfg.MBNSeedNoise);
                rng(cfg.MBNSeedNoise);
                rng(cfg.MBNSeedNoise);
            else % No
                % Generate one and set
                s=rng('shuffle'); %#ok<NASGU>
                s=rng('shuffle');
                stim.MBNSeedNoise=s;
                rng(s);
                rng(s);
            end
            
            % But rather than repmatting, use these values as the
            % amplitudes for blocks of noise of the block length
            noise=NaN(noiseBlock,length(noiseAmps));
            for i=1:length(noiseAmps)
                % And generate the next noise block
                % Using this stream sqeuentially
                noise(:,i) = wgn(noiseBlock,1,noiseAmps(i),'linear');
            end
            % And reshape into vector
            noise=reshape(noise,1,size(noise,1)*size(noise,2));
    end
    
    % Add noise to sound output
    % Might not be same length thanks to +1 above, so just add as much as
    % needed
    % sound2 is index of event location
    if cfg.rideNoise==0 % Don't add noise to events
        % Add noise everywhere events aren't
        sound(sound2==0)=sound(sound2==0)+noise(1:length(sound(sound2==0)));
    else % Do add noise to events
        sound=sound+noise(1:length(sound));
        
        % limit output magnitude ?
        %         sound(sound>stim.mag)=stim.mag;
        %         sound(sound<-stim.mag)=-stim.mag;
    end
end


%% 5) Other stuff

% Cull off anything above event range?
if cfg.cull>0
    stim.cull=cfg.cull;
    sound(sound>cfg.cull)=cfg.cull;
    sound(sound<0-cfg.cull)=0-cfg.cull;
else
    stim.cull=0;
end

% What about values below 0 for Vis?
switch cfg.type
    case 'Aud'
    case 'Vis'
        % sound=abs(sound); % Does this half noise power?
        % Or?
        % sound=sound(sound<0)=0; %?
end

% Apply cut off to normalise lengths?
stim.cutOff = cfg.cutOff;
cO = round(cfg.cutOff/1000*cfg.Fs);
if length(sound)>cO
    sound=sound(1:cO);
end


%% 6) If original sound existed, check it's correct
%mm=0;
if exist('check_me','var')
    if sum(sound~=check_me)>0
        % Generated sound doesn't match original sound
        % Return original cfg including sound
        
        disp('Mismatch!')
        %mm=1;
    else
        disp('Stim OK')
    end
end


%% Save
% Structure can also be used as cfg
stim.sound=sound;
stim.gap_index=gap_index;
stim.durationActual=length(sound)/cfg.Fs*1000;

% Calculate average rate /s
stim.eventRate=cfg.nEvents/(stim.durationActual/1000);


% Move to appropriate places above
% stim.rise=rise/cfg.Fs*1000;
% stim.eventLength=eventLength/cfg.Fs*1000;

if cfg.dispWarn
    toc
end
rng('Shuffle');
