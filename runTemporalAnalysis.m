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
% sParams.level = 10;
sParams.level = 11;

% The rest
sub = Subject(sParams);


%% Sync

sub.syncSubject();


%% Find sessions

sub = sub.importSessions(true);

% Plot summary
sub.sessions = sub.sessions.summary();


%% Import sessions

% Limit for debugging
lim = 3;
if lim 
    sub.sessions.sessions = sub.sessions.sessions(1:lim,:);
    sub.sessions.nS = lim;
end
% Import
sub.sessions = sub.sessions.importData(true);


%% Analyse sessions

sub.sessions.analyseBehav(false)