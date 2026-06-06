%% Lab2_EPA_drivecycle_analysis_FINAL.m
% Final Lab 2 EPA drive-cycle analysis script
%
% Expected folder layout, default:
%
%   base folder/
%     trial01/debug_1.csv   Mtr1 speed reference
%     trial01/debug_2.csv   Mtr1 speed feedback
%     trial02/debug_1.csv   Mtr1 Iq reference
%     trial02/debug_2.csv   Mtr1 Iq feedback
%     trial03/debug_1.csv   Mtr1 mechanical power Pm
%     trial03/debug_2.csv   Mtr2 mechanical power Pm
%     trial04/debug_1.csv   Mtr1 torque Te
%     trial04/debug_2.csv   Mtr2 torque Te
%     trial05/debug_1.csv   Mtr1 speed reference, coupling run
%     trial05/debug_2.csv   Mtr2 speed feedback, coupling run
%
% If your saved folders are different, only edit the USER SETTINGS section.
%
% Main outputs:
%   1) Speed tracking plot and metrics
%   2) Iq/load tracking plot and metrics
%   3) Accel/decel classification from EPA speed reference
%   4) Mtr1/Mtr2 Pm and Te plots
%   5) Generated/absorbed energy estimates from Pm
%   6) Mechanical coupling plots and correlation metrics
%   7) Optional operating-point plot colored by efficiency estimate
%
% Notes:
%   - This script keeps the analysis honest: it does not invent missing data.
%   - If torque data or motor power data is missing, the relevant plots are skipped.
%   - Efficiency is only plotted where Mtr1 Pm, speed, and Te are all available.

clear; clc; close all;

baseDir = pwd;

%% ================= USER SETTINGS =================

outDir = fullfile(baseDir, 'Lab2_EPA_drivecycle_analysis_FINAL');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

% Trial folders
speedTrial      = "trial01";   % Mtr1: Speed ref & Speed feedback
loadTrial       = "trial02";   % Mtr1: Iq ref & Iq feedback
powerTrial      = "trial03";   % Mtr1&Mtr2: Pm
teTrial         = "trial04";   % Mtr1&Mtr2: Te
couplingTrialA  = "trial05";   % Mtr1 Speed ref & Mtr2 Speed fb
couplingTrialB  = "";          % optional second coupling run, e.g. "trial06"; leave blank if absent

% Time crop. Leave endTimeSec = inf for full run.
startTimeSec = 0;
endTimeSec   = inf;

% Signal sanity limits
maxAbsRPM = 7000;
maxAbsIq  = 20;
maxAbsPm  = 3000;
maxAbsTe  = 2.0;

% EPA accel/decel classification
rpmSmoothN          = 101;      % smoothing samples for RPM before derivative
minAccelRPMps       = 8;        % RPM/s threshold for accel
minDecelRPMps       = -8;       % RPM/s threshold for decel
minMovingRPM        = 25;       % ignore near-zero parked points

% Tracking metrics window
useOnlyMovingForTracking = true;

% Optional efficiency estimate from measured Mtr1 Pm and estimated input electrical power.
% If Vq/Iq is not collected in Lab 2, this is skipped automatically.
makeEfficiencyIfPossible = true;
vdvqTrial = "";                % optional, e.g. "trial06" if you captured Mtr1 Vd & Vq

% Electrical-power fallback if no Vq is available.
% This is NOT an efficiency calculation; it is only for plotting normalized operating points.
Kt_Nm_per_A = 0.0384;           % Teknic 2310P constant from earlier setup, edit if needed

% Plot limits
rpmPlotMax = 4200;

%% ================= LOAD TRIAL DATA =================

% Trial 1: speed tracking
[tSpdRefRaw, spdRefRaw] = readTrialSignal(baseDir, speedTrial, 'debug_1');
[tSpdFbRaw,  spdFbRaw]  = readTrialSignal(baseDir, speedTrial, 'debug_2');

% Trial 2: load/Iq tracking
[tIqRefRaw, iqRefRaw] = readTrialSignal(baseDir, loadTrial, 'debug_1');
[tIqFbRaw,  iqFbRaw]  = readTrialSignal(baseDir, loadTrial, 'debug_2');

% Trial 3: Mtr1 and Mtr2 mechanical power
[tPm1Raw, pm1Raw] = readTrialSignal(baseDir, powerTrial, 'debug_1');
[tPm2Raw, pm2Raw] = readTrialSignal(baseDir, powerTrial, 'debug_2');

% Trial 4: Mtr1 and Mtr2 torque
[tTe1Raw, te1Raw] = readTrialSignal(baseDir, teTrial, 'debug_1');
[tTe2Raw, te2Raw] = readTrialSignal(baseDir, teTrial, 'debug_2');

% Trial 5: coupling proof
[tCoupRefRawA, coupRefRawA] = readTrialSignal(baseDir, couplingTrialA, 'debug_1');
[tCoupFbRawA,  coupFbRawA]  = readTrialSignal(baseDir, couplingTrialA, 'debug_2');

% Optional second coupling run
if strlength(couplingTrialB) > 0
    [tCoupRefRawB, coupRefRawB] = readTrialSignal(baseDir, couplingTrialB, 'debug_1');
    [tCoupFbRawB,  coupFbRawB]  = readTrialSignal(baseDir, couplingTrialB, 'debug_2');
else
    tCoupRefRawB = []; coupRefRawB = [];
    tCoupFbRawB  = []; coupFbRawB  = [];
end

% Optional Vq trial
if makeEfficiencyIfPossible && strlength(vdvqTrial) > 0
    [tVdRaw, vdRaw] = readTrialSignal(baseDir, vdvqTrial, 'debug_1');
    [tVqRaw, vqRaw] = readTrialSignal(baseDir, vdvqTrial, 'debug_2');
else
    tVdRaw = []; vdRaw = [];
    tVqRaw = []; vqRaw = [];
end

%% ================= CROP AND LOCALIZE TIME =================

[tSpdRef, spdRef] = cropByTime(tSpdRefRaw, spdRefRaw, startTimeSec, endTimeSec);
[tSpdFb,  spdFb]  = cropByTime(tSpdFbRaw,  spdFbRaw,  startTimeSec, endTimeSec);
[tIqRef, iqRef]   = cropByTime(tIqRefRaw, iqRefRaw, startTimeSec, endTimeSec);
[tIqFb,  iqFb]    = cropByTime(tIqFbRaw,  iqFbRaw,  startTimeSec, endTimeSec);
[tPm1, pm1]       = cropByTime(tPm1Raw, pm1Raw, startTimeSec, endTimeSec);
[tPm2, pm2]       = cropByTime(tPm2Raw, pm2Raw, startTimeSec, endTimeSec);
[tTe1, te1]       = cropByTime(tTe1Raw, te1Raw, startTimeSec, endTimeSec);
[tTe2, te2]       = cropByTime(tTe2Raw, te2Raw, startTimeSec, endTimeSec);
[tCoupRefA, coupRefA] = cropByTime(tCoupRefRawA, coupRefRawA, startTimeSec, endTimeSec);
[tCoupFbA,  coupFbA]  = cropByTime(tCoupFbRawA,  coupFbRawA,  startTimeSec, endTimeSec);
[tCoupRefB, coupRefB] = cropByTime(tCoupRefRawB, coupRefRawB, startTimeSec, endTimeSec);
[tCoupFbB,  coupFbB]  = cropByTime(tCoupFbRawB,  coupFbRawB,  startTimeSec, endTimeSec);
[tVd, vd] = cropByTime(tVdRaw, vdRaw, startTimeSec, endTimeSec);
[tVq, vq] = cropByTime(tVqRaw, vqRaw, startTimeSec, endTimeSec);

[tSpdRef, spdRef, tSpdFb, spdFb] = localizePairTime(tSpdRef, spdRef, tSpdFb, spdFb);
[tIqRef, iqRef, tIqFb, iqFb]     = localizePairTime(tIqRef, iqRef, tIqFb, iqFb);
[tPm1, pm1, tPm2, pm2]           = localizePairTime(tPm1, pm1, tPm2, pm2);
[tTe1, te1, tTe2, te2]           = localizePairTime(tTe1, te1, tTe2, te2);
[tCoupRefA, coupRefA, tCoupFbA, coupFbA] = localizePairTime(tCoupRefA, coupRefA, tCoupFbA, coupFbA);
[tCoupRefB, coupRefB, tCoupFbB, coupFbB] = localizePairTime(tCoupRefB, coupRefB, tCoupFbB, coupFbB);
[tVd, vd, tVq, vq] = localizePairTime(tVd, vd, tVq, vq);

%% ================= TRIAL 1: EPA SPEED TRACKING =================

[tSpeed, spdRefA, spdFbA] = alignTwoSignals(tSpdRef, spdRef, tSpdFb, spdFb);
validSpeed = isfinite(spdRefA) & isfinite(spdFbA) & ...
             abs(spdRefA) <= maxAbsRPM & abs(spdFbA) <= maxAbsRPM;

tSpeed = tSpeed(validSpeed);
spdRefA = spdRefA(validSpeed);
spdFbA = spdFbA(validSpeed);

speedErr = spdFbA - spdRefA;
trackingMask = true(size(tSpeed));
if useOnlyMovingForTracking
    trackingMask = abs(spdRefA) > minMovingRPM;
end

speedRMSE = rmsNoNaN(speedErr(trackingMask));
speedMAE  = mean(abs(speedErr(trackingMask)), 'omitnan');
speedMaxAbsErr = max(abs(speedErr(trackingMask)), [], 'omitnan');
speedCorr = corrNoNaN(spdRefA(trackingMask), spdFbA(trackingMask));

% Accel/decel classification based on the reference speed.
spdRefSmooth = movmedian(spdRefA, rpmSmoothN, 'omitnan');
rpmRate = derivativeNonuniform(tSpeed, spdRefSmooth);
rpmRateSmooth = movmedian(rpmRate, rpmSmoothN, 'omitnan');
maskAccel = rpmRateSmooth > minAccelRPMps & abs(spdRefA) > minMovingRPM;
maskDecel = rpmRateSmooth < minDecelRPMps & abs(spdRefA) > minMovingRPM;
maskCruise = ~maskAccel & ~maskDecel & abs(spdRefA) > minMovingRPM;

fig = figure('Color','w','Name','Trial 1 EPA Speed Tracking');
tiledlayout(3,1);
nexttile;
plot(tSpeed, spdRefA, 'k--', 'LineWidth', 1.0); hold on;
plot(tSpeed, spdFbA, 'b', 'LineWidth', 1.0);
grid on; ylabel('Speed (RPM)');
title(sprintf('EPA Speed Tracking: RMSE %.2f RPM, MAE %.2f RPM, Corr %.4f', speedRMSE, speedMAE, speedCorr));
legend('Mtr1 speed ref','Mtr1 speed feedback','Location','best');

nexttile;
plot(tSpeed, speedErr, 'r', 'LineWidth', 1.0);
grid on; ylabel('Error (RPM)');
title(sprintf('Speed Tracking Error, Max |Error| %.2f RPM', speedMaxAbsErr));

nexttile;
plot(tSpeed, rpmRateSmooth, 'k', 'LineWidth', 1.0); hold on;
yline(minAccelRPMps, 'g--', 'Accel threshold');
yline(minDecelRPMps, 'r--', 'Decel threshold');
grid on; xlabel('Time (s)'); ylabel('dRPM/dt');
title('EPA Acceleration / Deceleration Classification Signal');
exportgraphics(fig, fullfile(outDir, '01_speed_tracking_and_accel_decel.png'), 'Resolution', 240);

fig = figure('Color','w','Name','Accel Decel Points on EPA Speed');
plot(tSpeed, spdRefA, 'Color', [0.45 0.45 0.45], 'LineWidth', 1.0); hold on;
scatter(tSpeed(maskAccel), spdRefA(maskAccel), 8, 'g', 'filled');
scatter(tSpeed(maskDecel), spdRefA(maskDecel), 8, 'r', 'filled');
scatter(tSpeed(maskCruise), spdRefA(maskCruise), 5, 'b', 'filled');
grid on; xlabel('Time (s)'); ylabel('Speed ref (RPM)');
title('EPA Drive Cycle Sections: Accel, Decel, and Cruise/Flat');
legend('EPA speed ref','Accel','Decel','Cruise/flat','Location','best');
exportgraphics(fig, fullfile(outDir, '02_epa_accel_decel_classification.png'), 'Resolution', 240);

%% ================= TRIAL 2: LOAD / IQ TRACKING =================

[tLoad, iqRefA, iqFbA] = alignTwoSignals(tIqRef, iqRef, tIqFb, iqFb);
validLoad = isfinite(iqRefA) & isfinite(iqFbA) & ...
            abs(iqRefA) <= maxAbsIq & abs(iqFbA) <= maxAbsIq;

tLoad = tLoad(validLoad);
iqRefA = iqRefA(validLoad);
iqFbA = iqFbA(validLoad);

iqErr = iqFbA - iqRefA;
iqRMSE = rmsNoNaN(iqErr);
iqMAE  = mean(abs(iqErr), 'omitnan');
iqMaxAbsErr = max(abs(iqErr), [], 'omitnan');
iqCorr = corrNoNaN(iqRefA, iqFbA);

fig = figure('Color','w','Name','Trial 2 Iq Load Tracking');
tiledlayout(2,1);
nexttile;
plot(tLoad, iqRefA, 'k--', 'LineWidth', 1.0); hold on;
plot(tLoad, iqFbA, 'r', 'LineWidth', 1.0);
grid on; ylabel('Iq (A)');
title(sprintf('Load / Iq Tracking: RMSE %.3f A, MAE %.3f A, Corr %.4f', iqRMSE, iqMAE, iqCorr));
legend('Iq ref','Iq feedback','Location','best');

nexttile;
plot(tLoad, iqErr, 'm', 'LineWidth', 1.0);
grid on; xlabel('Time (s)'); ylabel('Iq Error (A)');
title(sprintf('Iq Tracking Error, Max |Error| %.3f A', iqMaxAbsErr));
exportgraphics(fig, fullfile(outDir, '03_iq_load_tracking.png'), 'Resolution', 240);

%% ================= TRIALS 3 AND 4: POWER AND TORQUE =================

[tPower, pm1A, pm2A] = alignTwoSignals(tPm1, pm1, tPm2, pm2);
validPower = isfinite(pm1A) & isfinite(pm2A) & abs(pm1A) <= maxAbsPm & abs(pm2A) <= maxAbsPm;
tPower = tPower(validPower);
pm1A = pm1A(validPower);
pm2A = pm2A(validPower);

[tTorque, te1A, te2A] = alignTwoSignals(tTe1, te1, tTe2, te2);
validTorque = isfinite(te1A) & isfinite(te2A) & abs(te1A) <= maxAbsTe & abs(te2A) <= maxAbsTe;
tTorque = tTorque(validTorque);
te1A = te1A(validTorque);
te2A = te2A(validTorque);

% Energy estimates from Pm. Sign convention depends on your Simulink signal.
% The script reports positive and negative energy separately so you can interpret it correctly.
energyM1_Pos_J = integratePositive(tPower, pm1A);
energyM1_Neg_J = integrateNegative(tPower, pm1A);
energyM2_Pos_J = integratePositive(tPower, pm2A);
energyM2_Neg_J = integrateNegative(tPower, pm2A);

fig = figure('Color','w','Name','Mtr1 and Mtr2 Mechanical Power');
plot(tPower, pm1A, 'b', 'LineWidth', 1.0); hold on;
plot(tPower, pm2A, 'r', 'LineWidth', 1.0);
yline(0, 'k--');
grid on; xlabel('Time (s)'); ylabel('Pm (W)');
title('Mechanical Power: Motor 1 and Motor 2');
legend('Mtr1 Pm','Mtr2 Pm','Zero','Location','best');
exportgraphics(fig, fullfile(outDir, '04_mtr1_mtr2_mechanical_power.png'), 'Resolution', 240);

fig = figure('Color','w','Name','Mtr1 and Mtr2 Torque');
plot(tTorque, te1A, 'b', 'LineWidth', 1.0); hold on;
plot(tTorque, te2A, 'r', 'LineWidth', 1.0);
yline(0, 'k--');
grid on; xlabel('Time (s)'); ylabel('Te (N*m)');
title('Electromagnetic Torque: Motor 1 and Motor 2');
legend('Mtr1 Te','Mtr2 Te','Zero','Location','best');
exportgraphics(fig, fullfile(outDir, '05_mtr1_mtr2_torque.png'), 'Resolution', 240);

% Align power to speed classification to compare accel/decel behavior.
[tSpdPower, spdRefP, rpmRateP, pm1P, pm2P] = alignManySignals({tSpeed, tSpeed, tPower, tPower}, {spdRefA, rpmRateSmooth, pm1A, pm2A});
maskAccelP = rpmRateP > minAccelRPMps & abs(spdRefP) > minMovingRPM;
maskDecelP = rpmRateP < minDecelRPMps & abs(spdRefP) > minMovingRPM;

pm1AccelMean = mean(pm1P(maskAccelP), 'omitnan');
pm2AccelMean = mean(pm2P(maskAccelP), 'omitnan');
pm1DecelMean = mean(pm1P(maskDecelP), 'omitnan');
pm2DecelMean = mean(pm2P(maskDecelP), 'omitnan');

fig = figure('Color','w','Name','Power During Accel and Decel');
tiledlayout(2,1);
nexttile;
plot(tSpdPower, pm1P, 'b', 'LineWidth', 1.0); hold on;
scatter(tSpdPower(maskAccelP), pm1P(maskAccelP), 8, 'g', 'filled');
scatter(tSpdPower(maskDecelP), pm1P(maskDecelP), 8, 'r', 'filled');
yline(0, 'k--'); grid on; ylabel('Mtr1 Pm (W)');
title(sprintf('Mtr1 Power During EPA Sections: accel mean %.2f W, decel mean %.2f W', pm1AccelMean, pm1DecelMean));
legend('Mtr1 Pm','Accel','Decel','Zero','Location','best');

nexttile;
plot(tSpdPower, pm2P, 'b', 'LineWidth', 1.0); hold on;
scatter(tSpdPower(maskAccelP), pm2P(maskAccelP), 8, 'g', 'filled');
scatter(tSpdPower(maskDecelP), pm2P(maskDecelP), 8, 'r', 'filled');
yline(0, 'k--'); grid on; xlabel('Time (s)'); ylabel('Mtr2 Pm (W)');
title(sprintf('Mtr2 Power During EPA Sections: accel mean %.2f W, decel mean %.2f W', pm2AccelMean, pm2DecelMean));
legend('Mtr2 Pm','Accel','Decel','Zero','Location','best');
exportgraphics(fig, fullfile(outDir, '06_power_during_accel_decel.png'), 'Resolution', 240);

%% ================= TRIAL 5: MECHANICAL COUPLING =================

metricsCouplingA = analyzeCouplingRun(tCoupRefA, coupRefA, tCoupFbA, coupFbA, maxAbsRPM, minMovingRPM, outDir, 'A');

if ~isempty(tCoupRefB) && ~isempty(tCoupFbB)
    metricsCouplingB = analyzeCouplingRun(tCoupRefB, coupRefB, tCoupFbB, coupFbB, maxAbsRPM, minMovingRPM, outDir, 'B');
else
    metricsCouplingB = struct('corr', NaN, 'rmse', NaN, 'gain', NaN, 'lagSec', NaN);
end

%% ================= OPTIONAL OPERATING POINT / EFFICIENCY VIEW =================

% This section builds a simple operating-point plot. If Vq exists, it also estimates
% efficiency using Pelec = 1.5*Vq*Iq and Pmech = Pm. If Vq does not exist, it plots
% speed vs torque colored by power instead.

if ~isempty(tTorque) && ~isempty(tPower) && ~isempty(tSpeed)
    [tOp, rpmOp, te1Op, pm1Op] = alignManySignals({tSpeed, tTorque, tPower}, {spdFbA, te1A, pm1A});
    opMask = isfinite(rpmOp) & isfinite(te1Op) & isfinite(pm1Op) & ...
             abs(rpmOp) <= maxAbsRPM & abs(te1Op) <= maxAbsTe & abs(pm1Op) <= maxAbsPm;
    tOp = tOp(opMask);
    rpmOp = rpmOp(opMask);
    te1Op = te1Op(opMask);
    pm1Op = pm1Op(opMask);

    fig = figure('Color','w','Name','Operating Points Colored by Mechanical Power');
    scatter(abs(rpmOp), abs(te1Op), 8, pm1Op, 'filled');
    grid on; xlabel('Speed |RPM|'); ylabel('Torque |Te| (N*m)');
    title('Mtr1 Operating Points Colored by Mechanical Power');
    xlim([0 rpmPlotMax]);
    cb = colorbar; ylabel(cb, 'Pm (W)');
    exportgraphics(fig, fullfile(outDir, '09_operating_points_colored_by_pm.png'), 'Resolution', 240);

    if makeEfficiencyIfPossible && ~isempty(tVq)
        [tEff, rpmEff, iqEff, vqEff, pmEff, teEff] = alignManySignals({tSpeed, tLoad, tVq, tPower, tTorque}, {spdFbA, iqFbA, vq, pm1A, te1A});
        Pelec = 1.5 .* vqEff .* iqEff;
        Pmech = pmEff;
        eta = Pmech ./ Pelec;
        effMask = isfinite(rpmEff) & isfinite(teEff) & isfinite(eta) & ...
                  abs(rpmEff) <= maxAbsRPM & abs(teEff) <= maxAbsTe & ...
                  Pelec > 10 & Pmech > 3 & eta > 0 & eta < 1.05;

        fig = figure('Color','w','Name','Optional Efficiency Scatter');
        scatter(abs(rpmEff(effMask)), abs(teEff(effMask)), 8, eta(effMask), 'filled');
        grid on; xlabel('Speed |RPM|'); ylabel('Torque |Te| (N*m)');
        title('Optional Mtr1 Efficiency Estimate, Colored by Efficiency');
        xlim([0 rpmPlotMax]);
        cb = colorbar; ylabel(cb, 'Efficiency'); caxis([0 1]); colormap(jet);
        exportgraphics(fig, fullfile(outDir, '10_optional_efficiency_scatter.png'), 'Resolution', 240);
    end
end

%% ================= SUMMARY TABLE =================

Metric = strings(0,1);
Value = zeros(0,1);
Units = strings(0,1);

[Metric, Value, Units] = addMetric(Metric, Value, Units, "Speed RMSE", speedRMSE, "RPM");
[Metric, Value, Units] = addMetric(Metric, Value, Units, "Speed MAE", speedMAE, "RPM");
[Metric, Value, Units] = addMetric(Metric, Value, Units, "Speed max abs error", speedMaxAbsErr, "RPM");
[Metric, Value, Units] = addMetric(Metric, Value, Units, "Speed tracking correlation", speedCorr, "unitless");
[Metric, Value, Units] = addMetric(Metric, Value, Units, "Iq RMSE", iqRMSE, "A");
[Metric, Value, Units] = addMetric(Metric, Value, Units, "Iq MAE", iqMAE, "A");
[Metric, Value, Units] = addMetric(Metric, Value, Units, "Iq max abs error", iqMaxAbsErr, "A");
[Metric, Value, Units] = addMetric(Metric, Value, Units, "Iq tracking correlation", iqCorr, "unitless");
[Metric, Value, Units] = addMetric(Metric, Value, Units, "Mtr1 positive Pm energy", energyM1_Pos_J, "J");
[Metric, Value, Units] = addMetric(Metric, Value, Units, "Mtr1 negative Pm energy", energyM1_Neg_J, "J");
[Metric, Value, Units] = addMetric(Metric, Value, Units, "Mtr2 positive Pm energy", energyM2_Pos_J, "J");
[Metric, Value, Units] = addMetric(Metric, Value, Units, "Mtr2 negative Pm energy", energyM2_Neg_J, "J");
[Metric, Value, Units] = addMetric(Metric, Value, Units, "Mtr1 accel mean Pm", pm1AccelMean, "W");
[Metric, Value, Units] = addMetric(Metric, Value, Units, "Mtr1 decel mean Pm", pm1DecelMean, "W");
[Metric, Value, Units] = addMetric(Metric, Value, Units, "Mtr2 accel mean Pm", pm2AccelMean, "W");
[Metric, Value, Units] = addMetric(Metric, Value, Units, "Mtr2 decel mean Pm", pm2DecelMean, "W");
[Metric, Value, Units] = addMetric(Metric, Value, Units, "Coupling A correlation", metricsCouplingA.corr, "unitless");
[Metric, Value, Units] = addMetric(Metric, Value, Units, "Coupling A RMSE", metricsCouplingA.rmse, "RPM");
[Metric, Value, Units] = addMetric(Metric, Value, Units, "Coupling A gain", metricsCouplingA.gain, "unitless");
[Metric, Value, Units] = addMetric(Metric, Value, Units, "Coupling A lag", metricsCouplingA.lagSec, "s");
[Metric, Value, Units] = addMetric(Metric, Value, Units, "Coupling B correlation", metricsCouplingB.corr, "unitless");
[Metric, Value, Units] = addMetric(Metric, Value, Units, "Coupling B RMSE", metricsCouplingB.rmse, "RPM");
[Metric, Value, Units] = addMetric(Metric, Value, Units, "Coupling B gain", metricsCouplingB.gain, "unitless");
[Metric, Value, Units] = addMetric(Metric, Value, Units, "Coupling B lag", metricsCouplingB.lagSec, "s");

summaryTable = table(Metric, Value, Units);
writetable(summaryTable, fullfile(outDir, 'Lab2_summary_metrics.csv'));

save(fullfile(outDir, 'Lab2_analysis_data.mat'));

fprintf('\nDone. Saved Lab 2 analysis to:\n%s\n', outDir);
fprintf('\nKey results:\n');
fprintf('  Speed RMSE: %.2f RPM\n', speedRMSE);
fprintf('  Iq RMSE: %.3f A\n', iqRMSE);
fprintf('  Coupling A correlation: %.4f\n', metricsCouplingA.corr);
fprintf('  Coupling A RMSE: %.2f RPM\n', metricsCouplingA.rmse);
fprintf('  Mtr1 accel mean Pm: %.2f W\n', pm1AccelMean);
fprintf('  Mtr1 decel mean Pm: %.2f W\n', pm1DecelMean);

%% ================= LOCAL FUNCTIONS =================

function [t, y] = readTrialSignal(baseDir, trialName, baseName)
    t = [];
    y = [];
    if strlength(trialName) == 0
        return;
    end
    filePath = fullfile(baseDir, char(trialName), [baseName '.csv']);
    [t, y] = readSingleSignalCsv(filePath);
end

function [tOut, yOut] = cropByTime(t, y, tStart, tEnd)
    tOut = [];
    yOut = [];
    if isempty(t) || isempty(y)
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

function [t1, y1, t2, y2] = localizePairTime(t1, y1, t2, y2)
    starts = [safeFirst(t1), safeFirst(t2)];
    t0 = min(starts(isfinite(starts)), [], 'omitnan');
    if isempty(t0) || ~isfinite(t0)
        return;
    end
    if ~isempty(t1)
        t1 = t1 - t0;
    end
    if ~isempty(t2)
        t2 = t2 - t0;
    end
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
        warning('Empty CSV: %s', filePath);
        return;
    end

    isNum = varfun(@isnumeric, T, 'OutputFormat', 'uniform');
    Tn = T(:, isNum);

    if width(Tn) == 0
        warning('No numeric columns in: %s', filePath);
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
        warning('No signal columns in: %s', filePath);
        return;
    end

    y = Tn{:, sigCols(1)};
    t = t(:);
    y = y(:);

    mask = isfinite(t) & isfinite(y);
    t = t(mask);
    y = y(mask);

    [t, ia] = unique(t, 'stable');
    y = y(ia);
end

function [tCommon, y1A, y2A] = alignTwoSignals(t1, y1, t2, y2)
    if isempty(t1) || isempty(t2) || isempty(y1) || isempty(y2)
        tCommon = [];
        y1A = [];
        y2A = [];
        return;
    end

    tStart = max([safeFirst(t1), safeFirst(t2)]);
    tEnd   = min([safeLast(t1),  safeLast(t2)]);

    if ~isfinite(tStart) || ~isfinite(tEnd) || tEnd <= tStart
        tCommon = [];
        y1A = [];
        y2A = [];
        warning('No overlapping region for signal pair.');
        return;
    end

    if numel(t1) >= numel(t2)
        tBase = t1;
    else
        tBase = t2;
    end
    tCommon = tBase(tBase >= tStart & tBase <= tEnd);

    y1A = interpKeepNaN(t1, y1, tCommon);
    y2A = interpKeepNaN(t2, y2, tCommon);
end

function varargout = alignManySignals(tCells, yCells)
    n = numel(tCells);
    tStart = -inf;
    tEnd = inf;

    for k = 1:n
        t = tCells{k};
        if isempty(t)
            varargout = cell(1, n+1);
            for q = 1:n+1
                varargout{q} = [];
            end
            return;
        end
        tStart = max(tStart, safeFirst(t));
        tEnd = min(tEnd, safeLast(t));
    end

    if ~isfinite(tStart) || ~isfinite(tEnd) || tEnd <= tStart
        varargout = cell(1, n+1);
        for q = 1:n+1
            varargout{q} = [];
        end
        warning('No overlapping region for multi-signal alignment.');
        return;
    end

    lengths = zeros(1,n);
    for k = 1:n
        lengths(k) = numel(tCells{k});
    end
    [~, idxDense] = max(lengths);
    tBase = tCells{idxDense};
    tCommon = tBase(tBase >= tStart & tBase <= tEnd);

    varargout = cell(1, n+1);
    varargout{1} = tCommon;
    for k = 1:n
        varargout{k+1} = interpKeepNaN(tCells{k}, yCells{k}, tCommon);
    end
end

function yq = interpKeepNaN(t, y, tq)
    good = isfinite(t) & isfinite(y);
    yq = nan(size(tq));
    if nnz(good) < 2
        return;
    end
    yq = interp1(t(good), y(good), tq, 'linear', NaN);
end

function dy = derivativeNonuniform(t, y)
    dy = nan(size(y));
    if numel(t) < 3
        return;
    end
    t = t(:);
    y = y(:);
    good = isfinite(t) & isfinite(y);
    if nnz(good) < 3
        return;
    end
    dy(good) = gradient(y(good)) ./ max(gradient(t(good)), eps);
end

function r = rmsNoNaN(x)
    x = x(isfinite(x));
    if isempty(x)
        r = NaN;
    else
        r = sqrt(mean(x.^2));
    end
end

function c = corrNoNaN(x, y)
    mask = isfinite(x) & isfinite(y);
    if nnz(mask) < 3
        c = NaN;
        return;
    end
    C = corrcoef(x(mask), y(mask));
    c = C(1,2);
end

function ePos = integratePositive(t, p)
    if isempty(t) || isempty(p)
        ePos = NaN;
        return;
    end
    mask = isfinite(t) & isfinite(p);
    t = t(mask);
    p = p(mask);
    if numel(t) < 2
        ePos = NaN;
        return;
    end
    ePos = trapz(t, max(p, 0));
end

function eNeg = integrateNegative(t, p)
    if isempty(t) || isempty(p)
        eNeg = NaN;
        return;
    end
    mask = isfinite(t) & isfinite(p);
    t = t(mask);
    p = p(mask);
    if numel(t) < 2
        eNeg = NaN;
        return;
    end
    eNeg = trapz(t, min(p, 0));
end

function metrics = analyzeCouplingRun(tRef, ref, tFb, fb, maxAbsRPM, minMovingRPM, outDir, tag)
    metrics = struct('corr', NaN, 'rmse', NaN, 'gain', NaN, 'lagSec', NaN);

    [tC, refA, fbA] = alignTwoSignals(tRef, ref, tFb, fb);
    if isempty(tC)
        warning('Skipping coupling run %s because no data was found.', tag);
        return;
    end

    valid = isfinite(refA) & isfinite(fbA) & abs(refA) <= maxAbsRPM & abs(fbA) <= maxAbsRPM;
    tC = tC(valid);
    refA = refA(valid);
    fbA = fbA(valid);

    moving = abs(refA) > minMovingRPM;
    if nnz(moving) < 5
        moving = true(size(refA));
    end

    err = fbA - refA;
    metrics.rmse = rmsNoNaN(err(moving));
    metrics.corr = corrNoNaN(refA(moving), fbA(moving));

    p = polyfit(refA(moving), fbA(moving), 1);
    metrics.gain = p(1);

    % Lag estimate using normalized xcorr on evenly sampled interpolation.
    try
        nGrid = min(5000, numel(tC));
        tq = linspace(min(tC), max(tC), nGrid).';
        refQ = interpKeepNaN(tC, refA, tq);
        fbQ  = interpKeepNaN(tC, fbA,  tq);
        good = isfinite(refQ) & isfinite(fbQ);
        refQ = refQ(good) - mean(refQ(good), 'omitnan');
        fbQ  = fbQ(good)  - mean(fbQ(good), 'omitnan');
        dt = median(diff(tq), 'omitnan');
        maxLagSamples = min(round(5/dt), floor(numel(refQ)/2));
        [xc, lags] = xcorr(fbQ, refQ, maxLagSamples, 'coeff');
        [~, idx] = max(xc);
        metrics.lagSec = lags(idx) * dt;
    catch
        metrics.lagSec = NaN;
    end

    fig = figure('Color','w','Name',['Coupling Run ' char(tag)]);
    tiledlayout(2,1);
    nexttile;
    plot(tC, refA, 'k--', 'LineWidth', 1.0); hold on;
    plot(tC, fbA, 'b', 'LineWidth', 1.0);
    grid on; ylabel('Speed (RPM)');
    title(sprintf('Mechanical Coupling Run %s: Corr %.4f, RMSE %.2f RPM, Gain %.4f', tag, metrics.corr, metrics.rmse, metrics.gain));
    legend('Mtr1 speed ref','Mtr2 speed feedback','Location','best');

    nexttile;
    scatter(refA(moving), fbA(moving), 8, 'filled'); hold on;
    xLine = linspace(min(refA(moving)), max(refA(moving)), 100);
    plot(xLine, xLine, 'k--', 'LineWidth', 1.0);
    plot(xLine, polyval(p, xLine), 'r', 'LineWidth', 1.0);
    grid on; xlabel('Mtr1 Speed Ref (RPM)'); ylabel('Mtr2 Speed Feedback (RPM)');
    title(sprintf('Coupling Scatter Run %s: fitted gain %.4f, estimated lag %.3f s', tag, metrics.gain, metrics.lagSec));
    legend('Data','Ideal 1:1','Fit','Location','best');

    exportgraphics(fig, fullfile(outDir, sprintf('07_coupling_run_%s.png', char(tag))), 'Resolution', 240);
end

function [Metric, Value, Units] = addMetric(Metric, Value, Units, metricName, metricValue, metricUnits)
    Metric(end+1,1) = metricName;
    Value(end+1,1) = metricValue;
    Units(end+1,1) = metricUnits;
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
