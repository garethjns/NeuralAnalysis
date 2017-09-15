%% Generate default stim
close all

stim1 = TemporalStim('Aud');
stim1.plot('Stim1')


%% Check reproducablility (with .sound removed)

stim1b = stim1;
stim1b.sound = [];
stim2 = TemporalStim(stim1b);
stim2.plot('Stim2')


%% And again (without .sound removed)

stim3 = TemporalStim(stim2);
stim3.plot('Stim3');


%% With specifically set seeds

params.seed = 123;
params.Fs = 2048;
params.eventSeed = 123;
params.seedNoise = 123;
params.MBNSeedNoise = 123;

stim4 = TemporalStim(params);
stim4.plot('Stim4')

stim5 = TemporalStim(params);
stim5.plot('Stim5')


