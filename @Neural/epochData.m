function epoched = epochData(obj, behav, data, fs)
% Epoch data using times in behav data.
% Pre/post time parameters need to get here from Subject object
% (sub.params.PP)
% Epoched relative to trial start time
%           Variable         Length of stim
%      |~~~~~~~~~~~~~~~~|--------------------|
%   At centre          Stim             Trial start
%   Hold time start                     Hold time ends
%      |~~~~(silence)~~~|(holding during stim|
%        HT-length(stim)     length(stim)

%   Epoch:
%   |----------------------------------------|-----------------|
%   -2 (preTime)                             0             +1(postTime)

% Get times in s and pts
preTime = obj.neuralParams.EpochPreTime;
postTime = obj.neuralParams.EpochPostTime;
prePts = round(preTime*fs);
postPts = round(postTime*fs);
epochPts = abs(prePts) + postPts + 1;

% Get behav times from .StartTrialTime
% And calculate points for this fs
behavTimes = behav.StartTrialTime;
behavTimesPts = round(behavTimes*fs);

% Get the number of epochs and channels
nEpochs = numel(behavTimes);
nChans = size(data, 2);

% Get stat and ends for
epStartIdx = behavTimesPts + prePts; 
epEndIdx = behavTimesPts + postPts; 

% Extract these time indexs across all channels
% time x chan x epoch
epoched = zeros(epochPts, ...
    nChans, ...
    nEpochs, ...
    class(data));
for e = 1:nEpochs
    epoched(:,:,e) = data(epStartIdx:epEndIdx,:);
end
