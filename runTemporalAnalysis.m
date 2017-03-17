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

sub.syncSubject


%% Find sessions

sub = sub.importSessions(false);
