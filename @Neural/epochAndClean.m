function obj = epochAndClean(obj, EvIDs, behav)
% Handles epoching and cleaning on different EvIds. Calls epochData and
% clean to do actual work.
% Assuming BB_2, BB_3 (fData and lfpData) and Sens and Sond

% Set paths
obj.epochedPaths = [...
    getEpochedDataPath(obj, 'BB_2', 'fData'); ...
    getEpochedDataPath(obj, 'BB_2', 'lfpData'); ...
    getEpochedDataPath(obj, 'BB_3', 'fData'); ...
    getEpochedDataPath(obj, 'BB_3', 'lfpData'); ...
    getEpochedDataPath(obj, 'Sond'); ...
    getEpochedDataPath(obj, 'Sens')];

% Run
for e = 1:numel(EvIDs)
    id = EvIDs{e};
    switch id
        case {'BB_2', 'BB_3'}
            disp(['Epoching and cleaning ', id])
            % For BB_2 and BB_3 epoch both spikes and lfp
            % data, then clean spike data.
            
            % Check if already done
            % If either fData or lfpData missing, do all
            check = [getEpochedDataPath(...
                obj, id, 'fData');
                getEpochedDataPath(...
                obj, id, 'lfpData')];
            if exist(check(1).char(), 'file') ...
                    && exist(check(2).char(), 'file')
                disp([id, ' already done, skipping'])
            end
            
            % Load fData
            [fData, fs] = ...
                loadFilteredData(obj, id, 'fData');
            
            % Epoch fData
            fDataEpoch = epochData(...
                obj, behav, fData, fs);
            clear fData
            
            % Clean fDataEpoch
            % Check for bad channels before cleaning?
            fDataEpoch = obj.clean(fDataEpoch);
            
            % Save to epoched file
            writeEpochedData(obj, fDataEpoch, id, 'fData');
            clear fDataEpoch
            
            % Load lfpData
            [lfpData, fs] = ...
                loadFilteredData(obj, id, 'lfpData');
            
            % Epoch lfpData
            lfpDataEpoch = epochData(...
                obj, behav, lfpData, fs);
            clear lfpData
            
            % Save to epoched file
            writeEpochedData(obj, lfpDataEpoch, id, 'lfpData');
            clear lfpDataEpoch
            
        case {'Sens', 'Sond'}
            disp(['Epoching ', id])
            % For Sond and Sens, epoch raw data.
            
            % Check if already done
            check = getEpochedDataPath(obj, id, '');
            if exist(check(1).char(), 'file')
                disp([id, ' already done, skipping'])
            end
            
            % Load
            [data, fs] = loadExtractedData(obj, id);
            
            % Epoch current id
            dataEpoch = epochData(...
                obj, behav, data, fs);
            clear data
            
            % Save to epoched file
            writeEpochedData(obj, dataEpoch, id, '');
    end
end