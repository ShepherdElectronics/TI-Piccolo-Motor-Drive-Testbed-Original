function outDir = save_and_plot_debug_radio(outDir)
% SAVE_AND_PLOT_DEBUG_RADIO
% Always prompts user for debug index (radio button idx)

% -------------------------------------------------------------------------
% USER PROMPT FOR DEBUG INDEX
% -------------------------------------------------------------------------
selIdx = input('Enter debug index (radio button idx): ');

assert(isnumeric(selIdx) && isscalar(selIdx), ...
    'selIdx must be a scalar number.');

% -------------------------------------------------------------------------
% OUTPUT DIRECTORY
% -------------------------------------------------------------------------
if nargin < 1 || isempty(outDir)
    outDir = fullfile(pwd, 'PresentationData', datestr(now,'yyyymmdd_HHMMSS'));
end
if ~exist(outDir,'dir')
    mkdir(outDir);
end

sanitize = @(s) regexprep(lower(strrep(strtrim(s),' ','_')), '[^a-z0-9_]', '');

% -------------------------------------------------------------------------
% RADIO BUTTON STATE MAP (MATCH SIMULINK ORDER)
% -------------------------------------------------------------------------
stateMap = { ...
% idx | pairTitle                         | ch1Label       | ch2Label
  1,   'Mtr1: Speed ref & Speed feedback',  'Mtr1 Speed ref', 'Mtr1 Speed fb'
  2,   'Mtr1: Id ref & Id feedback',        'Mtr1 Id ref',    'Mtr1 Id fb'
  3,   'Mtr1: Iq ref & Iq feedback',        'Mtr1 Iq ref',    'Mtr1 Iq fb'
  4,   'Mtr1: Vd & Vq',                     'Mtr1 Vd',        'Mtr1 Vq'
  5,   'Mtr1: Ia & Ib feedback',            'Mtr1 Ia fb',     'Mtr1 Ib fb'
  6,   'Mtr1: Pm & Te',                     'Mtr1 Pm',        'Mtr1 Te'
  7,   'Mtr2: Id ref & Id feedback',        'Mtr2 Id ref',    'Mtr2 Id fb'
  8,   'Mtr2: Iq ref & Iq feedback',        'Mtr2 Iq ref',    'Mtr2 Iq fb'
  9,   'Mtr2: Vd & Vq',                     'Mtr2 Vd',        'Mtr2 Vq'
 10,   'Mtr2: Ia & Ib feedback',            'Mtr2 Ia fb',     'Mtr2 Ib fb'
 11,   'Mtr2: Pm & Te',                     'Mtr2 Pm',        'Mtr2 Te'
 12,   'Mtr1&Mtr2: Pm',                     'Mtr1 Pm',        'Mtr2 Pm'
 13,   'Mtr1&Mtr2: Te',                     'Mtr1 Te',        'Mtr2 Te'
 14,   'Mtr1&Mtr2: Pos',                    'Mtr1 Pos',       'Mtr2 Pos'
 15,   'Mtr1&Mtr2: Ia',                     'Mtr1 Ia',        'Mtr2 Ia'
 16,   'Mtr1 Speed ref & Mtr2 Speed fb',    'Mtr1 Speed ref', 'Mtr2 Speed fb'
};

nStates = size(stateMap,1);
assert(selIdx >= 1 && selIdx <= nStates, 'selIdx out of range.');

pairLabel = stateMap{selIdx,2};
ch1name   = stateMap{selIdx,3};
ch2name   = stateMap{selIdx,4};

% -------------------------------------------------------------------------
% PULL DEBUG SIGNALS
% -------------------------------------------------------------------------
assert(evalin('base','exist(''debug_1'',''var'')==1'), 'debug_1 missing.');
assert(evalin('base','exist(''debug_2'',''var'')==1'), 'debug_2 missing.');

d1 = evalin('base','debug_1');
d2 = evalin('base','debug_2');

[t1, y1] = toTimeValue(d1);
[t2, y2] = toTimeValue(d2);

if ~isequal(t1,t2)
    y2 = interp1(t2,y2,t1,'linear','extrap');
    t2 = t1;
end

% -------------------------------------------------------------------------
% PLOT
% -------------------------------------------------------------------------
fig = figure('Color','w');
plot(t1,y1,'LineWidth',1.2); hold on;
plot(t2,y2,'LineWidth',1.2);
grid on;
xlabel('Time (s)');
ylabel(bestYLabel(pairLabel));
title(pairLabel,'Interpreter','none');
legend(ch1name,ch2name,'Location','best','Interpreter','none');

exportgraphics(fig, fullfile(outDir, ...
    sprintf('debug_pair_%02d_%s.png',selIdx,sanitize(pairLabel))), ...
    'Resolution',200);

% -------------------------------------------------------------------------
% SAVE DATA
% -------------------------------------------------------------------------
writetable(table(t1,y1,'VariableNames',{'time_s','value'}), ...
    fullfile(outDir,[sanitize(ch1name) '.csv']));
writetable(table(t2,y2,'VariableNames',{'time_s','value'}), ...
    fullfile(outDir,[sanitize(ch2name) '.csv']));

save(fullfile(outDir,sprintf('debug_pair_%02d.mat',selIdx)), ...
    'selIdx','pairLabel','ch1name','ch2name','t1','y1','t2','y2');

fprintf('Saved idx %d → %s\nOutput: %s\n', selIdx, pairLabel, outDir);

end
% ========================= Helper: ylabel inference =========================
function yl = bestYLabel(pairLabel)
l = lower(pairLabel);
yl = 'Value';
if contains(l,'speed')
    yl = 'Speed';
elseif contains(l,'te')
    yl = 'Torque (Te)';
elseif contains(l,'pm')
    yl = 'Mechanical Power (Pm)';
elseif contains(l,'iq') || contains(l,'id') || contains(l,'ia') || contains(l,'ib')
    yl = 'Current';
elseif contains(l,'vd') || contains(l,'vq')
    yl = 'Voltage';
elseif contains(l,'pos')
    yl = 'Position';
end
end

% ========================= Helper: convert signal to [t,y] =========================
function [t, y] = toTimeValue(x)
% Accepts:
% - timeseries / Simulink.Timeseries
% - struct with Time/Data
% - numeric Nx2 [t,y]
% - numeric Nx1 [y] (sample index used as time)

if isa(x,'timeseries') || isa(x,'Simulink.Timeseries')
    t = double(x.Time(:));
    y = double(x.Data(:));
    return;
end

if isstruct(x) && isfield(x,'Time') && isfield(x,'Data')
    t = double(x.Time(:));
    y = double(x.Data(:));
    return;
end

if isnumeric(x)
    if size(x,2) == 2
        t = double(x(:,1));
        y = double(x(:,2));
    else
        y = double(x(:));
        t = (0:numel(y)-1)';   % sample index time
    end
    return;
end

error('Unsupported debug signal type: %s', class(x));
end

