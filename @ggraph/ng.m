function handles = ng(template)

if nargin==0
    template = 'Defualt';
end

%% Set defaults
% Figure positions
fPos=[1 1 800 600];

% Axes fonts
aFontSize = 12;
aFontWeight = 'bold';
aTFSM = 1.25; % (TitleFontSizeMultiplier)
% Axes lines
aLineWidth = 1.5;

% Line (eg. as produced by PLOT) lines
lLineWidth = 1.3;

% Bar graph line width
bLineWidth = 1.3;

% Scatter markers
scMarkerSize = 60;

% Legend
lLoc = 'NorthWest';
lFontSize = 11;
lFontWeight = 'bold';

% Grid
gr = 1;

%% Re-set specific settings for template

switch template
    case 'Defualt'
        % Leave as is
    case 'Wide'
        % Change position to make figue wider
        % Otherwise as default
        fPos = [1 1 1200 600];
    case '800'
        fPos = [1 1 800 600];
    case 'Small'
        fPos = [1 1 600 400];
    case '1024'
        fPos = [1 1 1024 768];
        lLineWidth = 2;
        lFontSize = 18;
        aFontSize = 18;
        aFontWeight = 'bold';
    case '1024ThinLines'
        fPos = [1 1 1024 768];
        lLineWidth = 1;
        lFontSize = 13;
        aFontSize = 13;
        aFontWeight = 'bold';
    case 'Big'
        % Change position to make figue wider
        % Otherwise as default
        fPos = [1 1 1200 1200];
    case 'AdapMetric'
        lLoc = 'NorthWest';
        fPos = [1 1 1200 600];
    case 'AdapMetric2'
        lLoc = 'SouthEast';
        fPos = [1 1 1200 600];
    case 'BigScatter'
        fPos = [1 1 1200 1200];
        lLineWidth = 3;
    case 'Huge'
        fPos = [1 1 1800 1800];
    case 'BigPSTH'
        fPos = [1 1 1200 1200];
        lLineWidth=0.9;
        aFontSize = 14;
        gr = 0;
    case 'PosterThin'
        fPos = [1 1 450 1200];
        lLineWidth = 2;
        aLineWidth = 2;
        aFontSize = 16;
    case 'PosterThinCC'
        fPos = [1 1 450 1200];
        lLineWidth = 2;
        aLineWidth = 2;
        aFontSize = 16;
    case 'ScatterCC'
        % Constant scatter colour, set below
        % Also constant scatter marker size
    case 'SingleBox'
        lLineWidth = 3;
    case 'Thin'
        fPos = [1 1 450 800];
        lLineWidth = 2;
        aLineWidth = 2;
    case '...' % Define new templates here
        
end

%% Figure

% Get current figure
f = gcf;
% Find bits in figure
handles = findobj(f);

% Run through these and set properties according to template
for i=1:length(handles)
    switch handles(i).Type
        case 'figure'
            % Set size
            handles(i).Position = fPos;
            
        case 'axes'
            handles(i).TitleFontSizeMultiplier = aTFSM;
            handles(i).FontSize = aFontSize;
            handles(i).LineWidth = aLineWidth;
            handles(i).FontWeight = aFontWeight;
            
            % Grid
            if gr==1
                grid(handles(i), 'On')
            else
                grid(handles(i), 'Off')
            end
            
        case 'line'
            handles(i).LineWidth = lLineWidth;
            
        case 'bar'
            handles(i).LineWidth = bLineWidth;
            % keyboard
        case 'errorbar'
            handles(i).LineWidth = lLineWidth;
            
        case 'scatter'
            % Special case - not set in template. Fills markers.
            switch template
                case {'ScatterCC', 'BigScatter', 'PosterThinCC'}
                otherwise
                    handles(i).SizeData = scMarkerSize;
                    
            end
            handles(i).MarkerFaceColor = handles(i).CData;
            
        case 'legend'
            handles(i).FontSize = lFontSize;
            handles(i).Location = lLoc;
            handles(i).FontWeight = lFontWeight;
            
        case 'text'
            handles(i).FontSize = lFontSize;
    end
end

drawnow