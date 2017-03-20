function raceStats = runRace(RTs)
% Race Model

Plot=1;
%Probs
P=0.02:0.02:1;

% A, V data, remove NaNs
X=round(RTs(~isnan(RTs(:,2)),2)*1000)';
Y=round(RTs(~isnan(RTs(:,3)),3)*1000)';
if length(X)<10 || length(Y)<10
    disp('Not running race model for this date range, not enough unisensory trials')
    raceStats = [];
    return
end

% AVs, remove NaNs
Z=round(RTs(~isnan(RTs(:,4)),4)*1000)';

if length(Z)<10
    disp('Not running race model for this date range, not enough multisensory trials')
    raceStats = [];
    return
else
    
end

figure
[Xp, Yp, Zp, Bp] = RaceModel(X,Y,Z,P,Plot);
h=ng;
% Replace Legend
for i=1:length(h)
    switch h(i).Type
        case 'legend'
            h(i).String = ...
                {'G_A(t)', 'G_V(t)', 'G_A_V_s(t)', 'G_A(t)+G_V(t)'};
    end
end

raceStats.vsAVs = [Xp, Yp, Zp, Bp];

% AVas
figure
Z=round(RTs(~isnan(RTs(:,5)),5)*1000)';
[Xp, Yp, Zp, Bp] = RaceModel(X,Y,Z,P,Plot);
h=ng;
% Replace Legend
for i=1:length(h)
    switch h(i).Type
        case 'legend'
            h(i).String = ...
                {'G_A(t)', 'G_V(t)', 'G_A_V_a(t)', 'G_A(t)+G_V(t)'};
    end
end

raceStats.vsAVa = [Xp, Yp, Zp, Bp];
end