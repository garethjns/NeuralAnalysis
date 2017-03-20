function overallSummary(allData, level, fPaths)

home

fnd = [fPaths.fBehavAnalysisFolder, 'Overall summary.txt'];
if exist(fnd, 'file')
    delete(fnd)
end
diary(fnd)

disp('--------Overall--------')
disp(['Total trials: ', num2str(height(allData)), ...
    ' from ', num2str(length(unique(allData.SessionNum))), ' sessions'])
disp(['Non-correction trials: ',  ...
    num2str(sum(allData.CorrectionTrial==0)), ':'])
disp(['NC-Auditory: ', ...
    num2str(sum(allData.CorrectionTrial==0 ...
    & allData.Type==2))]);
disp(['NC-Visual: ', ...
    num2str(sum(allData.CorrectionTrial==0 ...
    & allData.Type==3))]);
disp(['NC-AV sync: ', ...
    num2str(sum(allData.CorrectionTrial==0 ...
    & allData.Type==4))]);
disp(['NC-AV async: ', ...
    num2str(sum(allData.CorrectionTrial==0 ...
    & allData.Type==5))]);
disp(['Overall accuracy: ', ...
    num2str(sum(allData.Correct==1)/length(allData.Correct)*100), ...
    '%:'])
ind = allData.Type==2 & allData.CorrectionTrial==0;
disp(['NC-Auditory: ', ...
    num2str(sum(allData.Correct==1 & ind)/height(allData(ind,:))*100), ...
    '%:'])
ind = allData.Type==3 & allData.CorrectionTrial==0;
disp(['NC-Visual: ', ...
    num2str(sum(allData.Correct==1 & ind)/height(allData(ind,:))*100), ...
    '%:'])
ind = allData.Type==4 & allData.CorrectionTrial==0;
disp(['NC-AV sync: ', ...
    num2str(sum(allData.Correct==1 & ind)/height(allData(ind,:))*100), ...
    '%:'])
ind = allData.Type==5 & allData.CorrectionTrial==0;
disp(['NC-AV async: ', ...
    num2str(sum(allData.Correct==1 & ind)/height(allData(ind,:))*100), ...
    '%:'])

for l= 1:length(level)
    ind=allData.Level==level(l);
    disp(['-------- Level: ', num2str(level(l)), '--------'])
    disp(['Total trials: ', num2str(height(allData(ind,:))), ...
        ' from ', num2str(length(unique(allData.SessionNum(ind,:)))), ...
        ' sessions'])
    disp(['Non-correction trials: ',  ...
        num2str(sum(allData.CorrectionTrial==0 & ind))])
    disp(['Accuracy: ', ...
        num2str(sum(allData.Correct==1 & ind) ...
        /length(allData.Correct(ind))*100), '%'])
end
disp(' ')
disp(' ')

diary('off')

end