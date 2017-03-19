function obj = summary(obj)

%% Descriptive


%% nTrials

og
figure

clc
% Levels
levs = unique(obj.sessions.Level);
% Disguard NaNs
levs = levs(~isnan(levs));
% Inds (may contains NaNs, hence ==1
nInd = obj.sessions.NeuralData==1;
trInd = obj.sessions.Training==1;
gInd = obj.sessions.Good==1;

% Preallocate
totaln = NaN(1,numel(levs)); % All in set
neuraln = NaN(1,numel(levs)); % With nerual data available
ntn = NaN(1,numel(levs)); % Not training
goodn = NaN(1,numel(levs)); % Marked as good (ie pref not NaN)
greatn = NaN(1,numel(levs)); % Good, not training, with nerual data

% Run
for l = 1:length(levs)
    lInd = obj.sessions.Level == levs(l);
    totaln(l) = nansum(obj.sessions.nTrials(lInd));
    neuraln(l) = nansum(obj.sessions.nTrials(lInd & nInd));
    ntn(l) = nansum(obj.sessions.nTrials(lInd & ~trInd));
    goodn(l) = nansum(obj.sessions.nTrials(lInd & gInd));
    greatn(l) = nansum(obj.sessions.nTrials(lInd & gInd & nInd & ~trInd));
    
    disp(['Level: ', num2str(levs(l))]);
    disp(['Total n: ', num2str(totaln(l))]);
    disp(['Neural n: ', num2str(neuraln(l))]);
    disp(['Non-training n: ', num2str(ntn(l))]);
    disp(['Good n: ', num2str(goodn(l))]);
    disp(['Great n: ', num2str(greatn(l))]);
    
    y = [totaln(l), neuraln(l), ntn(l), goodn(l), greatn(l)];
    subplot(numel(levs),1,l)
    bar(y');
    a = gca;
    a.XTickLabel = {'Total', 'Neural', '~Tr', 'Good', 'Great'};
end

title('Number of trials vs level')
ng;

obj.sessionStats.n.Totaln = totaln;
obj.sessionStats.n.Neuraln = neuraln;
obj.sessionStats.n.NonTrn = ntn;
obj.sessionStats.n.Goodn = goodn;
obj.sessionStats.n.Greatn = greatn;


%% nTrials vs date vs time

og
figure
hold on
timen = NaN(1,3);
for t = 1:3 % All, AM, PM
    switch t
        case 1
            tInd = ones(1,height(obj.sessions));
            tInd = tInd==1;
        case 2
            tInd = strcmp(obj.sessions.Time, 'AM');
        case 3
            tInd = strcmp(obj.sessions.Time, 'PM');
    end
    timen(t) = sum(tInd);
    plot(obj.sessions.DateNum(tInd), obj.sessions.nTrials(tInd))
end
a = gca;
% a.XTickLabel = obj.sessions.Date;
xlabel('Date')
ylabel('nTrials')
legend({'Overall', 'AM sessions', 'PM sessions'})
title('Number of trials vs date')
ng;

disp(['Out of ', num2str(timen(1)), ...
    ' sessions ', num2str(timen(2)), ...
    ' were AM and ', num2str(timen(3)), ' were PM.'])


%% Performamce vs date vs time

og
figure
hold on
timen = NaN(1,3);
% Perf for overall (2 or more sessions average)
dn = unique(obj.sessions.DateNum);
dayPerf = NaN(1,numel(dn));
for d = 1:length(dn)
    % For each dateNum (ie. day) get index
    dInd = obj.sessions.DateNum == dn(d);
    % For data available, calculate unweighted mean
    dayPerf(d) = nanmean(obj.sessions.Perf1(dInd));
    % Weighted mean more complicated beacuase would have to check which are
    % which if >2 sessions in a day
end
scatter(dn, dayPerf);

% Perf for AM / PM
for t = 2:3 % AM, PM
    switch t
        case 2
            tInd = strcmp(obj.sessions.Time, 'AM');
        case 3
            tInd = strcmp(obj.sessions.Time, 'PM');
    end
    % Not saved in vector
    scatter(obj.sessions.DateNum(tInd), obj.sessions.Perf1(tInd))
end

a = gca;
a.XTickLabel = obj.sessions.Date;
title('Performance vs date vs time');
xlabel('Date');
ylabel('Overall % correct');
legend({'Overall', 'AM sessions', 'PM sessions'})
ylim([0 100]);
title('Performance vs date')
ng;

disp(['Out of ', num2str(timen(1)), ...
    ' sessions ', num2str(timen(2)), ...
    ' were AM and ', num2str(timen(3)), ' were PM.'])


%% Average level performamce


%% Average performance morning vs afternoon


%% Performamce

figure

ssize = obj.sessions.nTrials;
ssize(obj.sessions.nTrials==0 | isnan(obj.sessions.nTrials))=1;

plot(obj.sessions.SessionNum, obj.sessions.Perf1, 'LineWidth', 2)
hold on
scatter(obj.sessions.SessionNum, obj.sessions.Perf2, ssize/3)
scatter(obj.sessions.SessionNum, obj.sessions.Perf3, ssize/3)
scatter(obj.sessions.SessionNum, obj.sessions.Perf4, ssize/3)
scatter(obj.sessions.SessionNum, obj.sessions.Perf5, ssize/3)

legend({'All trials', 'A trials', 'V trials', 'AVs', 'AVa'})
xlabel('Session Number')
ylabel('Performance %')
title('Performance vs date')
ng('ScatterLine');


