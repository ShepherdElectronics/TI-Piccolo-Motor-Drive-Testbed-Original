function TRIMandPLOT(outDir)
% TRIMandPLOT
% Trims first/last 5 s from debug_1 & debug_2 (timeseries in base workspace),
% plots with minor grids, and saves PNG + trimmed CSVs.

% ================= USER-EDITABLE LABELS =================
plotTitle = 'Speed Feedback (debug\_1) vs Speed Reference (debug\_2)';
legend1   = 'Speed Feedback (debug\_1)';   % debug_1 = feedback
legend2   = 'Speed Reference (debug\_2)';  % debug_2 = reference
trim_s    = 5;                              % seconds to cut off start & end
% ========================================================

if nargin < 1 || isempty(outDir)
    outDir = pwd;
end
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

% ---- Pull timeseries from base workspace ----
if ~evalin('base','exist(''debug_1'',''var'') && exist(''debug_2'',''var'')')
    error('Base workspace must contain timeseries debug_1 and debug_2.');
end

ts1 = evalin('base','debug_1');
ts2 = evalin('base','debug_2');

t1 = double(ts1.Time(:));
y1 = double(ts1.Data(:));

t2 = double(ts2.Time(:));
y2 = double(ts2.Data(:));

% ---- Resample if time vectors differ ----
if ~isequal(t1, t2)
    ts2 = resample(ts2, t1);
    t2  = double(ts2.Time(:));
    y2  = double(ts2.Data(:));
end

% ---- Trim first & last N seconds ----
tStart = t1(1) + trim_s;
tEnd   = t1(end) - trim_s;

if tEnd <= tStart
    warning('Not enough duration to trim %g s from start and end. Plotting full data.', trim_s);
    idx = true(size(t1));
else
    idx = (t1 >= tStart) & (t1 <= tEnd);
end

t = t1(idx);
y1t = y1(idx);
y2t = y2(idx);

% ---- Plot ----
fig = figure;
plot(t, y1t, 'LineWidth', 1.3); hold on;
plot(t, y2t, 'LineWidth', 1.3);

grid on;
grid minor;
ax = gca;
ax.XMinorGrid = 'on';
ax.YMinorGrid = 'on';

xlabel('Time (s)');
ylabel('Per-unit value');
title([plotTitle ' (trimmed)']);
legend(legend1, legend2, 'Location', 'best');

% ---- Save figure ----
pngPath = fullfile(outDir, 'debug_overlay_trimmed.png');
saveas(fig, pngPath);

% ---- Save trimmed CSVs ----
sanitize = @(s) regexprep(lower(strrep(strtrim(s),' ','_')), '[^a-z0-9_]', '');

T1 = table(t, y1t, 'VariableNames', {'time_s','value'});
T2 = table(t, y2t, 'VariableNames', {'time_s','value'});

csv1 = fullfile(outDir, [sanitize(legend1) '_trimmed.csv']);
csv2 = fullfile(outDir, [sanitize(legend2) '_trimmed.csv']);

writetable(T1, csv1);
writetable(T2, csv2);

fprintf('Saved:\n  %s\n  %s\n  %s\n', pngPath, csv1, csv2);
end
