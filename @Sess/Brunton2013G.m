function acc = Brunton2013G(events, params)
% The Brunton model is for L vs R information.
% This is a modified version for rate task

% Defualt params?
if ~isstruct(params)
    params.a = 0;
    params.aVar = 1;
    params.sVar = 0;
    params.lam = 1;
    params.C = 1;
    params.phi = 2;
    params.tauPhi = 1;
    params.B = 100;
    params.plot = 0;
end

% Generate events?
if isempty(events)
    n = 200;
    events = rand(1, n);
    events(events>0.95) = 1;
    events = floor(events);
%     events = rand(1, n);
%     events(events>0.65) = 1;
%     events = floor(events);
end

if params.plot
    clf
    subplot(2,1,1), plot(events)
end

%% Set up
% time
t = 1:length(events);
nt = numel(t);
acc = NaN(1,nt);

% Initial value of acc
acc(1) = params.a;
% Noise of initial value
aVar = params.aVar;
aRho = randn(1,nt)*aVar; % ie IID N(1,aVar)
% Noise (sensory)
sVar = params.sVar;
sRhoR = randn(1,nt)*sVar + 1; % ie IID N(1,sVar)
% sRhoL = randn(1,nt)*sVar + 1; % ie IID N(1,sVar)
% Scaled by amplitude of impulse
C = NaN(1, nt);
C(1) = params.C; % Amplitude of
deltaR = events; % Delta function, ie. [... 0 0 0 0 1 0 0 0 0 ... ] (*C in model)
% deltaL = eventsL;
% Drift <0 = leaky, >0 unstable
lam = params.lam;
% Memory time constant
tau = 1/lam;
% Decision boundary
B = params.B;
% Sesnory adaptation
phi = params.phi; % Mag, >1 facilitation, <1 depression
tauPhi = params.tauPhi; % Time constant of adaptation


% Model
% acc(t) = aVar*W + (deltaR(t) * sRohR * C)
% + lam*acc(t-1)
% C = (1 - C)/tauPhi + (tau-1)*c*(deltaR(t)+deltaL(t))


%% Run
%t = 1:length(eventsL);
nt = length(events);

acc(1) = deltaR(1);

for t = 2:nt
   % C(t) = (1 - C(t-1))/tauPhi + (phi-1)*C(t-1)*(deltaR(t));
    C(t) = 1;
    acc(t) = aRho(t-1) + ... % Acc noise +
        deltaR(t)*sRhoR(t)*C(t) + ... % Sesnory information + noise +
        lam*acc(t-1); % Previous acc contents * AR coeff
    
    if params.plot
        subplot(2,1,2), plot(1:t, acc(1:t))
        drawnow
    end
end

