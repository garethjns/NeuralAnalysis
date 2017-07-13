% Quickly hgexport/save a figure
% .png or .fig or .svg on file name exports this fomat only
% No extension exports all
function hgx(varargin)

% Check all input arguements given
for ai = 1:length(varargin)
    switch class(varargin{ai})
        case 'matlab.ui.Figure'
            % Save any handles to h
            h = varargin{ai};
        case 'char'
            % Save any string to fnG (filename)
            fnG = varargin{ai};
        case 'string'
            % Save any string to fnG (filename)
            fnG = varargin{ai}.char();
    end
end

% If handle not specified, get current figure
if ~exist('h', 'var')
    figHandles = get(0,'Children');
    h = figHandles(1);
end

disp(fnG)
if strcmp(fnG(end-3:end), '.png')
    % Just .png using hgexport
    disp('hgexport of .png...')
    hgexport(h, fnG, hgexport('factorystyle'), 'Format', 'png');
elseif strcmp(fnG(end-3:end), '.fig') || strcmp(fnG(end-3:end), '.svg')
    % Just .fig/.svg using saveas 
    disp(['saveas of ', fnG(end-3:end), '...' ])
    saveas(h, fnG);
else
    % Assume no extentsion, export .png and .fig
    disp('hgexport of .png...')
    hgexport(h, [fnG, '.png'], hgexport('factorystyle'), 'Format', 'png');
    disp('saveas of .fig...')
    saveas(h, [fnG, '.fig']);
    % saveas(h, [fnG, '.svg']);
end
