classdef Sessions
    % Import list of sessions for subject
    % Inherit session methods for reporting and plotting
    %
    % Data structure on disk:
    % For individual sessions:
    % \BehavAnalysis\IndividualSessions\:
    % \Level xx\division ID (session)\
    % For combosessions:
    % \BehavAnalysis\JoinedSessions\:
    % \Level\ID and date
    % ID can be ID used to divide data eg. SID2 or DID or All
    % Inside is same analysis run on combined data
    % Subfolders then contain comparisions from Sessions.CompareData
    % Eg. sub.comboSessions.All.compareSessions(sub.comboSessions.SID2s):
    % All_Dates\...
    % SID2s_1s\ % 1s compared to all
    % SID2s_2s\ % 2s compared to all
    
    properties (SetAccess = immutable)
        subject
        fID
    end
    
    properties
        levels
        sessions % Tabulated list of sessions
        sessionData = cell(1) % Exp objects containing data for sessions
        sessionStats % Stats for session
        compStatsMeta % List of comparisons\paths
        compStats % States compared to another session
        compStatsSessionData;
        nS % Number of sessions
        nT % Total number of trials available
        targetSide % "Fast" side, constant per subject
    end
    
    properties (Hidden = true)
        % Kept for convenience/debugging, Hidden for tidyness:
        subjectParams % Parameters set for subject
        subjectPaths % Paths set for subject
        forceNeural = 0;
    end
    
    methods
        
        function obj = Sessions(sub, reImport)
            
            obj.subject = sub.subject;
            obj.levels = sub.levels;
            obj.fID = sub.fID;
            obj.subjectParams = sub.params;
            obj.subjectPaths = sub.paths;
            obj.targetSide = sub.params.targetSide;
            
            % Import sessions for subject
            % Reload or reimport?
            if ~reImport
                
                % Attempt load
                try
                    fns = dataSetFns(obj);
                    tic
                    load(fns{1})
                    disp(['Loaded ', ...
                        num2str(height(sessions.sessions)), ...
                        ' trials in ', ...
                        num2str(toc), 's.'])
                    obj = sessions;
                    loadOK = true;
                catch
                    disp('Load failed, importing...')
                    loadOK = false;
                end
                
                if ~loadOK
                    reImport = true;
                end
            end
            
            % Reimport and save if not loaded
            if reImport
                obj.sessions = obj.findSessions(sub);
                obj.nS = height(obj.sessions);
                obj.saveSessions(sub);
            end
            
        end
        
        function saveSessions(obj, sub)
            
            % Generate file names
            fns = dataSetFns(obj);
            
            % Rename obj to sessions in saved file
            sessions = obj; %#ok<NASGU,PROPLC>
            
            disp('Saving .mat')
            save(fns{1}, ...
                'sessions', 'sub')
            
            disp('Writing table')
            writetable(obj.sessions, [obj.fID, '_', sub.subject, ...
                fns{2}])
            
            disp(['Saved: ', obj.fID, '_',  sub.subject, ...
                '_SessionDataset .mat/.txt'])
        end
        
        function obj = importData(obj, reImport, forceNeural)
            % Create table for analysis from sess objects
            
            if ~exist('forceNeural', 'var')
                forceNeural = 0;
            end
            
            if ~reImport
                % Load
            end
            
            obj.nT = 0;
            for s = 1:obj.nS
                % Report and time for debugging
                a = string('*').pad(30, '*');
                disp(a)
                disp(['Importing session: ', num2str(s), ...
                    '/', num2str(obj.nS)])
                tic
                % Create session object for each session using table row
                % from Sessions and subject's parameters/paths
                obj.sessionData{s} = Sess(obj.sessions(s,:), ...
                    {obj.subjectParams, obj.subjectPaths}, ...
                    forceNeural);
                b = toc;
                disp(['Done in ', num2str(b) ', S @ ', ...
                    num2str(obj.sessionData{s}.nTrials/b), ' t/S'])
                
                obj.nT = obj.nT + obj.sessionData{s}.nTrials;
            end
            
        end
        
        function fns = dataSetFns(obj)
            l = obj.l2fn(obj.levels);
            fns{1} = [obj.fID, '_', obj.subject, ...
                '_levels', l, '_SessionDataset.mat'];
            fns{2} = [obj.fID, '_', obj.subject, ...
                '_levels', l, '_SessionDataset.txt'];
        end
        
        function obj = analyseBehav(obj, force)
            % Analyse all sess objects held in session, if not already
            % done.
            % (Using Sess.analyseBehav(sessObj)
            
            % Check force parameter - if true force redoing of analysis of
            % each Sess object, ignoring .analysisDone.
            if ~exist('force', 'var')
                % Default to false
                force = false;
            end
            
            for s = 1:obj.nS
                % Check analysis flag
                sess = obj.sessionData{s};
                
                % First check session obj isn't totally empty
                if isempty(sess.data)
                    continue
                end
                
                % And that analysis hasn't already been done
                if ~(sess.behavAnalysisDone == 0 || force)
                    % Done, don't redo
                    continue
                end
                
                % Else, run analysis
                obj.sessionData{s} = obj.sessionData{s}.analyseBehav();
                
            end
        end
        
        function obj = analyseNerual(obj, force)
            % Analyse all sess objects held in session, if not already
            % done.
            % (Using sess.analyseNeural)
            
            for s = 1:obj.nS
                % Check analysis flag
                sess = obj.sessionData{s};
                
                % First check session data (behav) obj isn't totally empty
                if isempty(sess.data)
                    continue
                end
                
                % Then check there is a neural object.
                if isempty(sess.neuralData)
                    continue
                end
                
                % And that analysis hasn't already been done
                if ~(sess.neuralAnalysisDone == 0 || force)
                    % Done, don't redo
                    continue
                end
                
                % Else, run analysis
                obj.sessionData{s} = obj.sessionData{s}.analyseNeural();
                
            end
        end
        
        function obj = compareSessions(obj, comps, plotOn, verbosity)
            % obj is Sessions containing single or multiple (?) comboSess
            % comps is Sessions containg multiple comboSess Stats are in
            % sessionData{x}.stats
            %
            % Compare this session to a group of other sessions For
            % example, if this session is 'All' combo and comps = SID2s
            % combo, compare the DT, bias, perf for each session in comps
            % to this session
            % Assumes all sessions already analysed - not
            % checking flag for now
            % Order is important for indirected comparisons
            % eg comps..bsAvgAsMs will be compared to
            % obj..bsgAvgs
            
            % Set defaults
            if ~exist('plotOn', 'var')
                figInfo.plotOn = true;
            else
                figInfo.plotOn = plotOn;
            end
            if ~exist('verbosity', 'var')
                figInfo.verbosity = 1;
            else
               figInfo.verbosity = verbosity;
            end
            
            % Count comparisons
            n1 = numel(obj.sessionData);
            n2 = numel(comps.sessionData);
            
            % Output these (reference) x those (targets)
            obj.compStats = cell(n1, n2);
            % Keep the comps in this object for reference
            obj.compStatsSessionData = comps.sessionData;
            
            % For each session in this object
            for n = 1:n1
                % Stats1 (left input) from object
                stats1 = obj.sessionData{n}.stats;
                s1Title = obj.sessionData{n}.title;
                
                % To command window if verbosity>0
                if figInfo.verbosity
                    disp(' ')
                    disp(['Comparing', s1Title, ' (reference) to ...'])
                end
                
                % Compare with each session in comp object
                for m = 1:n2
                    % Stats2 (right input) from input
                    stats2 = comps.sessionData{m}.stats;
                    s2Title = comps.sessionData{m}.title;
                    
                    % To command window if verbosity>0
                    if figInfo.verbosity
                        disp(['...', s2Title, ' (target)'])
                    end
                    
                    % Prepare meta data and sub directory for this
                    % comparison
                    obj.compStatsMeta{n,m}.m = m;
                    obj.compStatsMeta{n,m}.n = n;
                    obj.compStatsMeta{n,m}.mName = s2Title;
                    obj.compStatsMeta{n,m}.nName = s1Title;
                    
                    % Make sub path
                    % Parent:
                    s1 = string(s1Title);
                    % Child, remove top dir levels
                    s2 = string(s2Title).split('\');
                    % Join to create sub directory
                    s3 = [s1, '\', s2(end)];
                    s3 = s3.join('').char();
                    
                    % Set file name and level path
                    figInfo.titleAppend = s3;
                    figInfo.fns = ...
                        [obj.subjectPaths.behav.joinedSessAnalysis, ...
                        figInfo.titleAppend, '\'];
                    
                    % If saving graphs, clear and create directory
                    % If not saving graphs, don't make one and/or
                    % leave existing directory
                    if figInfo.plotOn
                        try
                            if exist(figInfo.fns, 'dir')
                                rmdir(figInfo.fns, 's')
                            end
                            mkdir(figInfo.fns)
                        catch err
                            disp(err)
                        end
                    end
                    
                    % Save to meta table
                    obj.compStatsMeta{n, m}.figInfo = figInfo;
                    
                    % Run direct comparisons
                    % None of these are active yet and will need updating
                    % (see indirectStatsComp)
                    % Sessions.directStatComp(stats1, stats2)
                    
                    % Run indirect comparisons
                    obj.compStats{n, m} ...
                        = Sessions.indirectStatComp(stats1, stats2, ...
                        figInfo);
                    
                    % Close any created figures
                    if figInfo.plotOn
                        close all
                    end
                end
            end
        end
        
        
        function [obj, hP] = plotSummaryComps(obj)
            % This plot is comparison on AVASync performance (at whatever
            % AsM settings and for whatever metrics) vs AVSync performance
            % from the same session group.
            %
            % compStats is nRef x nTar, representing each session compared
            % to every other session.
            % So Data for references is consistent across columns and data
            % for targets is consistent across rows
            %
            % If the comparision data is from a symmetrical generator [ie.
            % reference sessions == target sessions, such as SID2s (not an
            % "all" generator (which would have just one reference, mean
            % for all sessions)] then the diagonal is AVa compared to AVs
            % from the same session
            % 
            % Inside each cell is the stats object. This contains the
            % bl_comp (delta) fields that are used in
            % plotSummaryCompsDeltas and the .data field which contains the
            % data used to calculate the delta
            % This will include n performance metrics (eg. PCCorr and bs) *
            % n AsM setting combinations (currently 3) * [ref, tar] = 12
            % fields.
            %
            % bsAvgAsM1_ref: [0.0200 0.0200 6.8601 4.2763]
            % vs
            % bsAvgAsM1_tar: [5×4 double]
            %
            % bsAvgAsM2_ref: [0.0200 0.0200 6.8601 4.2763]
            % vs
            % bsAvgAsM2_tar: [3×4 double]
            %
            % bsAvgAsM3_ref: [0.0200 0.0200 6.8601 4.2763]
            % vs
            % bsAvgAsM3_tar: [3×4 double]
            %
            % PCCorAsM1_ref: 75.4386
            % vs
            % PCCorAsM1_tar: [72.2222 78.9474 81.8182 68.5714 57.1429]
            %
            % PCCorAsM2_ref: 75.4386
            % vs
            % PCCorAsM2_tar: [72.2222 80.4878 65.3061]
            %
            % PCCorAsM3_ref: 75.4386
            % vs
            % PCCorAsM3_tar: [72.2222 71.8750 73.0769]
            %
            % These data are extracted in to a matrix form useful for
            % scatter plots. The reference matrix (X data) for a metric
            % will be nRef x nTar x 1 (again, with the diagonal being a
            % self comparison).
            % The target (Y Data) will be nRef x nTar x the number of AsM 
            % bins. Colors/symbols are used to differeniate this dimesion
            % on the scatter plots.
            % Where a performance metrix has multiple feature - like bs; g,
            % l, u, v, these are stored in the 4th dimension and need to go
            % on seperate plots/subplots.
            %
            % TODO:
            % 1) It might be worth saving these matrixes for convenience
            % later
            % 2) Add regression lines
            
            nRef = size(obj.compStats, 1);
            nTar = size(obj.compStats, 2);
            
            asMode = 'AsM1';
            nAsMBins = ...
                size(obj.compStats{1}.data.(['PCCor', asMode, '_tar']),2);
            
            % PC Plots
            nFea = 1;
            PCDataRef = NaN(nRef, nTar, 1, nFea);
            PCDataTar = NaN(nRef, nTar, nAsMBins, nFea);
                
            % Extract data from cells
            for r = 1:nRef
                for t = 1:nTar
                    PCDataRef(r,t,1,1) = ...
                        obj.compStats{r,t}...
                        .data.(['PCCor', asMode, '_ref']);
                    
                    PCDataTar(r,t,:,1) = ...
                        obj.compStats{r,t}...
                        .data.(['PCCor', asMode, '_tar']);
                end
            end
            
            % Plot scatter for PCCor, and each AsMBin
            figure
            hold on
            for a = 1:nAsMBins
                scatter(diag(PCDataRef), diag(PCDataTar(:,:,a)))
            end
            axis([0,100,0,100])
            
            % bs Plots
            nFea = 4;
            bsDataRef = NaN(nRef, nTar, 1, nFea);
            bsDataTar = NaN(nRef, nTar, nAsMBins, nFea);
                
            % Extract data from cells
            for r = 1:nRef
                for t = 1:nTar
                    bsDataRef(r,t,1,:) = ...
                        obj.compStats{r,t}...
                        .data.(['bsAvg', asMode, '_ref']);
                    
                    
                    data = obj.compStats{r,t}...
                        .data.(['bsAvg', asMode, '_tar']);
                    % Permute coeffs (2) to 4 and AsM bins (1) to 3
                    data = permute(data, [3,4,1,2]);
                    
                    % HERE
                    % Need to handle NaNs (saved as row of 1x4)
                    bsDataTar(r,t,:,:) = data;
                end
            end

            
        end
        
        function [obj, hP] = plotSummaryCompsDeltas(obj)
            % Plot summary plots of differences.
            % Two kinds of plots:
            % 1) Row by row (hT, transient - saved to disk, closed)
            % ie. Reference compared targets
            % eg.,
            % For each row in the stats matrix, boxplot the
            % stats in the columns. In this case, plots the
            % deltas calculated from the sub directiories inside the
            % reference
            % 2) All (hP, persistent - saved to disk, kept)
            % ie. ReferenceS compared to targets
            % eg.,
            % For each row, add to scatter plot
            %
            % Paths are already available in obj.compStatsMeta.figInfo
            % There's a plot for each metric ie.
            % "blComp_bsAvgAsM1"
            % "blComp_bsAvgAsM2"
            % "blComp_bsAvgAsM3"
            % "blComp_PCCorAsM1"
            % "blComp_PCCorAsM2"
            % "blComp_PCCorAsM3"
            % This isn't flexible, has to be this order. Need to 
            % ignore.data field too.
            
            % These are the comparisons to be plotted
            
            
            % Create figure handles
            % plots (bl, PC) x metric
            % Assuming there are 3 AsM levels to plot
            % Transient
            hT = gobjects(2,3);
            for p = 1:numel(hT(:))
                hT(p) = figure;
            end
            % Persistent
            hP = gobjects(2,3);
            for p = 1:numel(hP(:))
                hP(p) = figure;
            end
            
            % Check what to do
            if isempty(obj.compStats)
                disp('No comparisons to plot')
                return
            end
            
            % Create plots for each row (reference, session from this 
            % object).
            % Data from comp object (targets, columns) goes on each plot.
            % Column loop in plot functions
            
            n1 = size(obj.compStats, 1);
            for n = 1:n1
                % Extract data
                row = obj.compStats(n,:);
                metaRow = obj.compStatsMeta(n,:);
                
                % Find available fields
                % fns = string(fieldnames(row{1}));
                fns = ex; % Currently defined at top of function
                nC = numel(fns);

                for f = 1:nC
                    
                    if fns(f).contains('bs')
                        % Plot curve comparisons
                        obj.plotCurveComps(row, metaRow, ...
                            fns(f).char(), hT(1,f), hP(1,f));
                    end
                    
                    if fns(f).contains('PC')
                        % Plot PCCor comarsions
                        obj.plotPCComps(row, metaRow, ...
                            fns(f).char(), hT(2,f-3), hP(2,f-3));
                    end
                end
            end
            
            % Finish persistent figures
            
        end

        function plotCurveComps(~, row, metaRow, field, hT, hP)
            
            % Ready data
            m = size(row,2);
            o = size(row{1}.(field), 1); % Assume first session is ok!
            % n x AsMs x nCoeffs ([g, l, u, v])
            data = NaN(m, o, 4);
            for r = 1:m
                % Permute coeffs to 3rd dim
                
                % If somethings gone wrong - missing data perhaps? Or
                % missing type from short session? And size of this
                % sessions data aren't consistent, skip over
                if size(row{r}.(field), 1) ~= o
                    continue
                end
                
                data(r,:,:) = permute(row{r}.(field), [3,1,2]);
            end
            
            % Remove "all"
            data = data(:,2:end,:);
            o = size(data, 2);
            
            % Plot u, v
            figure(hT)
            clf
            subplot(1,2,1)
            boxplot(data(:,:,3))
            title('Bias')
            
            subplot(1,2,2)
            boxplot(data(:,:,4))
            title('DT')
            xlim([0, o+1])
            
            suptitle([field, ' group[AVs] - mean(groups[AVa])'])
            
            % Save figure, using any obj.compStatsMeta{xx}.figInfo
            % corresponding to this row
            
            % Get full path (could just use obj.paths...)
            fp = string(metaRow{1}.figInfo.fns)...
                .extractBefore(metaRow{1}.nName);
            fp = [fp, metaRow{1}.nName, '\', field, '_summary.png'];
            fp = fp.join('');
            
            % Save
            BehavAnalysis.ng;
            BehavAnalysis.hgx(fp)
            
            % Add to persistent figures
            figure(hP)
            subplot(1,2,1)
            hold on
            for xi = 1:o
                x = repmat(xi, size(data, 1), 1);
                scatter(x, data(:,xi,3))
            end
            
            subplot(1,2,2)
            hold on
            for xi = 1:o
                x = repmat(xi, size(data, 1), 1);
                scatter(x, data(:,xi,4))
            end
            
        end
       
        function plotPCComps(~, row, metaRow, field, hT, hP)
            
            % Ready data
            m = size(row, 2);
            o = size(row{1}.(field), 2);
            % n x AsMs x nCoeffs ([g, l, u, v])
            data = NaN(m, o);
            for r = 1:m
                data(r,:) = row{r}.(field);
            end
            
            % Remove "all"
            data = data(:,2:end);
            o = size(data, 2);
            
            figure(hT)
            clf
            boxplot(data)
            title('PC Correct')
            ylabel('Delta, %')
            xlabel('AsM rating ->')
            
            suptitle([field, ' group[AVs] - mean(groups[AVa])'])
            % Save figure, using any obj.compStatsMeta{xx}.figInfo
            % corresponding to this row
            
            % Get full path (could just use obj.paths...)
            fp = string(metaRow{1}.figInfo.fns)...
                .extractBefore(metaRow{1}.nName);
            fp = [fp, metaRow{1}.nName, '\', field, '_summary.png'];
            fp = fp.join('');
            
            % Save
            BehavAnalysis.ng;
            BehavAnalysis.hgx(fp)
            
            % Add to persistent figures
            figure(hP)
            hold on
            for xi = 1:o
                x = repmat(xi, size(data, 1), 1);
                scatter(x, data(:,xi))
            end
        end
        
    end
    
    methods (Static)
        
        function delta = directStatComp(stats1, stats2)
            % Compare matching fields in each stats structure
            % Output as delta structure with same fieldnames
            % WIP
            
            fn1 = string(fieldnames(stats1));
            fn2 = string(fieldnames(stats2));
            for n = 1:numel(fn1)
                % Field in fn2?
                f = fn1(n).char();
                if any(fn2.eq(f))
                    
                    % Different fields need to be treated differently
                    switch f
                        case {'fastProp', 'fastPropAsM1', ...
                                'fastPropAsM2', 'fastPropAsM3'}
                            % [6×?×3 double]
                        case {'fastPropFitted', 'fastPropFittedAsM1', ...
                                'fastPropFittedAsM2', 'fastPropFittedAsM3'}
                            % [100×5 double] (curves)
                        case {'bsAvg', 'bsAvgAsM1', ...
                                'bsAvgAsM2', 'bsAvgAsM3'}
                            % Fit objects
                            % bsAvg:
                            % 6 fits, plus offset fits
                            % 1: All, 2:Aud, 3:Vis, 4:Sync, 5:Async
                            
                            stats1.(f).data
                            stats2.(f).data
                            
                        case {'PCCor', 'PCCorAsM1', ...
                                'PCCorAsM2', 'PCCorAsM3'}
                            % [1×5 table]
                            
                        otherwise
                            try
                                delta.(f) = stats1.(f) - stats2.(f);
                            catch
                                
                            end
                    end
                    
                end
                
            end
        end
        
        function fn = l2fn(levels)
            % Add levels to file name
            l = ('_' + string(levels'))';
            fn = l.join('').char();
        end
        
        % Indirect stats comparisons
        stats = indirectStatComp(stats1, stats2, figInfo)
        
        % Template table for sessions (external file)
        emptyTable = sessionsTable(nTrials)
        
    end
end