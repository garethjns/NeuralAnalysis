function syncSubject(obj)
% Copies files and folders from one directory to another.
% Designed to copy files at source directory, then files one directory deep
% one by one, checking if they already exist. 
% Doesn't overwrite if file exists at destination. Doesn't check if files
% are different in any way.
%
% Works for deeper dirs, but doesn't check files individually.

tic
home

dest = obj.paths.behav.data;
source = obj.paths.behav.source;

% If destination doesn't exist, create it
if ~exist(dest,'file')
    mkdir(dest)
end

disp('  ')
disp('Copying from:')
disp(source)
disp('to:')
disp(dest)
disp('  ')

% Start counters for successes
suc = [0 0];
% And files that already exist at destination
ex = 0;

% Get list of folders (and files) in source folder
folders=dir([source, '*']);
for i = 1:length(folders)
    if folders(i).isdir==0 && ~(strcmp(folders(i).name, '.') || strcmp(folders(i).name, '..'))
        if ~exist([dest, folders(i).name], 'file')
            % Copy the files in the root directory over, if they don't exist at
            % destination, (and they aren't directories and they aren't called
            % '.' or '..')
            disp(['Copying ', source, folders(i).name, ' -> ',  ...
                dest, folders(i).name])
            suc = suc+FC([source, folders(i).name], ...
                [dest, folders(i).name]);
        else % File already exists at desintion
            ex = ex+1; % Count
        end
    end
end

% For each of the folders...
for i = 1:length(folders)
    if folders(i).isdir==0 || (strcmp(folders(i).name, '.') || strcmp(folders(i).name, '..'))
        % Ignore if '.' or '..', or if it's a root file not a directory
    else
        % ... Create folders at destination, if they don't exist
        % (this IS necessary!)
        if ~exist([dest, folders(i).name, '\'], 'file') && folders(i).isdir==1
            mkdir([dest, folders(i).name])
        end
        
        % Get list of files at source
        filesSource = dir([source, folders(i).name, '\*']);
        % filesDest=dir([dest, folders(i).name, '\*']); % Not needed
        
        % For each file in source list...
        for p=1:length(filesSource)
            if strcmp(filesSource(p).name, '.') || strcmp(filesSource(p).name, '..')
                % Ignore if '.' or '..'
            else
                % ... Copy if it doesn't exist at destination
                if ~exist([dest, folders(i).name, '\', ...
                        filesSource(p).name], 'file')
                    
                    disp(['Copying ', source, folders(i).name, '\', ...
                        filesSource(p).name, ' -> ',  ...
                        dest, folders(i).name, '\', filesSource(p).name])
                    
                    suc = suc+FC([source, folders(i).name, '\', ...
                        filesSource(p).name], ...
                        [dest, folders(i).name, '\', filesSource(p).name]);
                else % File already sxists at destination
                    ex = ex+1; % Count
                end
            end
        end
    end
end

disp('  ')
disp(['That took ', num2str(toc), 's'])
disp(['Copied ', num2str(suc(1)), ' files, failed to copy ', ... 
    num2str(suc(2)), ' files'])
if ex ~= 0
    disp([num2str(ex), ...
        ' files weren''t copied becuase they already existed at destination'])
end

function outcome = FC(source, destination)
try % Try to copy
    copyfile(source, destination)
    disp('Success!')
    outcome=[1 0]; % Record success
catch err % Report error if it doesn't work
    disp('Failed!')
    disp(err.identifier)
    disp(err.message)
    outcome=[0 1]; % Record failure
end
