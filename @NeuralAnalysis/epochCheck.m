function [evPerEp, OK, survivedTest] = epochCheck(events, plotOn)
% Applies various tests to number of events per channel/epoch.
% Aims to detect bad channels, and bad epochs.
% Checks:
% 1) Absolute number of events per channel/epoch
% 2) Relative number of events across channels then across epochs.
% 3) If channel is intermittent
% 4) If epochs are intermittent - ie. if a channel becomes intermittent due
% to loss of connection
% 5) Proportion of intermittent channels, too many assume unplugged
% Thresholds hard coded for now
% Implicit assumtion: All channels from one headstage. NOT
% channels from different headstages.

if ~exist('plotOn', 'var')
    plotOn = true;
end

if plotOn
    close all
end

c = size(events, 2);
e = size(events, 3);
leg = string('Chan ') + (1:c)';


evPerEp = nansum(events, 1);
survivedTest = zeros(c, e);


%% Plot input

figure
plot(permute(evPerEp, [3,2,1]))
ylabel('n Spikes')
xlabel('Epoch')
legend(leg)


%% Too many events (absolute)
% Ditch all epochs where average events goes over 4000
% Mean across channels, permute to row vector (of epochs which are 3rd
% D)

OK1 = evPerEp<4000;


% Update index
OK = OK1;
survivedTest(OK) = 1;
pltOK(OK, plotOn, 'Test 1')


%% Too few events (absolute)
% Was this channel just too shit to bother with?
% If very few events/Ep detected
OK2 = evPerEp>10;


% Update index
OK = OK & OK2;
survivedTest(OK) = 2;
pltOK(OK, plotOn, 'Test 2')


%% Too many events (relative across chans)
% Ditch all epochs where average events goes over 4*median
% Med across channels

OK3 = evPerEp < 5*median(evPerEp,2);

% Update index
OK = OK & OK3;
survivedTest(OK) = 3;
pltOK(OK, plotOn, 'Test 3')


%% Too many events (relative across epoch)
% Ditch all epochs where average events goes over 4*median
% Med across epoch

OK4 = evPerEp < 4*median(evPerEp, 3);

% Update index
OK = OK & OK4;
survivedTest(OK) = 4;
pltOK(OK, plotOn, 'Test 4')


%% Intermittent channels - remove channel
% Take sum of OK across epochs. 0 = all 0 or all 1, >0 = some good, some
% bad.
% Remove above some threshold

% Eg less than 70% good
cOK = sum(OK,3)./e > 0.70;

OK5 = repmat(cOK, 1, 1, e);
OK = OK & OK5;
survivedTest(OK) = 5;
pltOK(OK, plotOn, 'Test 5')


%% Intermittent epochs - remove epochs
% Take running average of proportion of good epochs (for each channel)
% If this average drops suddenly, assume channel has become intermittent.
% Remove epochs from this point onwards.

% Permute so epoch is rows, channel cols
pOK =  permute(OK, [3,2,1]);

% Moving std of each channels OKness
mStd = movstd(pOK, 4);

% Does this go over some threshold based on median of channel's overall std
mOK = mStd > median(mStd)*3;

% Permute back and update index
OK6 = permute(~mOK, [3,2,1]);
OK = OK & OK6;
survivedTest(OK) = 6;
pltOK(OK, plotOn, 'Test 6')


%% Does this affect too many channels?
% Ignoring channels where there is no good data at all
% When intermittence occurs, does it occur on enough channels to warrent
% total removal of this side?

% Which channels have data and should be counted in proportion?
% Not those that are all zeros
nEx = sum(all(permute(OK==0, [3,2,1])));
% Actually don't need to do this - use mOK instead, as it's based on std

% Calcualte prop of affected channels
propOK = (sum(~mOK,2) - nEx) ./ (c - nEx);

% Remove entire block where proportion of affected channels is too high
propOK = propOK > 0.5;

% Update index
OK7 = repmat(propOK, 1, c);
OK7 = permute(OK7, [3,2,1]);
OK = OK & OK7;
survivedTest(OK) = 7;
pltOK(OK, plotOn, 'Test 7')


%% Plot survival
% Plot showing test number epoch/channel was dropped at, 7 if still alive.

if plotOn
    figure
    imagesc(survivedTest')
    colorbar
    xlabel('Channel')
    ylabel('Test')
    title('Test survival')
end

end

function pltOK(OK, plotOn, tit)
if plotOn
    figure
    imagesc(permute(OK, [3,2,1]))
    ylabel('Epoch')
    xlabel('Channel')
    colorbar
    title(['Index of OK after ', tit])
end
end