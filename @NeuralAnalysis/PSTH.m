function [raster, PSTH] = PSTH(eSpikes, params)
% Input should be [time x chan x epoch] and [epoch times]
% Params should contain bin size in ms (.binSize)
% And .fs

if ~isfield(params, 'plotOn')
    plotOn = true;
end



% Make raster for each channel
if plotOn
    rf = figure;
    pf = figure;
end




