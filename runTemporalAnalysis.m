clear all %#ok<CLALL>

%% 1) Set up subject

% Main analysis directory
sParams.root = ...
    'S:\OneDrive\Gareth\Current\AC\fBehaviouralData\NeuralAnalysis';
cd(sParams.root);

% Box
sParams.box = 'Nellie';

% Subject
% sParams.fName = 'Twister';
% sParams.subject = 'Suarez';
sParams.subject = 'Snow';
% sParams.subject = 'Beryl';

% sParams.level = [8, 9, 10];
% sParams.level = 8;
sParams.level = [10, 11];

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
lim = 0;
if lim 
    sub.sessions.sessions = sub.sessions.sessions(1:lim,:);
    sub.sessions.nS = lim;
end
% Import
reImport = true;
forceNeural = false; % Force prcoessing of neural data from this stage.
sub.sessions = sub.sessions.importData(reImport, forceNeural);


%% Analyse individual sessions
% Do behavioural analysis (using BehavAnalysis)
% Do neural analysis (PSTH etc.) (Using NeuralAnalysis)

force = false;
sub.sessions.analyseBehav(force)
sub.sessions.analyseNerual(force)


%% Create combined sessions - level 9/10/11
% Join on dayIDs

level = 10;
sub = sub.importComboSessions('DID', level);
% Analyse combine sessions
force = true;
sub.comboSessions.DID = sub.comboSessions.DID.analyseBehav(force);
sub.comboSessions.DID = sub.comboSessions.DID.analyseNerual(force);


%% Create combined sessions - level 11
% Join on seedIDs

level = 11;
sub = sub.importComboSessions('SID2', level);
% Analyse combine sessions
force = true;
sub.comboSessions.SID2 = sub.comboSessions.SID2.analyseBehav(force);


%% Create combo sessions using all

level = 11;
sub = sub.importComboSessions('All', level);
sub.comboSessions.All = sub.comboSessions.All.analyseBehav(force);


%% Run comparision between combo sessions
% All vs SIDs2

% Do comps
sub.comboSessions.All = ...
    sub.comboSessions.All.compareSessions(sub.comboSessions.SID2);

% Plot summary
sub.comboSessions.All.plotSummaryComps


%% Run comparision between combo sessions
% SIDs2 vs SIDs2

close all

sub.comboSessions.SID2 = ...
    sub.comboSessions.SID2.compareSessions(...
    sub.comboSessions.SID2, false);


%% Plot summary deltas

close all
sub.comboSessions.SID2.plotSummaryCompsDeltas


%% Plot summary

close all
sub.comboSessions.SID2 = sub.comboSessions.SID2.plotSummaryComps;

