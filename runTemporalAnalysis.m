clear

%% 1) Set up subject

% Main analysis directory
sParams.root = ...
    'S:\OneDrive\Gareth\Current\AC\fBehaviouralData\NeuralAnalysis';
cd(sParams.root);

% Box
sParams.box = 'Nellie';

% Subject
% sParams.fName = 'Twister';
% sParams.fName = 'Suarez';
sParams.subject = 'Snow';
% sParams.fName = 'Beryl';

% sParams.level = [8, 9, 10];
% sParams.level = 8;
sParams.level = 10;

% The rest
sub = Subject(sParams);

% Sync
sub.syncSubject();


%% Find sessions

reImport = true;
sub = sub.importSessions(reImport);

% Plot summary
sub.sessions = sub.sessions.summary();


%% Import sessions

% Limit for debugging
lim = 50;
if lim 
    sub.sessions.sessions = sub.sessions.sessions(1:lim,:);
    sub.sessions.nS = lim;
end
% Import
reImport = true;
forceNeural = 3; % Force prcoessing of neural data from this stage.
sub.sessions = sub.sessions.importData(reImport, forceNeural);


%% Analyse sessions

force = false;
sub.sessions.analyseBehav(force)
