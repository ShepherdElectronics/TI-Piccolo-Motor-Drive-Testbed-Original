%% build_motor1_efficiency_trial01_04_FINAL.m
clear; clc; close all;

baseDir = pwd;

%% ================= USER SETTINGS =================

startTimeSec = 0;
endTimeSec   = inf;

speedTrial = "trial01";   % Mtr1 Speed ref & Speed feedback
iqTrial    = "trial02";   % Mtr1 Iq ref & Iq feedback
vdvqTrial  = "trial03";   % Mtr1 Vd & Vq, but Vd forced to zero
pmteTrial  = "trial04";   % Mtr1 Pm & Te

% Sanity limits
maxAbsRPM = 6000;
maxAbsIq  = 8;
maxAbsVq  = 200;
maxAbsTe  = 0.30;
maxAbsPm  = 1000;

% Physics filters
minPelec  = 10;       % W
minPmech  = 3;        % W
minTorque = 0.045;    % N*m
etaMin    = 0.0;
etaMax    = 1.05;

% Map binning
rpmEdges        = 0:100:4000;
torqueEdges     = 0:0.01:0.25;
minCountPerBin  = 3;
useMedianInBins = true;

outDir = fullfile(baseDir, 'motor1_efficiency_trial01_04_FINAL');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

%% ================= LOAD RAW SIGNALS =================

[tRpmRefRaw, rpmRefRaw] = readTrialSignal(baseDir, speedTrial, 'debug_1');
[tRpmRaw,    rpmRaw]    = readTrialSignal(baseDir, speedTrial, 'debug_2');

[tIqRefRaw, iqRefRaw] = readTrialSignal(baseDir, iqTrial, 'debug_1');
[tIqRaw,    iqRaw]    = readTrialSignal(baseDir, iqTrial, 'debug_2');

% Ignore Vd channel. Use debug_2 only as Vq.
[tVqRaw, vqRaw] = readTrialSignal(baseDir, vdvqTrial, 'debug_2');

[tPmRaw, pmRaw] = readTrialSignal(baseDir, pmteTrial, 'debug_1');
[tTeRaw, teRaw] = readTrialSignal(baseDir, pmteTrial, 'debug_2');

%% ================= TRUE RAW PLOT, ZOOMED =================

iqPlot = iqRaw;
vqPlot = vqRaw;
pmPlot = pmRaw;

iqPlot(abs(iqPlot) > 20)   = NaN;
vqPlot(abs(vqPlot) > 500)  = NaN;
pmPlot(abs(pmPlot) > 200)  = NaN;

fig = figure('Color','w','Name','Step 0 Raw Data Zoomed');
tiledlayout(4,1);

nexttile;
plot(tRpmRefRaw, rpmRefRaw, 'k--', 'LineWidth', 1.0); hold on;
plot(tRpmRaw, rpmRaw, 'b', 'LineWidth', 1.0);
grid on; ylabel('RPM');
title('RAW: Speed Reference vs Feedback');
legend('RPM ref','RPM fb','Location','best');

nexttile;
plot(tIqRefRaw, iqRefRaw, 'k--', 'LineWidth', 1.0); hold on;
plot(tIqRaw, iqPlot, 'r', 'LineWidth', 1.0);
grid on; ylabel('Iq (A)');
ylim([-1 5]);
title('RAW: Iq, Zoomed');
legend('Iq ref','Iq fb','Location','best');

nexttile;
plot(tVqRaw, vqPlot, 'r', 'LineWidth', 1.0);
grid on; ylabel('Vq (V)');
ylim([0 200]);
title('RAW: Vq, Zoomed');

nexttile;
plot(tPmRaw, pmPlot, 'c', 'LineWidth', 1.0); hold on;
plot(tTeRaw, teRaw, 'm', 'LineWidth', 1.0);
grid on; xlabel('Time (s)'); ylabel('Pm / Te');
ylim([0 0.25]);
title('RAW: Mechanical, Zoomed');
legend('Pm','Te','Location','best');

exportgraphics(fig, fullfile(outDir, 'step0_raw_zoomed.png'), 'Resolution', 240);

%% ================= CROP =================

[tRpmRef, rpmRef] = cropByTime(tRpmRefRaw, rpmRefRaw, startTimeSec, endTimeSec);
[tRpm,    rpm]    = cropByTime(tRpmRaw,    rpmRaw,    startTimeSec, endTimeSec);

[tIqRef, iqRef] = cropByTime(tIqRefRaw, iqRefRaw, startTimeSec, endTimeSec);
[tIq,    iq]    = cropByTime(tIqRaw,    iqRaw,    startTimeSec, endTimeSec);

[tVq, vq] = cropByTime(tVqRaw, vqRaw, startTimeSec, endTimeSec);

[tPm, pm] = cropByTime(tPmRaw, pmRaw, startTimeSec, endTimeSec);
[tTe, te] = cropByTime(tTeRaw, teRaw, startTimeSec, endTimeSec);

%% ================= ALIGN TO COMMON TIME BASE =================

tStart = max([safeFirst(tRpm), safeFirst(tIq), safeFirst(tVq), safeFirst(tPm), safeFirst(tTe)]);
tEnd   = min([safeLast(tRpm),  safeLast(tIq),  safeLast(tVq),  safeLast(tPm),  safeLast(tTe)]);

if tEnd <= tStart
    error('No overlapping time region across trial01-trial04.');
end

candidates = {tRpm, tIq, tVq, tPm, tTe};
lengths = cellfun(@numel, candidates);
[~, idxDense] = max(lengths);

tBase = candidates{idxDense};
tCommon = tBase(tBase >= tStart & tBase <= tEnd);

rpmA    = interpKeepNaN(tRpm,    rpm,    tCommon);
rpmRefA = interpKeepNaN(tRpmRef, rpmRef, tCommon);

iqA     = interpKeepNaN(tIq,    iq,    tCommon);
iqRefA  = interpKeepNaN(tIqRef, iqRef, tCommon);

vqA     = interpKeepNaN(tVq, vq, tCommon);
vdA     = zeros(size(vqA));

pmA     = interpKeepNaN(tPm, pm, tCommon);
teA     = interpKeepNaN(tTe, te, tCommon);

%% ================= BASIC SANITY FILTER =================

validBasic = isfinite(rpmA) & isfinite(iqA) & isfinite(vqA) & ...
             isfinite(pmA) & isfinite(teA) & ...
             abs(rpmA) <= maxAbsRPM & ...
             abs(iqA)  <= maxAbsIq  & ...
             abs(vqA)  <= maxAbsVq  & ...
             abs(teA)  <= maxAbsTe  & ...
             abs(pmA)  <= maxAbsPm;

tCommon = tCommon(validBasic);
rpmA    = rpmA(validBasic);
rpmRefA = rpmRefA(validBasic);
iqA     = iqA(validBasic);
iqRefA  = iqRefA(validBasic);
vdA     = vdA(validBasic);
vqA     = vqA(validBasic);
pmA     = pmA(validBasic);
teA     = teA(validBasic);

%% ================= POWER + PHYSICS FILTER =================

Pelec_raw = 1.5 .* vqA .* iqA;
Pmech_raw = pmA;
eta_raw   = Pmech_raw ./ Pelec_raw;

maskFinite = isfinite(Pelec_raw) & isfinite(Pmech_raw) & isfinite(eta_raw);
maskPelec  = Pelec_raw > minPelec;
maskPmech  = Pmech_raw > minPmech;
maskTorque = teA > minTorque;
maskEta    = eta_raw > etaMin & eta_raw < etaMax;

validPhysics = maskFinite & maskPelec & maskPmech & maskTorque & maskEta;

%% ================= CLEANING DIAGNOSTIC PLOT, NO FAKE LINES =================

fig = figure('Color','w','Name','Aligned Data With Kept Points Overlay');
tiledlayout(5,1);

nexttile;
plot(tCommon, rpmRefA, 'k--', 'LineWidth', 1.0); hold on;
plot(tCommon, rpmA, 'b', 'LineWidth', 1.0);
scatter(tCommon(validPhysics), rpmA(validPhysics), 8, 'g', 'filled');
grid on; ylabel('RPM');
title('RPM: Raw Aligned Line + Kept Points');
legend('RPM ref','RPM fb','Kept','Location','best');

nexttile;
plot(tCommon, iqRefA, 'k--', 'LineWidth', 1.0); hold on;
plot(tCommon, iqA, 'r', 'LineWidth', 1.0);
scatter(tCommon(validPhysics), iqA(validPhysics), 8, 'g', 'filled');
grid on; ylabel('Iq (A)');
title('Iq: Raw Aligned Line + Kept Points');
legend('Iq ref','Iq fb','Kept','Location','best');

nexttile;
plot(tCommon, vqA, 'r', 'LineWidth', 1.0); hold on;
plot(tCommon, vdA, 'b', 'LineWidth', 1.0);
scatter(tCommon(validPhysics), vqA(validPhysics), 8, 'g', 'filled');
grid on; ylabel('Vd / Vq');
title('Vq Used, Vd Forced to 0');
legend('Vq','Vd=0','Kept','Location','best');

nexttile;
plot(tCommon, pmA, 'c', 'LineWidth', 1.0); hold on;
plot(tCommon, teA, 'm', 'LineWidth', 1.0);
scatter(tCommon(validPhysics), teA(validPhysics), 8, 'g', 'filled');
grid on; ylabel('Pm / Te');
title('Pm and Te: Raw Aligned Line + Kept Points');
legend('Pm','Te','Kept Te','Location','best');

nexttile;
plot(tCommon, eta_raw, 'Color', [0.5 0.5 0.5], 'LineWidth', 1.0); hold on;
scatter(tCommon(validPhysics), eta_raw(validPhysics), 8, 'g', 'filled');
grid on; xlabel('Time (s)'); ylabel('Efficiency');
ylim([0 1.1]);
title('Efficiency Before/After Cleaning');
legend('Raw eta','Kept eta','Location','best');

exportgraphics(fig, fullfile(outDir, 'step1_cleaning_overlay_no_fake_lines.png'), 'Resolution', 240);

%% ================= FILTER MASK PLOTS =================

fig = figure('Color','w','Name','Filter Masks');
tiledlayout(5,1);

nexttile; plot(tCommon, double(maskPelec), 'LineWidth', 1.0);
grid on; ylim([-0.1 1.1]); ylabel('Pass');
title(sprintf('Pelec > %.2f W', minPelec));

nexttile; plot(tCommon, double(maskPmech), 'LineWidth', 1.0);
grid on; ylim([-0.1 1.1]); ylabel('Pass');
title(sprintf('Pmech > %.2f W', minPmech));

nexttile; plot(tCommon, double(maskTorque), 'LineWidth', 1.0);
grid on; ylim([-0.1 1.1]); ylabel('Pass');
title(sprintf('Te > %.4f N*m', minTorque));

nexttile; plot(tCommon, double(maskEta), 'LineWidth', 1.0);
grid on; ylim([-0.1 1.1]); ylabel('Pass');
title(sprintf('%.2f < eta < %.2f', etaMin, etaMax));

nexttile; plot(tCommon, double(validPhysics), 'k', 'LineWidth', 1.0);
grid on; ylim([-0.1 1.1]); xlabel('Time (s)'); ylabel('Pass');
title('Final Combined Physics Filter');

exportgraphics(fig, fullfile(outDir, 'step2_filter_masks.png'), 'Resolution', 240);

%% ================= APPLY FINAL FILTER =================

tClean      = tCommon(validPhysics);
rpmClean    = rpmA(validPhysics);
rpmRefClean = rpmRefA(validPhysics);
iqClean     = iqA(validPhysics);
iqRefClean  = iqRefA(validPhysics);
vdClean     = vdA(validPhysics);
vqClean     = vqA(validPhysics);
pmClean     = pmA(validPhysics);
teClean     = teA(validPhysics);

Pelec = Pelec_raw(validPhysics);
Pmech = Pmech_raw(validPhysics);
eta   = eta_raw(validPhysics);

%% ================= FINAL CLEANED SCATTER PLOTS =================

fig = figure('Color','w','Name','Valid Points Colored by Efficiency');
scatter(rpmClean, teClean, 8, eta, 'filled');
grid on;
xlabel('RPM');
ylabel('Torque Te (N*m)');
title('Motor 1 Valid Operating Points Colored by Efficiency');
xlim([0 4200]);
ylim([0 0.25]);
cb = colorbar;
ylabel(cb, 'Efficiency');
caxis([0 1]);
exportgraphics(fig, fullfile(outDir, 'step3_valid_points_efficiency_scatter.png'), 'Resolution', 240);

%% ================= BUILD MEASURED EFFICIENCY MAP =================

rpmCenters    = (rpmEdges(1:end-1) + rpmEdges(2:end))/2;
torqueCenters = (torqueEdges(1:end-1) + torqueEdges(2:end))/2;

etaMap   = nan(numel(torqueCenters), numel(rpmCenters));
countMap = zeros(size(etaMap));

for i = 1:numel(rpmCenters)
    for j = 1:numel(torqueCenters)

        inBin = rpmClean >= rpmEdges(i) & rpmClean < rpmEdges(i+1) & ...
                teClean  >= torqueEdges(j) & teClean  < torqueEdges(j+1);

        if any(inBin)
            if useMedianInBins
                etaMap(j,i) = median(eta(inBin), 'omitnan');
            else
                etaMap(j,i) = mean(eta(inBin), 'omitnan');
            end
            countMap(j,i) = sum(inBin);
        end
    end
end

etaMap(countMap < minCountPerBin) = NaN;

%% ================= STRONG INTERPOLATED PRESENTATION MAP =================

[X, Y] = meshgrid(rpmCenters, torqueCenters);
validInterp = isfinite(etaMap);

if nnz(validInterp) >= 10

    F = scatteredInterpolant( ...
        X(validInterp), ...
        Y(validInterp), ...
        etaMap(validInterp), ...
        'natural', ...
        'nearest');

    etaMapSmooth = F(X, Y);

    countMask = countMap > 0;
    expansionKernel = ones(9,9);
    countMaskExpanded = conv2(double(countMask), expansionKernel, 'same') > 0;

    etaMapSmooth(~countMaskExpanded) = NaN;

    for k = 1:3
        etaTemp = etaMapSmooth;
        etaTemp(~isfinite(etaTemp)) = 0;

        weight = double(isfinite(etaMapSmooth));
        smoothKernel = ones(5,5);

        etaFiltered = conv2(etaTemp, smoothKernel, 'same') ./ ...
                      max(conv2(weight, smoothKernel, 'same'), eps);

        etaMapSmooth(isfinite(etaMapSmooth)) = etaFiltered(isfinite(etaMapSmooth));
    end

    etaMapSmooth(etaMapSmooth < 0) = 0;
    etaMapSmooth(etaMapSmooth > 1) = 1;

else
    etaMapSmooth = etaMap;
    warning('Not enough measured bins to interpolate efficiency map.');
end

%% ================= FINAL MAP PLOTS =================

fig = figure('Color','w','Name','Measured Efficiency Map');
imagesc(rpmCenters, torqueCenters, etaMap);
set(gca, 'YDir', 'normal');
grid on;
xlabel('Speed (RPM)');
ylabel('Torque Te (N*m)');
title('Motor 1 Efficiency Map, Measured Bins');
ylim([0 0.25]);
colormap(jet);
cb = colorbar;
ylabel(cb, 'Efficiency');
caxis([0 1]);
exportgraphics(fig, fullfile(outDir, 'step4_efficiency_map_measured_bins.png'), 'Resolution', 240);

fig = figure('Color','w','Name','Sample Count Map');
imagesc(rpmCenters, torqueCenters, countMap);
set(gca, 'YDir', 'normal');
grid on;
xlabel('Speed (RPM)');
ylabel('Torque Te (N*m)');
title('Sample Count per Bin');
ylim([0 0.25]);
cb = colorbar;
ylabel(cb, 'Count');
exportgraphics(fig, fullfile(outDir, 'step5_count_map.png'), 'Resolution', 240);

fig = figure('Color','w','Name','Strong Interpolated Efficiency Map');
imagesc(rpmCenters, torqueCenters, etaMapSmooth);
set(gca, 'YDir', 'normal');
grid on;
xlabel('Speed (RPM)');
ylabel('Torque Te (N*m)');
title('Motor 1 Efficiency Map, Strong Interpolated View');
ylim([0 0.25]);
colormap(jet);
cb = colorbar;
ylabel(cb, 'Efficiency');
caxis([0 1]);
exportgraphics(fig, fullfile(outDir, 'step6_efficiency_map_strong_interpolated.png'), 'Resolution', 240);

fig = figure('Color','w','Name','Strong Interpolated Efficiency Contour');
contourf(rpmCenters, torqueCenters, etaMapSmooth, 30, 'LineColor', 'none');
grid on;
xlabel('Speed (RPM)');
ylabel('Torque Te (N*m)');
title('Motor 1 Efficiency Map Contour, Strong Interpolated View');
ylim([0 0.25]);
colormap(jet);
cb = colorbar;
ylabel(cb, 'Efficiency');
caxis([0 1]);
exportgraphics(fig, fullfile(outDir, 'step7_efficiency_map_contour_strong_interpolated.png'), 'Resolution', 240);

%% ================= SAVE =================

save(fullfile(outDir, 'motor1_efficiency_trial01_04_FINAL_data.mat'), ...
    'tCommon', 'rpmA', 'rpmRefA', 'iqA', 'iqRefA', 'vdA', 'vqA', 'pmA', 'teA', ...
    'validPhysics', 'tClean', 'rpmClean', 'rpmRefClean', 'iqClean', 'iqRefClean', ...
    'vdClean', 'vqClean', 'pmClean', 'teClean', ...
    'Pelec', 'Pmech', 'eta', 'Pelec_raw', 'Pmech_raw', 'eta_raw', ...
    'rpmEdges', 'torqueEdges', 'rpmCenters', 'torqueCenters', ...
    'etaMap', 'etaMapSmooth', 'countMap', ...
    'minPelec', 'minPmech', 'minTorque');

fprintf('\nDone. Saved to:\n%s\n', outDir);
fprintf('Raw aligned points: %d\n', numel(validPhysics));
fprintf('Kept valid points: %d\n', nnz(validPhysics));
fprintf('Rejected points: %d\n', numel(validPhysics) - nnz(validPhysics));
fprintf('Torque range kept: %.4f to %.4f N*m\n', min(teClean), max(teClean));
fprintf('RPM range kept: %.1f to %.1f RPM\n', min(rpmClean), max(rpmClean));

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