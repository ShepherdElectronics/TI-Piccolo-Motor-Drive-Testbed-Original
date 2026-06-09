function outDir = save_and_plot_debug_radio(outDir)
% Save & plot the currently-selected debug pair (from Debug_signals.Value).
% Uses save_debug_session(debug_1, debug_2) and auto-labels based on
% the radio-button state labels.

% -------------------------------------------------------------------------
% 1) EDIT THIS LIST IF YOU CHANGE THE RADIO BUTTON STATES IN SIMULINK
%    (order must match the "States" list in your Radio Button block)
% -------------------------------------------------------------------------
stateLabels = { ...
    'Mtr1: Speed ref & Speed feedback'          % 1
    'Mtr1: Id ref & Id feedback'                % 2
    'Mtr1: Iq ref & Iq feedback'                % 3
    'Mtr1: Vd & Vq'                             % 4
    'Mtr1: Ia & Ib feedback'                    % 5
    'Mtr1: Pm & Te'                             % 6
    'Mtr2: Id ref & Id feedback'                % 7
    'Mtr2: Iq ref & Iq feedback'                % 8
    'Mtr2: Vd & Vq'                             % 9
    'Mtr2: Pm & Te'                             % 10
    'Mtr1&Mtr2: Pm'                             % 11
    'Mtr1&Mtr2: Pos'                            % 12
    'Mtr1&Mtr2: Ia'                             % 13
    'Mtr1 Speed ref & Mtr2 Speed fb'            % 14
};

% -------------------------------------------------------------------------
% 2) Read the current selection from base workspace
% -------------------------------------------------------------------------
selIdx = 1;  % default if not found

if evalin('base','exist(''Debug_signals'',''var'')')
    ds = evalin('base','Debug_signals');
    if isstruct(ds) && isfield(ds,'Value')
        selIdx = ds.Value;
    else
        selIdx = ds;
    end
elseif evalin('base','exist(''Debug_signals_Value'',''var'')')
    selIdx = evalin('base','Debug_signals_Value');
end

selIdx = max(1, min(numel(stateLabels), round(selIdx)));
pairLabel = stateLabels{selIdx};

% Split pair label into channel names (left & right of '&')
parts = regexp(pairLabel, '&', 'split');
ch1name = strtrim(parts{1});
if numel(parts) >= 2
    ch2name = strtrim(parts{2});
else
    ch2name = 'Channel 2';
end

% Helper to create safe filenames from labels
sanitize = @(s) regexprep(lower(strrep(strtrim(s),' ','_')), '[^a-z0-9_]', '');

% -------------------------------------------------------------------------
% 3) Call your existing saver for debug_1 / debug_2
% -------------------------------------------------------------------------
if nargin < 1
    outDir = [];
end
outDir = save_debug_session({'debug_1','debug_2'}, outDir);

% -------------------------------------------------------------------------
% 4) Pull timeseries and plot them overlapped with labels
% -------------------------------------------------------------------------
ts1 = evalin('base','debug_1');
ts2 = evalin('base','debug_2');

t1 = double(ts1.Time(:));
y1 = double(ts1.Data(:));

t2 = double(ts2.Time(:));
y2 = double(ts2.Data(:));

% Resample if time vectors differ
if ~isequal(t1, t2)
    ts2 = resample(ts2, t1);
    t2  = double(ts2.Time(:));
    y2  = double(ts2.Data(:));
end

figure;
plot(t1, y1, 'LineWidth', 1.2); hold on;
plot(t2, y2, 'LineWidth', 1.2);
grid on;
xlabel('Time (s)');
ylabel('Per-unit value');
title(pairLabel);
legend(ch1name, ch2name, 'Location', 'best');

% Save figure
saveas(gcf, fullfile(outDir, sprintf('debug_pair_%02d_overlay.png', selIdx)));

% -------------------------------------------------------------------------
% 5) Extra CSVs with human-readable names
% -------------------------------------------------------------------------
T1 = table(t1, y1, 'VariableNames', {'time_s','value'});
T2 = table(t2, y2, 'VariableNames', {'time_s','value'});

writetable(T1, fullfile(outDir, [sanitize(ch1name) '.csv']));
writetable(T2, fullfile(outDir, [sanitize(ch2name) '.csv']));

% Append mapping into README so you know which pair this run used
readmePath = fullfile(outDir, 'README.txt');
fid = fopen(readmePath, 'a');  % append
if fid ~= -1
    fprintf(fid, '\nSelected debug pair (radio button): state %d -> %s\n', selIdx, pairLabel);
    fprintf(fid, 'Mapped filenames: %s.csv (debug_1), %s.csv (debug_2)\n', ...
        sanitize(ch1name), sanitize(ch2name));
    fclose(fid);
end

fprintf('Saved debug pair %d: %s\n', selIdx, pairLabel);
end

