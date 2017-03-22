function PCCor = PCCorrect(allData, trialInd, figInfo)
% Calculate percent correct
% Correct answer histogram
% Plots histogram of all answers.
% Gets % correct summary

% Valid conditions
validConditions = [1, 2, 3, 4, 5];

% Unpackage figInfo
% {rect, colours, validCondTits, validCondTitsComp, validCondTitsAlt, ...
% fName}
rect = figInfo.rect;
tA = figInfo.titleAppend;
colours = figInfo.colours;
validCondTits = figInfo.validCondTits;
validCondTitsComp = figInfo.validCondTitsComp;
validCondTitsAlt = figInfo.validCondTitsAlt;
fName = figInfo.fName;
fns = figInfo.fns;

% Preallocate
PCCor = array2table(NaN(size(validCondTitsComp)));
PCCor.Properties.VariableNames = validCondTitsComp;
pdl = NaN(1,length(validConditions));

figure('OuterPosition', rect);
for v = 1:length(validConditions)
    plotData=[];
    switch v
        case 1
            plotData(:,1) = allData.Correct(trialInd);
            
            pdl(v)=size(plotData,1);
            
            % Graph stuff
            tit = 'All trials';
            limy = [0, 600];
            col = colours(v,:);
            ecol = 'w';
            
        otherwise % Data for current, valid condition
            index = allData.Type==validConditions(v) ...
                & trialInd;
            
            plotData = allData.Correct(index);
            
            % Graph stuff
            tit = validCondTitsComp{v};
            limy = [0, 600];
            col = colours(v,:);
            ecol = 'k';
    end
    
    subplot(1,length(validConditions),v),
    hist(plotData,0:1:1);
    % Set colour of hist
    h = findobj(gca,'Type','patch');
    set(h,'FaceColor', col, 'EdgeColor', ecol)
    title(tit);
    ylabel('n');
    xlim([-1 2]);
    ylim(limy)
    
    % PCcorrect
    PCCor{1,v} = sum(plotData)/length(plotData)*100;
    xlabel([num2str((round(PCCor{1,v}*10))/10), '%']);
    
    clear data2Plot index tit h col ecol limy
end
suptitle([tA, 'Proportion of correct responses'])
Sess.ng;

fn = [fns, 'Prop correct'];
Sess.hgx(fn)

disp('%s correct:')
disp(PCCor);
