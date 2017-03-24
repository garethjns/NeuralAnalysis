function thresh = threshold(allData, trialInd, figInfo)
% Find psychometric threshold


% Unpackage figInfo
rect = figInfo.rect;
tA = figInfo.titleAppend;
colours = figInfo.colours;
validCondTits = figInfo.validCondTits;
validCondTitsComp = figInfo.validCondTitsComp;
validCondTitsAlt = figInfo.validCondTitsAlt;
fName = figInfo.fName;
fns = figInfo.fns;

% Run for each modality and each noise level available...
nls = unique([allData.vNoise(trialInd,1), allData.aNoise(trialInd,1)]);
corPCA = NaN(1,numel(nls));
corPCAn = zeros(1,numel(nls));
corPCV = NaN(1,numel(nls));
corPCVn = zeros(1,numel(nls));
% Run through all noise levels for both mods, although not all nls may be
% used in both mods - leave as NaNs and remove later
for nl = 1:numel(nls)
    for v=2:3
        switch v
            case 2
                ind = trialInd ...
                    & allData.Type == v ...
                    & allData.aNoise == nls(nl);
                corPCA(nl) = sum(allData.Correct(ind,1)) / sum(ind) *100;
                corPCAn(nl) = sum(ind);
                
            case 3
                ind = trialInd ...
                    & allData.Type == v ...
                    & allData.vNoise == nls(nl);
                corPCV(nl) = sum(allData.Correct(ind,1)) / sum(ind) *100;
                corPCVn(nl) = sum(ind);
        end
    end
end

% Remove NaNs from corPCV and corPCA and create x
xA = nls(~isnan(corPCA));
corPCAn = corPCAn(corPCAn>0);
corPCA = corPCA(~isnan(corPCA));
xV = nls(~isnan(corPCV));
corPCVn = corPCVn(corPCVn>0); % Should match with below
corPCV = corPCV(~isnan(corPCV));

[coeffsA, curveA, thresholdA] = ...
    Sess.fitPsycheCurveLogit(xA, corPCA/100.*corPCAn, corPCAn, 0.75); 
[coeffsV, curveV, thresholdV] = ...
    Sess.fitPsycheCurveLogit(xV, corPCV/100.*corPCVn, corPCVn, 0.75); 

% [fit, threshold, stat] = FitPsycheCurve(xA, corPCA/100, 0.75)

disp(tA)
disp(['A thresh: ', num2str(thresholdA), ...
    ', V thresh: ', num2str(thresholdV)])

% Plot
figure
subplot(1,2,1),
scatter(xA, corPCA, corPCAn);
hold on
plot(curveA(:,1), curveA(:,2));
axis([-150, 0, 0 100])
title('Auditory')
xlabel('Noise level')
ylabel('Perf')
subplot(1,2,2),
scatter(xV, corPCV, corPCVn);
hold on
plot(curveV(:,1), curveV(:,2));
axis([-150, 0, 0 100])
title('Visual')
xlabel('Noise level')
ylabel('Perf')
ng OpenScatter

fn = [fns, 'Thresholds'];
% hgexport(gcf, fn, hgexport('factorystyle'), ...
%     'Format', 'png');
Sess.hgx(fn)

% Return
thresh.thresholdA = thresholdA;
thresh.coeffsA = coeffsA;
thresh.thresholdV = thresholdV;
thresh.coeffsV = coeffsV;

