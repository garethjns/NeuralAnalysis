function [stats] = indirectStatComp(stats1, stats2, figInfo)
% Do indirect comparisons of stats. Eg. stats1.bsAvg to
% stats2.bsAvg.AsM1:
% AVs coeffs extracted from stats1.bsAvg (blCoeffs, 1x4)
% Coeffs at each AsM extracted from stats2.bsAvg.AsM1
% (coeffs, nx4)
% Save in stats as 'blcomp_' coeffs-blCoeffs (n x 4)
% Save data in .data field
% Plot comparisons

pairs = {'bsAvg', 'bsAvgAsM1'; ...
    'bsAvg', 'bsAvgAsM2'; ...
    'bsAvg', 'bsAvgAsM3'; ...
    'PCCor', 'PCCorAsM1'; ...
    'PCCor', 'PCCorAsM2'; ...
    'PCCor', 'PCCorAsM3'};

% To command window if level >1
if figInfo.verbosity>1
    disp(pairs)
end

% Loop over pair rows
nP = size(pairs,1);
for p = 1:nP
    switch pairs{p,1}
        case 'bsAvg'
            % Dealing with cfit objects
            
            % Get/check reference
            % Get the AV sync baseline - (4) is AVs
            if ~isa(stats1.bsAvg, 'struct')
                % If fit missing, NaN
                blCoeffs = NaN(1,4);
            else
                blCoeffs = coeffvalues(stats1.bsAvg(4).data);
            end
            
            % Get/check target
            % Extract the coeffs from other cfit models
            nComps = numel(stats2.(pairs{p,2}));
            coeffs = NaN(nComps, 4);
            for n = 1:nComps
                if ~isa(stats2.(pairs{p,2})(n), 'struct') ...
                        || isa(stats2.(pairs{p,2})(n).data, ...
                        'double')
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
            % Also save data
            stats.data.([pairs{p,2}, '_ref']) = blCoeffs;
            stats.data.([pairs{p,2}, '_tar']) = coeffs;
            
            if figInfo.plotOn
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
                suptitle(['Curve comp: ', ...
                    pairs{p,1}, ' to ', ...
                    pairs{p,2}, ' [' figInfo.titleAppend, ']'])
                
                BehavAnalysis.ng('Big')
                fn = [figInfo.fns, 'Curve comp_', ...
                    pairs{p,1}, '_', ...
                    pairs{p,2}, ...
                    '.png';];
                BehavAnalysis.hgx(fn)
            end
            
        case 'PCCor'
            % Dealing with table objects
            
            % Get/check reference
            if isa(stats1.PCCor, 'table')
                % All, A, V, AVs, AVa
                blPCCor = stats1.PCCor;
            else
                blPCCor.AVsync = NaN;
            end
            
            % Get/check target
            if  isa(stats2.(pairs{p,2}), 'double')
                % Missing
                PCCor = NaN;
            else
                % Extract the coeffs from other cfit models
                % All, a1, a2, a3, a4....
                PCCor = stats2.(pairs{p,2}){1,:};
            end
            
            % Compare all to AVs
            stats.(['blComp_', (pairs{p,2})]) = ...
                PCCor - blPCCor.AVsync;
            
            % Also save data
            stats.data.([pairs{p,2}, '_ref']) = blPCCor.AVsync;
            stats.data.([pairs{p,2}, '_tar']) = PCCor;
            
            if figInfo.plotOn
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
