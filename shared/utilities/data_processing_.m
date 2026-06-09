%% data_processing_lab2_motor1_raw_student_FINAL.m
% Lab 2 Motor 1 Raw Student Analysis
%
% Uses only Motor 1 data:
%   trial01 = Mtr1: Speed ref & Speed feedback
%   trial03 = Mtr1: Pm & Te
%   trial05 = Mtr1: Iq ref & Iq feedback
%
% IMPORTANT:
%   This version uses the same raw plotting method as the Lab 1 example.
%   It does NOT align Iq to speed or Pm/Te for the student plots.
%
% Output:
%   Saves PNGs to:
%   C:\CourseDev\DMD\lab2_motor1_raw_student_analysis\pngs
%
% Notes:
%   - Raw data is plotted directly from each trial folder.
%   - Speed error is calculated only from trial01.
%   - Iq range is calculated only from trial05.
%   - Pm/Te range is calculated only from trial03.
%   - High startup Pm spikes are removed only from Pm plot/calcs.

clear; clc; close all;

baseDir = pwd;

%% ================= USER SETTINGS =================

startTimeSec = 0;
endTimeSec   = 30;

speedTrial  = "trial01";   % Mtr1 speed ref & speed feedback
m1MechTrial = "trial03";   % Mtr1 Pm & Te
m1IqTrial   = "trial05";   % Mtr1 Iq ref & Iq feedback

outDir = fullfile(baseDir, 'lab2_motor1_raw_student_analysis');
pngDir = fullfile(outDir, 'pngs');

if ~exist(outDir, 'dir')
    mkdir(outDir);
end

if ~exist(pngDir, 'dir')
    mkdir(pngDir);
end

%% ================= PLOT STYLE =================

fontName = 'Arial';
fontSize = 11;
lineW    = 1.35;

%% ================= DISPLAY / SANITY LIMITS =================

maxAbsRPM = 7000;
maxAbsIq  = 20;
maxAbsPm  = 2000;
maxAbsTe  = 1.0;

% Remove only obvious high startup Pm spikes from Pm plot/calcs.
pmStartupSpikeLimit_W = 200;

regenIqThreshold = -0.05;

%% ================= LOAD RAW SIGNALS =================

% trial01: Motor 1 speed reference and feedback
[tM1RefRaw, m1RefRaw] = readTrialSignal(baseDir, speedTrial, 'debug_1');
[tM1RpmRaw, m1RpmRaw] = readTrialSignal(baseDir, speedTrial, 'debug_2');

% trial05: Motor 1 Iq reference and feedback
[tIqRefRaw, iqRefRaw] = readTrialSignal(baseDir, m1IqTrial, 'debug_1');
[tIqFbRaw,  iqFbRaw]  = readTrialSignal(baseDir, m1IqTrial, 'debug_2');

% trial03: Motor 1 Pm and Te, channel order auto-detected
[tM1Ch1Raw, m1Ch1Raw] = readTrialSignal(baseDir, m1MechTrial, 'debug_1');
[tM1Ch2Raw, m1Ch2Raw] = readTrialSignal(baseDir, m1MechTrial, 'debug_2');

[tM1PmRaw, m1PmRaw, tM1TeRaw, m1TeRaw, m1Assignment] = autoAssignPmTe( ...
    tM1Ch1Raw, m1Ch1Raw, ...
    tM1Ch2Raw, m1Ch2Raw, ...
    "Motor 1");

fprintf('\nMechanical channel assignment:\n');
fprintf('  %s\n', m1Assignment);

fprintf('\nRaw channel ranges before crop:\n');
printRange('Speed ref', m1RefRaw);
printRange('Speed fb',  m1RpmRaw);
printRange('Iq ref',    iqRefRaw);
printRange('Iq fb',     iqFbRaw);
printRange('M1 debug_1', m1Ch1Raw);
printRange('M1 debug_2', m1Ch2Raw);

%% ================= CROP EACH TRIAL IN ITS OWN TIME BASE =================

[tM1Ref, m1Ref] = cropByTime(tM1RefRaw, m1RefRaw, startTimeSec, endTimeSec);
[tM1Rpm, m1Rpm] = cropByTime(tM1RpmRaw, m1RpmRaw, startTimeSec, endTimeSec);

[tIqRef, iqRef] = cropByTime(tIqRefRaw, iqRefRaw, startTimeSec, endTimeSec);
[tIqFb,  iqFb]  = cropByTime(tIqFbRaw,  iqFbRaw,  startTimeSec, endTimeSec);

[tM1Pm, m1Pm] = cropByTime(tM1PmRaw, m1PmRaw, startTimeSec, endTimeSec);
[tM1Te, m1Te] = cropByTime(tM1TeRaw, m1TeRaw, startTimeSec, endTimeSec);

%% ================= REMOVE ONLY IMPOSSIBLE VALUES PER TRIAL =================

validSpeedRef = isfinite(tM1Ref) & isfinite(m1Ref) & abs(m1Ref) <= maxAbsRPM;
validSpeedFb  = isfinite(tM1Rpm) & isfinite(m1Rpm) & abs(m1Rpm) <= maxAbsRPM;

tM1Ref = tM1Ref(validSpeedRef);
m1Ref  = m1Ref(validSpeedRef);

tM1Rpm = tM1Rpm(validSpeedFb);
m1Rpm  = m1Rpm(validSpeedFb);

validIqRef = isfinite(tIqRef) & isfinite(iqRef) & abs(iqRef) <= maxAbsIq;
validIqFb  = isfinite(tIqFb)  & isfinite(iqFb)  & abs(iqFb)  <= maxAbsIq;

tIqRef = tIqRef(validIqRef);
iqRef  = iqRef(validIqRef);

tIqFb = tIqFb(validIqFb);
iqFb  = iqFb(validIqFb);

validPm = isfinite(tM1Pm) & isfinite(m1Pm) & abs(m1Pm) <= maxAbsPm;
validTe = isfinite(tM1Te) & isfinite(m1Te) & abs(m1Te) <= maxAbsTe;

tM1Pm = tM1Pm(validPm);
m1Pm  = m1Pm(validPm);

tM1Te = tM1Te(validTe);
m1Te  = m1Te(validTe);

%% ================= REMOVE HIGH STARTUP PM SPIKES ONLY =================

m1PmPlot = m1Pm;

pmSpikeMask = abs(m1PmPlot) > pmStartupSpikeLimit_W;
m1PmPlot(pmSpikeMask) = NaN;

fprintf('\nAfter crop:\n');
printRange('Speed ref', m1Ref);
printRange('Speed fb',  m1Rpm);
printRange('Iq ref',    iqRef);
printRange('Iq fb',     iqFb);
printRange('M1 Pm plot', m1PmPlot);
printRange('M1 Te',      m1Te);

fprintf('\nRemoved high Motor 1 Pm startup/spike samples from Pm plot/calcs: %d\n', nnz(pmSpikeMask));

%% ================= RAW CALCS, EACH TRIAL SEPARATELY =================

% Speed error from speed trial only
tSpeedCommon = tM1Rpm;
m1RefOnSpeedTime = interpKeepNaN(tM1Ref, m1Ref, tSpeedCommon);

speedValid = isfinite(tSpeedCommon) & isfinite(m1RefOnSpeedTime) & isfinite(m1Rpm);

tSpeedCalc = tSpeedCommon(speedValid);
m1RefCalc  = m1RefOnSpeedTime(speedValid);
m1RpmCalc  = m1Rpm(speedValid);

rpmErr = m1RpmCalc - m1RefCalc;
absRpmErr = abs(rpmErr);

meanAbsRpmError = mean(absRpmErr, 'omitnan');
maxAbsRpmError  = max(absRpmErr, [], 'omitnan');

% Iq summary from Iq feedback trial only
iqMin = min(iqFb, [], 'omitnan');
iqMax = max(iqFb, [], 'omitnan');

regenMask = iqFb < regenIqThreshold;
pctNegativeIq = 100 * nnz(regenMask) / max(numel(iqFb), 1);

% Mechanical summary from Pm/Te trial only
m1PmMin = min(m1PmPlot, [], 'omitnan');
m1PmMax = max(m1PmPlot, [], 'omitnan');

m1TeMin = min(m1Te, [], 'omitnan');
m1TeMax = max(m1Te, [], 'omitnan');

%% ============================================================
%  FIGURE 1: RAW SPEED TRACKING
% ============================================================

fig = figure('Color','w','Name','Figure 1 - Motor 1 Raw Speed Tracking');
set(fig, 'Position', [100 100 1000 520]);

plot(tM1Ref, m1Ref, 'k--', 'LineWidth', lineW); hold on;
plot(tM1Rpm, m1Rpm, 'b', 'LineWidth', lineW);

grid on; grid minor;
formatAxes(gca, fontName, fontSize);

xlabel('Time (s)');
ylabel('Speed (RPM)');
title('Motor 1 EPA-Style Speed Tracking');
legend('Speed reference','Motor 1 speed feedback','Location','best');

xlim([startTimeSec endTimeSec]);

exportgraphics(fig, fullfile(pngDir, 'figure1_motor1_raw_speed_tracking.png'), 'Resolution', 300);

%% ============================================================
%  FIGURE 2: RAW SPEED ERROR
% ============================================================

fig = figure('Color','w','Name','Figure 2 - Motor 1 Raw Speed Error');
set(fig, 'Position', [120 120 1000 430]);

plot(tSpeedCalc, rpmErr, 'r', 'LineWidth', lineW);
yline(0, 'k-', 'LineWidth', 0.8);

grid on; grid minor;
formatAxes(gca, fontName, fontSize);

xlabel('Time (s)');
ylabel('Speed error (RPM)');
title('Motor 1 Speed Tracking Error');

xlim([startTimeSec endTimeSec]);

exportgraphics(fig, fullfile(pngDir, 'figure2_motor1_raw_speed_error.png'), 'Resolution', 300);

%% ============================================================
%  FIGURE 3: RAW IQ
% ============================================================

fig = figure('Color','w','Name','Figure 3 - Motor 1 Raw Iq');
set(fig, 'Position', [140 140 1000 500]);

plot(tIqRef, iqRef, 'k--', 'LineWidth', lineW); hold on;
plot(tIqFb, iqFb, 'r', 'LineWidth', lineW);
yline(0, 'k-', 'LineWidth', 0.8);

if any(regenMask)
    scatter(tIqFb(regenMask), iqFb(regenMask), 20, 'filled');
end

grid on; grid minor;
formatAxes(gca, fontName, fontSize);

xlabel('Time (s)');
ylabel('Iq (A)');
title('Motor 1 Iq Feedback During Drive Cycle');
legend('Iq reference','Iq feedback','Zero line','Negative Iq samples','Location','best');

xlim([startTimeSec endTimeSec]);

exportgraphics(fig, fullfile(pngDir, 'figure3_motor1_raw_iq_feedback.png'), 'Resolution', 300);

%% ============================================================
%  FIGURE 4: RAW MOTOR 1 MECHANICAL
% ============================================================

fig = figure('Color','w','Name','Figure 4 - Motor 1 Raw Mechanical');
set(fig, 'Position', [160 160 1000 640]);

tiledlayout(2,1, 'TileSpacing','compact', 'Padding','compact');

nexttile;
plot(tM1Pm, m1PmPlot, 'b', 'LineWidth', lineW);
yline(0, 'k-', 'LineWidth', 0.8);

grid on; grid minor;
formatAxes(gca, fontName, fontSize);

ylabel('Power (W)');
title('Motor 1 Mechanical Power');
legend('Motor 1 Pm, startup spikes removed','Zero line','Location','best');

xlim([startTimeSec endTimeSec]);

nexttile;
plot(tM1Te, m1Te, 'm', 'LineWidth', lineW);
yline(0, 'k-', 'LineWidth', 0.8);

grid on; grid minor;
formatAxes(gca, fontName, fontSize);

xlabel('Time (s)');
ylabel('Torque (N*m)');
title('Motor 1 Torque');
legend('Motor 1 Te','Zero line','Location','best');

xlim([startTimeSec endTimeSec]);

exportgraphics(fig, fullfile(pngDir, 'figure4_motor1_raw_mechanical.png'), 'Resolution', 300);

%% ============================================================
%  FIGURE 5: RAW MOTOR 1 DRIVE-CYCLE SUMMARY
% ============================================================

fig = figure('Color','w','Name','Figure 5 - Motor 1 Raw Drive Cycle Summary');
set(fig, 'Position', [180 180 1050 760]);

tiledlayout(4,1, 'TileSpacing','compact', 'Padding','compact');

nexttile;
plot(tM1Ref, m1Ref, 'k--', 'LineWidth', lineW); hold on;
plot(tM1Rpm, m1Rpm, 'b', 'LineWidth', lineW);
grid on; grid minor;
formatAxes(gca, fontName, fontSize);
ylabel('RPM');
title('Speed Tracking');
legend('Ref','Feedback','Location','best');
xlim([startTimeSec endTimeSec]);

nexttile;
plot(tIqFb, iqFb, 'r', 'LineWidth', lineW);
yline(0, 'k-', 'LineWidth', 0.8);
grid on; grid minor;
formatAxes(gca, fontName, fontSize);
ylabel('Iq (A)');
title('Motor 1 Iq Feedback');
xlim([startTimeSec endTimeSec]);

nexttile;
plot(tM1Pm, m1PmPlot, 'b', 'LineWidth', lineW);
yline(0, 'k-', 'LineWidth', 0.8);
grid on; grid minor;
formatAxes(gca, fontName, fontSize);
ylabel('Pm (W)');
title('Motor 1 Mechanical Power');
xlim([startTimeSec endTimeSec]);

nexttile;
plot(tM1Te, m1Te, 'm', 'LineWidth', lineW);
yline(0, 'k-', 'LineWidth', 0.8);
grid on; grid minor;
formatAxes(gca, fontName, fontSize);
xlabel('Time (s)');
ylabel('Te (N*m)');
title('Motor 1 Torque');
xlim([startTimeSec endTimeSec]);

exportgraphics(fig, fullfile(pngDir, 'figure5_motor1_raw_drive_cycle_summary.png'), 'Resolution', 300);

%% ============================================================
%  FIGURE 6: STUDENT SUMMARY
% ============================================================

fig = figure('Color','w','Name','Figure 6 - Motor 1 Student Summary');
set(fig, 'Position', [200 200 900 520]);

axis off;

summaryText = {
    'Lab 2 Motor 1 EPA-Style Drive-Cycle Summary'
    ''
    sprintf('Time window analyzed: %.1f to %.1f s', startTimeSec, endTimeSec)
    sprintf('Speed samples used: %d', numel(tSpeedCalc))
    sprintf('Iq feedback samples used: %d', numel(iqFb))
    sprintf('Pm/Te samples used: %d / %d', numel(m1PmPlot), numel(m1Te))
    sprintf('High startup Pm samples removed from Pm plot/calcs: %d', nnz(pmSpikeMask))
    sprintf('Mean absolute speed error: %.1f RPM', meanAbsRpmError)
    sprintf('Maximum absolute speed error: %.1f RPM', maxAbsRpmError)
    sprintf('Iq feedback range: %.3f to %.3f A', iqMin, iqMax)
    sprintf('Mechanical power range: %.1f to %.1f W', m1PmMin, m1PmMax)
    sprintf('Torque range: %.4f to %.4f N*m', m1TeMin, m1TeMax)
    sprintf('Negative Iq samples: %.1f %% of Iq feedback samples', pctNegativeIq)
    ''
    'Notes'
    '• This analysis uses Motor 1 only.'
    '• Motor 2 data is omitted because it is too rough for the student plot set.'
    '• Raw traces are plotted on their own trial time bases.'
    '• High startup Pm spikes are removed only from the Pm plot and Pm summary range.'
    };

text(0.05, 0.94, summaryText, ...
    'FontName', fontName, ...
    'FontSize', fontSize + 1, ...
    'VerticalAlignment', 'top');

exportgraphics(fig, fullfile(pngDir, 'figure6_motor1_student_summary.png'), 'Resolution', 300);

%% ================= SAVE SUMMARY =================

Summary = table( ...
    numel(tSpeedCalc), ...
    numel(iqFb), ...
    numel(m1PmPlot), ...
    numel(m1Te), ...
    nnz(pmSpikeMask), ...
    meanAbsRpmError, ...
    maxAbsRpmError, ...
    iqMin, iqMax, ...
    m1PmMin, m1PmMax, ...
    m1TeMin, m1TeMax, ...
    pctNegativeIq);

writetable(Summary, fullfile(outDir, 'lab2_motor1_raw_student_summary.csv'));

save(fullfile(outDir, 'lab2_motor1_raw_student_analysis_data.mat'), ...
    'tM1Ref', 'm1Ref', ...
    'tM1Rpm', 'm1Rpm', ...
    'tIqRef', 'iqRef', ...
    'tIqFb', 'iqFb', ...
    'tM1Pm', 'm1Pm', 'm1PmPlot', ...
    'tM1Te', 'm1Te', ...
    'tSpeedCalc', 'm1RefCalc', 'm1RpmCalc', ...
    'rpmErr', 'absRpmErr', ...
    'regenMask', 'pmSpikeMask', ...
    'm1Assignment', ...
    'meanAbsRpmError', 'maxAbsRpmError', ...
    'iqMin', 'iqMax', ...
    'm1PmMin', 'm1PmMax', ...
    'm1TeMin', 'm1TeMax', ...
    'pctNegativeIq');

fprintf('\nDone. Motor 1 raw Lab 2 student analysis saved to:\n%s\n', outDir);
fprintf('\nPNGs saved to:\n%s\n', pngDir);
fprintf('\nMechanical channel assignment:\n');
fprintf('  %s\n', m1Assignment);
fprintf('\nSpeed samples used: %d\n', numel(tSpeedCalc));
fprintf('Iq feedback samples used: %d\n', numel(iqFb));
fprintf('Pm samples used: %d\n', numel(m1PmPlot));
fprintf('Te samples used: %d\n', numel(m1Te));
fprintf('High startup Pm samples removed from Pm plot/calcs: %d\n', nnz(pmSpikeMask));

%% ================= HELPERS =================

function [t, y] = readTrialSignal(baseDir, trialName, baseName)
    filePath = fullfile(baseDir, trialName, [baseName '.csv']);
    [t, y] = readSingleSignalCsv(filePath);
end

function [tOut, yOut] = cropByTime(t, y, tStart, tEnd)
    if isempty(t) || isempty(y)
        tOut = [];
        yOut = [];
        return;
    end

    if isinf(tEnd)
        mask = isfinite(t) & isfinite(y) & t >= tStart;
    else
        mask = isfinite(t) & isfinite(y) & t >= tStart & t <= tEnd;
    end

    tOut = t(mask);
    yOut = y(mask);
end

function [t, y] = readSingleSignalCsv(filePath)
    t = [];
    y = [];

    if ~exist(filePath, 'file')
        warning('Missing file: %s', filePath);
        return;
    end

    T = readtable(filePath, 'VariableNamingRule', 'preserve');

    if isempty(T) || height(T) == 0
        warning('Empty file: %s', filePath);
        return;
    end

    isNum = varfun(@isnumeric, T, 'OutputFormat', 'uniform');
    Tn = T(:, isNum);

    if width(Tn) == 0
        warning('No numeric columns found in file: %s', filePath);
        return;
    end

    names = Tn.Properties.VariableNames;
    lowerNames = lower(names);

    timeIdx = find(contains(lowerNames,'time') | ...
                   strcmpi(names,'t') | ...
                   strcmpi(names,'time_s') | ...
                   strcmpi(names,'sec') | ...
                   strcmpi(names,'seconds'), 1, 'first');

    if isempty(timeIdx)
        t = (1:height(Tn)).';
        sigCols = 1:width(Tn);
    else
        t = Tn{:, timeIdx};
        sigCols = setdiff(1:width(Tn), timeIdx, 'stable');
    end

    if isempty(sigCols)
        warning('No signal column found in file: %s', filePath);
        return;
    end

    y = Tn{:, sigCols(1)};

    t = t(:);
    y = y(:);

    mask = isfinite(t) & isfinite(y);
    t = t(mask);
    y = y(mask);
end

function yq = interpKeepNaN(t, y, tq)
    good = isfinite(t) & isfinite(y);
    yq = nan(size(tq));

    if nnz(good) < 2
        return;
    end

    yq = interp1(t(good), y(good), tq, 'linear', NaN);
end

function v = safeFirst(x)
    if isempty(x)
        v = -inf;
    else
        v = x(1);
    end
end

function v = safeLast(x)
    if isempty(x)
        v = inf;
    else
        v = x(end);
    end
end

function formatAxes(ax, fontName, fontSize)
    ax.FontName = fontName;
    ax.FontSize = fontSize;
    ax.LineWidth = 0.9;
    ax.Box = 'on';
    ax.GridAlpha = 0.18;
    ax.MinorGridAlpha = 0.08;
    ax.XMinorGrid = 'on';
    ax.YMinorGrid = 'on';
end

function [tPm, pm, tTe, te, assignmentText] = autoAssignPmTe(t1, y1, t2, y2, motorName)

    y1Finite = y1(isfinite(y1));
    y2Finite = y2(isfinite(y2));

    if isempty(y1Finite)
        range1 = 0;
        medAbs1 = 0;
    else
        range1 = max(y1Finite) - min(y1Finite);
        medAbs1 = median(abs(y1Finite), 'omitnan');
    end

    if isempty(y2Finite)
        range2 = 0;
        medAbs2 = 0;
    else
        range2 = max(y2Finite) - min(y2Finite);
        medAbs2 = median(abs(y2Finite), 'omitnan');
    end

    score1 = max(range1, medAbs1);
    score2 = max(range2, medAbs2);

    if score1 >= score2
        tPm = t1;
        pm  = y1;
        tTe = t2;
        te  = y2;
        assignmentText = sprintf('%s Pm = debug_1, Te = debug_2', motorName);
    else
        tPm = t2;
        pm  = y2;
        tTe = t1;
        te  = y1;
        assignmentText = sprintf('%s Pm = debug_2, Te = debug_1', motorName);
    end
end

function printRange(labelText, y)
    y = y(isfinite(y));

    if isempty(y)
        fprintf('  %s range: empty\n', labelText);
    else
        fprintf('  %s range: %.4f to %.4f\n', labelText, min(y), max(y));
    end
end