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
        
        function obj = compareSessions(obj, comps)
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
            
            n1 = numel(obj.sessionData);
            n2 = numel(comps.sessionData);
            
            % Output these x those
            obj.compStats = cell(n1, n2);
            % Keep the comps in this object for reference
            obj.compStatsSessionData = comps.sessionData;
            
            % For each session in this object
            for n = 1:n1
                % Stats1 (left input) from object
                stats1 = obj.sessionData{n}.stats;
                s1Title = obj.sessionData{n}.title;
                % Compare with each session in comp object
                for m = 1:n2
                    % Stats2 (right input) from input
                    stats2 = comps.sessionData{m}.stats;
                    s2Title = comps.sessionData{m}.title;
                    
                    % Prepare meta data and sub directory for this
                    % comparison
                    obj.compStatsMeta{n, m}.m = m;
                    obj.compStatsMeta{n, m}.n = n;
                    obj.compStatsMeta{n, m}.mName = s2Title;
                    obj.compStatsMeta{n, m}.nName = s1Title;
                   
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
                    
                    try
                        if exist(figInfo.fns, 'dir')
                            rmdir(figInfo.fns)
                        end
                        mkdir(figInfo.fns)
                    catch err
                        disp(err)
                    end
                    % Save to meta table
                    obj.compStatsMeta{n, m}.figInfo = figInfo;
                    
                    
                    % Run direct comparisons
                    % None of these are active yet
                    % Sessions.directStatComp(stats1, stats2)
                    
                    % Run indirect comparisons
                    obj.compStats{n, m} ...
                        = Sessions.indirectStatComp(stats1, stats2, ...
                        figInfo);
                    
                    close all
                end
            end
        end
        
        
        
        function obj = plotSummaryComps(obj)
            % Plot summary plots of differences.
            % For example, for each row in the stats matrix, boxplot the
            % stats in the columns.
            % Ie. this function works for each reference, and plots the
            % deltas calculated from the sub directiories inside the
            % reference
            % Paths are already available in obj.compStatsMeta.figInfo
            % Actual plot functions are called stat by stat, which is a bit
            % weird.
            
            % Check what to do
            if isempty(obj.compStats)
                disp('No comparisons to plot')
                return
            end
            
            % Create plots for each row (session from this object)
            % Data from comp object (columns) goes on each plot.
            % Column loop in plot functions
            
            n1 = size(obj.compStats, 1);
            
            for n = 1:n1
                
                % Extract data
                row = obj.compStats(n,:);
                metaRow = obj.compStatsMeta(n,:);
                
                % Find available fields
                fns = string(fieldnames(row{1}));
                nC = numel(fns);
                for f = 1:nC
                    
                    if fns(f).contains('bs')
                        % Plot curve comparisons
                       obj.plotCurveComps(row, metaRow, ...
                           fns(f).char());
                    end
                    
                    if fns(f).contains('PC')
                        % Plot PCCor comarsions
                        obj.plotPCComps(row, metaRow, ...
                            fns(f).char());
                    end
                end
            end
            
            
        end
        
        function plotPCComps(~, row, metaRow, field)
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
            
            figure
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
            
            BehavAnalysis.ng;
            BehavAnalysis.hgx(fp)
            
        end
        
        function plotCurveComps(~, row, metaRow, field)
            
            m = size(row,2);
            o = size(row{1}.(field), 1);
            % n x AsMs x nCoeffs ([g, l, u, v])
            data = NaN(m, o, 4);
            for r = 1:m
                % Permute coeffs to 3rd dim
                data(r,:,:) = permute(row{r}.(field), [3,1,2]);
            end
            
            % Remove "all"
            data = data(:,2:end,:);
            o = size(data, 2);
            
            % Plot u, v
            figure
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
            
            BehavAnalysis.ng;
            BehavAnalysis.hgx(fp)
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
        
        function stats = indirectStatComp(stats1, stats2, figInfo)
            % Do indirect comparisons of stats. Eg. stats1.bsAvg to
            % stats2.bsAvg.AsM1:
            % AVs coeffs extracted from stats1.bsAvg (blCoeffs, 1x4)
            % Coeffs at each AsM extracted from stats2.bsAvg.AsM1
            % (coeffs, nx4)
            % Save in stats as coeffs-blCoeffs (n x 4)
            % Plot comparisons
            
            pairs = {'bsAvg', 'bsAvgAsM1'; ...
                'bsAvg', 'bsAvgAsM2'; ...
                'bsAvg', 'bsAvgAsM3'; ...
                'PCCor', 'PCCorAsM1'; ...
                'PCCor', 'PCCorAsM2'; ...
                'PCCor', 'PCCorAsM3'};
            
            nP = size(pairs,1);
            
            for p = 1:nP
                switch pairs{p,1}
                    case 'bsAvg'
                        % Dealing with cfit objects
                        
                        % Get the AV sync baseline - (3) is AVs
                        if isa(stats1.bsAvg(3), 'double')
                            % If fit missing, NaN
                            blCoeffs = NaN(1,4);
                        else
                            blCoeffs = coeffvalues(stats1.bsAvg(3).data);
                        end
                        
                        % Extract the coeffs from other cfit models
                        nComps = numel(stats2.(pairs{p,2}));
                        coeffs = NaN(nComps, 4);
                        for n = 1:nComps
                            if isa(stats2.(pairs{p,2})(n).data, 'double')
                                % If fit missing, NaN
                                coeffs(n,:) = NaN(1,4);
                            else
                                coeffs(n,:) = ...
                                    coeffvalues(...
                                    stats2.(pairs{p,2})(n).data);
                            end
                        end
                        
                        % blCoeffs is 1x [g, l, u, v]
                        % coeffs is now nFits x [g, l, u, v]
                        % First row is "all"
                        % Compare coeffs-blCoeffs on each coeff row
                        % (implicit expansion)
                        % And save to stats structure
                        stats.(['blComp_', (pairs{p,2})]) = ...
                            coeffs-blCoeffs;
                        
                        % Plot this comparison bargraph for each coeff
                        figure
                        for c = 1:4
                            subplot(2,2,c)
                            hold on
                            bar(0, blCoeffs(1,c))
                            % Exclude "all" 
                            bar(coeffs(2:end,c), 'FaceColor', 'y')
                            
                            % bar([repmat(blCoeffs(1,c),nComps,1), ...
                            %    coeffs(:,c)])
                            
                            switch c
                                case 1
                                    ylabel('g, mag')
                                    title('Guess rate')
                                case 2
                                    ylabel('l, mag')
                                    title('Lapse rate')
                                case 3
                                    ylabel('u, mag')
                                    title('Bias')
                                case 4
                                    ylabel('v, mag')
                                    title('DT')
                            end
                            xlabel('AsM rating ->')
                            legend({'Reference (AVs)', 'Async'})
                        end
                        suptitle(['Curve comp: ', pairs{p,1}, ' to ', ...
                            pairs{p,2}, ' [' figInfo.titleAppend, ']'])
                        
                        BehavAnalysis.ng('Big')
                        fn = [figInfo.fns, 'Curve comp_', ...
                            pairs{p,1}, '_', ...
                            pairs{p,2}, ...
                            '.png';];
                        BehavAnalysis.hgx(fn)
                        
                    case 'PCCor'
                        % Dealing with table objects
                        
                        % Get numbers - All, A, V, AVs, AVa
                        blPCCor = stats1.PCCor;
                        
                        % Extract the coeffs from other cfit models
                        % All, a1, a2, a3, a4....
                        PCCor = stats2.(pairs{p,2}){1,:};
                        
                        % Compare all to AVs
                        stats.(['blComp_', (pairs{p,2})]) = ...
                            PCCor - blPCCor.AVsync;
                        
                        % Plot comparison bargraph
                        figure
                        hold on
                        bar(0, blPCCor.AVsync)
                        % Exclude "all"
                        bar(PCCor(2:end), 'FaceColor', 'y')
                        xlabel('AsM rating ->')
                        ylabel('% Correct')
                        legend({'Reference (AVs)', 'Async'})
                        suptitle(['PC comp: ', pairs{p,1}, ' to ', ...
                            pairs{p,2}, ' [' figInfo.titleAppend, ']'])
                        
                        BehavAnalysis.ng('Big')
                        fn = [figInfo.fns, 'Curve comp_', ...
                            pairs{p,1}, '_', ...
                            pairs{p,2}, ...
                            '.png';];
                        BehavAnalysis.hgx(fn)
                end
            end
            
            
        end
        
        function fn = l2fn(levels)
            % Add levels to file name
            l = ('_' + string(levels'))';
            fn = l.join('').char();
        end
        
        % Template table for sessions (external file)
        emptyTable = sessionsTable(nTrials)
        
    end
end