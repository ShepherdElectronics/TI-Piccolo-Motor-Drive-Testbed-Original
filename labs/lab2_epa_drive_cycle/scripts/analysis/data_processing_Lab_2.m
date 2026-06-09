%% data_processing_lab2_demo.m
% Lab 2 EPA-style drive-cycle dyno demo analysis
%
% Minimum demo trial set:
%   trial01 = Mtr1: Speed ref & Speed feedback
%   trial03 = Mtr1: Pm & Te
%   trial04 = Mtr2: Pm & Te
%   trial05 = Mtr1: Iq ref & Iq feedback
%   trial07 = Mtr1 Speed ref & Mtr2 Speed fb
%
% Notes:
%   - Motor 2 speed feedback is not yet trusted/functionally validated.
%   - trial07 is included only as a mechanical-coupling diagnostic.
%   - Motor 2 Vd/Vq and electrical power are not used.
%   - Motor 1 Iq feedback is used as the main load/regen sign indicator.
%   - Only 30 seconds of data are used.

clear; clc; close all;

baseDir = pwd;

%% ================= USER SETTINGS =================

startTimeSec = 0;
endTimeSec   = 30;

speedTrial      = "trial01";   % Mtr1 Speed ref & Speed feedback
mtr1PmTeTrial   = "trial03";   % Mtr1 Pm & Te
mtr2PmTeTrial   = "trial04";   % Mtr2 Pm & Te
mtr1IqTrial     = "trial05";   % Mtr1 Iq ref & Iq feedback
couplingTrial   = "trial07";   % Mtr1 Speed ref & Mtr2 Speed fb

outDir = fullfile(baseDir, 'lab2_epa_demo_analysis');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

%% ================= SANITY LIMITS =================

maxAbsRPM = 6000;
maxAbsIq  = 10;
maxAbsTe  = 0.40;
maxAbsPm  = 1000;

% Demo thresholds
minMovingRPM = 100;
minAbsPm     = 1.0;
minAbsTe     = 0.005;
minAbsIq     = 0.05;

% Sign convention note:
% The sign of Iq depends on the model convention.
% For this demo, negative Iq is treated as regen/loading direction if present.
regenIqThreshold = -0.05;

%% ================= LOAD RAW SIGNALS =================

% trial01: Motor 1 speed reference and feedback
[tM1RpmRefRaw, m1RpmRefRaw] = readTrialSignal(baseDir, speedTrial, 'debug_1');
[tM1RpmRaw,    m1RpmRaw]    = readTrialSignal(baseDir, speedTrial, 'debug_2');

% trial03: Motor 1 mechanical power and torque
[tM1PmRaw, m1PmRaw] = readTrialSignal(baseDir, mtr1PmTeTrial, 'debug_1');
[tM1TeRaw, m1TeRaw] = readTrialSignal(baseDir, mtr1PmTeTrial, 'debug_2');

% trial04: Motor 2 mechanical power and torque
[tM2PmRaw, m2PmRaw] = readTrialSignal(baseDir, mtr2PmTeTrial, 'debug_1');
[tM2TeRaw, m2TeRaw] = readTrialSignal(baseDir, mtr2PmTeTrial, 'debug_2');

% trial05: Motor 1 Iq reference and feedback
[tM1IqRefRaw, m1IqRefRaw] = readTrialSignal(baseDir, mtr1IqTrial, 'debug_1');
[tM1IqRaw,    m1IqRaw]    = readTrialSignal(baseDir, mtr1IqTrial, 'debug_2');

% trial07: Motor 1 speed reference and Motor 2 speed feedback
[tCoupleRefRaw, m1RpmRefCoupleRaw] = readTrialSignal(baseDir, couplingTrial, 'debug_1');
[tM2RpmRaw,     m2RpmRaw]          = readTrialSignal(baseDir, couplingTrial, 'debug_2');

%% ================= RAW PLOT =================

fig = figure('Color','w','Name','Lab 2 Raw Data Overview');
tiledlayout(5,1);

nexttile;
plot(tM1RpmRefRaw, m1RpmRefRaw, 'k--', 'LineWidth', 1.0); hold on;
plot(tM1RpmRaw,    m1RpmRaw,    'b',   'LineWidth', 1.0);
grid on;
ylabel('RPM');
title('RAW: Motor 1 Speed Reference vs Feedback');
legend('Mtr1 RPM ref','Mtr1 RPM fb','Location','best');

nexttile;
plot(tM1IqRefRaw, m1IqRefRaw, 'k--', 'LineWidth', 1.0); hold on;
plot(tM1IqRaw,    m1IqRaw,    'r',   'LineWidth', 1.0);
grid on;
ylabel('Iq (A)');
title('RAW: Motor 1 Iq Reference vs Feedback');
legend('Mtr1 Iq ref','Mtr1 Iq fb','Location','best');

nexttile;
plot(tM1PmRaw, m1PmRaw, 'c', 'LineWidth', 1.0); hold on;
plot(tM1TeRaw, m1TeRaw, 'm', 'LineWidth', 1.0);
grid on;
ylabel('M1 Pm / Te');
title('RAW: Motor 1 Mechanical Power and Torque');
legend('Mtr1 Pm','Mtr1 Te','Location','best');

nexttile;
plot(tM2PmRaw, m2PmRaw, 'c', 'LineWidth', 1.0); hold on;
plot(tM2TeRaw, m2TeRaw, 'm', 'LineWidth', 1.0);
grid on;
ylabel('M2 Pm / Te');
title('RAW: Motor 2 Mechanical Power and Torque');
legend('Mtr2 Pm','Mtr2 Te','Location','best');

nexttile;
plot(tCoupleRefRaw, m1RpmRefCoupleRaw, 'k--', 'LineWidth', 1.0); hold on;
plot(tM2RpmRaw,     m2RpmRaw,          'g',   'LineWidth', 1.0);
grid on;
xlabel('Time (s)');
ylabel('RPM');
title('RAW: Mechanical Coupling Check, Mtr1 Speed Ref vs Mtr2 Speed Feedback');
legend('Mtr1 RPM ref','Mtr2 RPM fb, not yet trusted','Location','best');

exportgraphics(fig, fullfile(outDir, 'step0_raw_lab2_overview.png'), 'Resolution', 240);

%% ================= CROP =================

[tM1RpmRef, m1RpmRef] = cropByTime(tM1RpmRefRaw, m1RpmRefRaw, startTimeSec, endTimeSec);
[tM1Rpm,    m1Rpm]    = cropByTime(tM1RpmRaw,    m1RpmRaw,    startTimeSec, endTimeSec);

[tM1Pm, m1Pm] = cropByTime(tM1PmRaw, m1PmRaw, startTimeSec, endTimeSec);
[tM1Te, m1Te] = cropByTime(tM1TeRaw, m1TeRaw, startTimeSec, endTimeSec);

[tM2Pm, m2Pm] = cropByTime(tM2PmRaw, m2PmRaw, startTimeSec, endTimeSec);
[tM2Te, m2Te] = cropByTime(tM2TeRaw, m2TeRaw, startTimeSec, endTimeSec);

[tM1IqRef, m1IqRef] = cropByTime(tM1IqRefRaw, m1IqRefRaw, startTimeSec, endTimeSec);
[tM1Iq,    m1Iq]    = cropByTime(tM1IqRaw,    m1IqRaw,    startTimeSec, endTimeSec);

[tCoupleRef, m1RpmRefCouple] = cropByTime(tCoupleRefRaw, m1RpmRefCoupleRaw, startTimeSec, endTimeSec);
[tM2Rpm,     m2Rpm]          = cropByTime(tM2RpmRaw,     m2RpmRaw,          startTimeSec, endTimeSec);

%% ================= ALIGN TO COMMON TIME BASE =================

allTimes = {tM1Rpm, tM1Iq, tM1Pm, tM1Te, tM2Pm, tM2Te};
tStart = max(cellfun(@safeFirst, allTimes));
tEnd   = min(cellfun(@safeLast,  allTimes));

if tEnd <= tStart
    error('No overlapping time region across selected Lab 2 trials.');
end

lengths = cellfun(@numel, allTimes);
[~, idxDense] = max(lengths);
tBase = allTimes{idxDense};

tCommon = tBase(tBase >= tStart & tBase <= tEnd);

m1RpmRefA = interpKeepNaN(tM1RpmRef, m1RpmRef, tCommon);
m1RpmA    = interpKeepNaN(tM1Rpm,    m1Rpm,    tCommon);

m1IqRefA = interpKeepNaN(tM1IqRef, m1IqRef, tCommon);
m1IqA    = interpKeepNaN(tM1Iq,    m1Iq,    tCommon);

m1PmA = interpKeepNaN(tM1Pm, m1Pm, tCommon);
m1TeA = interpKeepNaN(tM1Te, m1Te, tCommon);

m2PmA = interpKeepNaN(tM2Pm, m2Pm, tCommon);
m2TeA = interpKeepNaN(tM2Te, m2Te, tCommon);

% Coupling trial is kept on its own aligned base because Motor 2 speed is not trusted.
tCoupleStart = max([safeFirst(tCoupleRef), safeFirst(tM2Rpm)]);
tCoupleEnd   = min([safeLast(tCoupleRef),  safeLast(tM2Rpm)]);

if tCoupleEnd > tCoupleStart
    tCoupleCommon = tM2Rpm(tM2Rpm >= tCoupleStart & tM2Rpm <= tCoupleEnd);
    m1RpmRefCoupleA = interpKeepNaN(tCoupleRef, m1RpmRefCouple, tCoupleCommon);
    m2RpmA          = interpKeepNaN(tM2Rpm,     m2Rpm,          tCoupleCommon);
else
    tCoupleCommon = [];
    m1RpmRefCoupleA = [];
    m2RpmA = [];
end

%% ================= BASIC SANITY FILTER =================

validBasic = isfinite(m1RpmRefA) & isfinite(m1RpmA) & ...
             isfinite(m1IqA)    & isfinite(m1PmA) & isfinite(m1TeA) & ...
             isfinite(m2PmA)    & isfinite(m2TeA) & ...
             abs(m1RpmA) <= maxAbsRPM & ...
             abs(m1IqA)  <= maxAbsIq  & ...
             abs(m1PmA)  <= maxAbsPm  & ...
             abs(m2PmA)  <= maxAbsPm  & ...
             abs(m1TeA)  <= maxAbsTe  & ...
             abs(m2TeA)  <= maxAbsTe;

tCommon   = tCommon(validBasic);
m1RpmRefA = m1RpmRefA(validBasic);
m1RpmA    = m1RpmA(validBasic);
m1IqRefA  = m1IqRefA(validBasic);
m1IqA     = m1IqA(validBasic);
m1PmA     = m1PmA(validBasic);
m1TeA     = m1TeA(validBasic);
m2PmA     = m2PmA(validBasic);
m2TeA     = m2TeA(validBasic);

%% ================= LAB 2 METRICS =================

rpmError = m1RpmA - m1RpmRefA;
absRpmError = abs(rpmError);

movingMask = abs(m1RpmRefA) > minMovingRPM | abs(m1RpmA) > minMovingRPM;

motoringMask = movingMask & m1IqA > minAbsIq;
regenMask    = movingMask & m1IqA < regenIqThreshold;

m1PositivePowerMask = movingMask & m1PmA > minAbsPm;
m1NegativePowerMask = movingMask & m1PmA < -minAbsPm;

m2PositivePowerMask = movingMask & m2PmA > minAbsPm;
m2NegativePowerMask = movingMask & m2PmA < -minAbsPm;

% Simple mechanical power balance proxy.
% This is not an efficiency calculation. It is just a coupling/load behavior check.
sumPm = m1PmA + m2PmA;

%% ================= PLOT 1: SPEED TRACKING =================

fig = figure('Color','w','Name','Lab 2 Speed Tracking');
tiledlayout(2,1);

nexttile;
plot(tCommon, m1RpmRefA, 'k--', 'LineWidth', 1.1); hold on;
plot(tCommon, m1RpmA,    'b',   'LineWidth', 1.1);
grid on;
ylabel('RPM');
title('Lab 2: Motor 1 EPA-Style Speed Tracking');
legend('Mtr1 speed ref','Mtr1 speed fb','Location','best');

nexttile;
plot(tCommon, rpmError, 'r', 'LineWidth', 1.0);
grid on;
xlabel('Time (s)');
ylabel('RPM Error');
title('Motor 1 Speed Tracking Error');

exportgraphics(fig, fullfile(outDir, 'step1_speed_tracking.png'), 'Resolution', 240);

%% ================= PLOT 2: Iq LOAD / REGEN INDICATOR =================

fig = figure('Color','w','Name','Lab 2 Iq Load Regen Indicator');
plot(tCommon, m1IqRefA, 'k--', 'LineWidth', 1.0); hold on;
plot(tCommon, m1IqA,    'r',   'LineWidth', 1.1);
yline(0, 'k-', 'LineWidth', 0.8);
scatter(tCommon(regenMask), m1IqA(regenMask), 20, 'b', 'filled');
grid on;
xlabel('Time (s)');
ylabel('Motor 1 Iq (A)');
title('Lab 2: Motor 1 Iq Feedback as Load/Regen Direction Indicator');
legend('Iq ref','Iq feedback','Zero line','Possible regen/loading windows','Location','best');

exportgraphics(fig, fullfile(outDir, 'step2_mtr1_iq_load_regen_indicator.png'), 'Resolution', 240);

%% ================= PLOT 3: MOTOR 1 MECHANICAL OUTPUT =================

fig = figure('Color','w','Name','Lab 2 Motor 1 Mechanical');
tiledlayout(2,1);

nexttile;
plot(tCommon, m1PmA, 'c', 'LineWidth', 1.1); hold on;
yline(0, 'k-', 'LineWidth', 0.8);
grid on;
ylabel('Pm (W)');
title('Motor 1 Mechanical Power');
legend('Mtr1 Pm','Zero line','Location','best');

nexttile;
plot(tCommon, m1TeA, 'm', 'LineWidth', 1.1); hold on;
yline(0, 'k-', 'LineWidth', 0.8);
grid on;
xlabel('Time (s)');
ylabel('Te (N*m)');
title('Motor 1 Torque');

exportgraphics(fig, fullfile(outDir, 'step3_mtr1_mechanical.png'), 'Resolution', 240);

%% ================= PLOT 4: MOTOR 2 MECHANICAL OUTPUT =================

fig = figure('Color','w','Name','Lab 2 Motor 2 Mechanical');
tiledlayout(2,1);

nexttile;
plot(tCommon, m2PmA, 'c', 'LineWidth', 1.1); hold on;
yline(0, 'k-', 'LineWidth', 0.8);
grid on;
ylabel('Pm (W)');
title('Motor 2 Mechanical Power');
legend('Mtr2 Pm','Zero line','Location','best');

nexttile;
plot(tCommon, m2TeA, 'm', 'LineWidth', 1.1); hold on;
yline(0, 'k-', 'LineWidth', 0.8);
grid on;
xlabel('Time (s)');
ylabel('Te (N*m)');
title('Motor 2 Torque');

exportgraphics(fig, fullfile(outDir, 'step4_mtr2_mechanical.png'), 'Resolution', 240);

%% ================= PLOT 5: MOTOR 1 VS MOTOR 2 MECHANICAL POWER =================

fig = figure('Color','w','Name','Lab 2 Mechanical Power Comparison');
tiledlayout(2,1);

nexttile;
plot(tCommon, m1PmA, 'b', 'LineWidth', 1.1); hold on;
plot(tCommon, m2PmA, 'r', 'LineWidth', 1.1);
plot(tCommon, sumPm, 'k--', 'LineWidth', 1.0);
yline(0, 'k-', 'LineWidth', 0.8);
grid on;
ylabel('Pm (W)');
title('Mechanical Power Comparison');
legend('Mtr1 Pm','Mtr2 Pm','Mtr1 + Mtr2 Pm','Zero line','Location','best');

nexttile;
plot(tCommon, m1TeA, 'b', 'LineWidth', 1.1); hold on;
plot(tCommon, m2TeA, 'r', 'LineWidth', 1.1);
yline(0, 'k-', 'LineWidth', 0.8);
grid on;
xlabel('Time (s)');
ylabel('Te (N*m)');
title('Torque Comparison');
legend('Mtr1 Te','Mtr2 Te','Zero line','Location','best');

exportgraphics(fig, fullfile(outDir, 'step5_motor_power_torque_comparison.png'), 'Resolution', 240);

%% ================= PLOT 6: REGEN / ABSORPTION DEMO =================

fig = figure('Color','w','Name','Lab 2 Regen Absorption Demo');
tiledlayout(3,1);

nexttile;
plot(tCommon, m1RpmRefA, 'k--', 'LineWidth', 1.0); hold on;
plot(tCommon, m1RpmA,    'b',   'LineWidth', 1.0);
grid on;
ylabel('RPM');
title('EPA-Style Speed Command and Feedback');
legend('Mtr1 speed ref','Mtr1 speed fb','Location','best');

nexttile;
plot(tCommon, m1IqA, 'r', 'LineWidth', 1.0); hold on;
yline(0, 'k-', 'LineWidth', 0.8);
scatter(tCommon(regenMask), m1IqA(regenMask), 18, 'b', 'filled');
grid on;
ylabel('Iq (A)');
title('Iq Sign Indicator');
legend('Mtr1 Iq feedback','Zero line','Negative Iq windows','Location','best');

nexttile;
plot(tCommon, m1PmA, 'b', 'LineWidth', 1.0); hold on;
plot(tCommon, m2PmA, 'r', 'LineWidth', 1.0);
yline(0, 'k-', 'LineWidth', 0.8);
grid on;
xlabel('Time (s)');
ylabel('Pm (W)');
title('Mechanical Power During Drive-Cycle');
legend('Mtr1 Pm','Mtr2 Pm','Zero line','Location','best');

exportgraphics(fig, fullfile(outDir, 'step6_regen_absorption_demo.png'), 'Resolution', 240);

%% ================= PLOT 7: COUPLING CHECK =================

fig = figure('Color','w','Name','Lab 2 Coupling Check');

if ~isempty(tCoupleCommon)
    plot(tCoupleCommon, m1RpmRefCoupleA, 'k--', 'LineWidth', 1.0); hold on;
    plot(tCoupleCommon, m2RpmA,          'g',   'LineWidth', 1.0);
    grid on;
    xlabel('Time (s)');
    ylabel('RPM');
    title({'Mechanical Coupling Check', ...
           'Motor 2 speed feedback is not yet trusted; shipped example needs investigation'});
    legend('Mtr1 speed ref','Mtr2 speed fb, diagnostic only','Location','best');
else
    text(0.1, 0.5, 'No valid Motor 2 speed feedback overlap found.', 'FontSize', 12);
    axis off;
end

exportgraphics(fig, fullfile(outDir, 'step7_mechanical_coupling_check_mtr2_speed_untrusted.png'), 'Resolution', 240);

%% ================= SUMMARY METRICS =================

meanAbsRpmError = mean(absRpmError(movingMask), 'omitnan');
maxAbsRpmError  = max(absRpmError(movingMask), [], 'omitnan');

pctMotoring = 100 * nnz(motoringMask) / max(nnz(movingMask), 1);
pctRegen    = 100 * nnz(regenMask)    / max(nnz(movingMask), 1);

m1PmMax = max(m1PmA, [], 'omitnan');
m1PmMin = min(m1PmA, [], 'omitnan');
m2PmMax = max(m2PmA, [], 'omitnan');
m2PmMin = min(m2PmA, [], 'omitnan');

m1TeMax = max(m1TeA, [], 'omitnan');
m1TeMin = min(m1TeA, [], 'omitnan');
m2TeMax = max(m2TeA, [], 'omitnan');
m2TeMin = min(m2TeA, [], 'omitnan');

fprintf('\n================ LAB 2 EPA DEMO SUMMARY ================\n');
fprintf('Output folder:\n%s\n\n', outDir);

fprintf('Time window used: %.2f to %.2f s\n', startTimeSec, endTimeSec);
fprintf('Aligned points: %d\n', numel(tCommon));

fprintf('\nSpeed tracking:\n');
fprintf('  Mean abs RPM error: %.2f RPM\n', meanAbsRpmError);
fprintf('  Max abs RPM error:  %.2f RPM\n', maxAbsRpmError);

fprintf('\nIq sign demo:\n');
fprintf('  Percent moving samples with positive Iq: %.2f %%\n', pctMotoring);
fprintf('  Percent moving samples with negative Iq: %.2f %%\n', pctRegen);

fprintf('\nMechanical power:\n');
fprintf('  Mtr1 Pm range: %.2f to %.2f W\n', m1PmMin, m1PmMax);
fprintf('  Mtr2 Pm range: %.2f to %.2f W\n', m2PmMin, m2PmMax);

fprintf('\nTorque:\n');
fprintf('  Mtr1 Te range: %.4f to %.4f N*m\n', m1TeMin, m1TeMax);
fprintf('  Mtr2 Te range: %.4f to %.4f N*m\n', m2TeMin, m2TeMax);

fprintf('\nImportant limitations:\n');
fprintf('  Motor 2 speed feedback is not yet trusted.\n');
fprintf('  Motor 2 electrical power is not available.\n');
fprintf('  This is a Lab 2 demonstration analysis, not final calibrated dyno efficiency.\n');
fprintf('  Input commands should be adjusted to create a fuller regen-braking window.\n');

%% ================= SAVE DATA =================

save(fullfile(outDir, 'lab2_epa_demo_analysis_data.mat'), ...
    'tCommon', ...
    'm1RpmRefA', 'm1RpmA', 'rpmError', 'absRpmError', ...
    'm1IqRefA', 'm1IqA', ...
    'm1PmA', 'm1TeA', ...
    'm2PmA', 'm2TeA', ...
    'sumPm', ...
    'movingMask', 'motoringMask', 'regenMask', ...
    'm1PositivePowerMask', 'm1NegativePowerMask', ...
    'm2PositivePowerMask', 'm2NegativePowerMask', ...
    'tCoupleCommon', 'm1RpmRefCoupleA', 'm2RpmA', ...
    'meanAbsRpmError', 'maxAbsRpmError', ...
    'pctMotoring', 'pctRegen', ...
    'm1PmMin', 'm1PmMax', 'm2PmMin', 'm2PmMax', ...
    'm1TeMin', 'm1TeMax', 'm2TeMin', 'm2TeMax');

fprintf('\nSaved Lab 2 demo analysis data.\n');

%% ================= HELPERS =================

function [t, y] = readTrialSignal(baseDir, trialName, baseName)
    filePath = fullfile(baseDir, trialName, [baseName '.csv']);
    [t, y] = readSingleSignalCsv(filePath);
end

function [tOut, yOut] = cropByTime(t, y, tStart, tEnd)
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
        return;
    end

    isNum = varfun(@isnumeric, T, 'OutputFormat', 'uniform');
    Tn = T(:, isNum);

    if width(Tn) == 0
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