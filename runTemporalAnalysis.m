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
sParams.level = 11;

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
% Import behavioural data
% Try to import and preprocess neural data, if data is available

% Limit for debugging
lim = 0
if lim 
    sub.sessions.sessions = sub.sessions.sessions(1:lim,:);
    sub.sessions.nS = lim;
end
% Import
reImport = true;
forceNeural = 0; % Force prcoessing of neural data from this stage.
sub.sessions = sub.sessions.importData(reImport, forceNeural);


%% Analyse individual sessions
% Do behavioural analysis (using BehavAnalysis)
% Do neural analysis (PSTH etc.) (Using NeuralAnalysis)

force = false;
% sub.sessions.analyseBehav(force)
% sub.sessions.analyseNerual(force)


%% Create combined sessions

sub = sub.importComboSessions('SID2s');


%% Analyse combine sessions

sub.comboSessions.analyseBehav(force)

% TODO:
% Fix psychometric curves
% Fix image saving paths - double \\ and not saving to joined analysis
% folder

