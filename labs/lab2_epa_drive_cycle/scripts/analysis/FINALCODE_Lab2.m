

%% ================================================================
%  LAB 2 FINAL SCRIPT
%  Mini FTP-75 model with smoothed RPM + doubled smoothed Motor 2 Iq
%
%  Host model:
%    mcb_pmsm_foc_host_model_dyno_f28069m_Lab2.slx
%
%  Creates:
%    FTP75_motorRPM_sig
%    FTP75_IqRef_A_sig
%
%  Important:
%    - Compresses full FTP-75 shape into a short mini model cycle.
%    - Smooths RPM and Iq commands.
%    - Adds 5 s zero-command delay before motion.
%    - No trial cropping needed when miniFtpModel = true.
%% ================================================================

clearvars -except ans
clc

%% ================================================================
%  0. MAIN USER KNOBS
%% ================================================================

% 0.00 = almost raw / aggressive
% 0.25 = light smoothing
% 0.50 = balanced
% 0.75 = smooth / safer
% 1.00 = very smooth / safest
smoothness = 1.00;
smoothness = min(max(smoothness, 0), 1);

% 1.00 = original load
% 2.00 = about double load
loadMagnitude = 2.00;

% Mini FTP-75 model control
miniFtpModel  = true;
miniDuration_s = 35;      % seconds of compressed FTP-style motion

% 5 seconds at zero RPM and zero Iq before trial starts
startDelay_s = 5.0;

% Leave false when using mini FTP model
shortenTrial = false;

% Optional crop settings, only used if miniFtpModel = false and shortenTrial = true
trialStart_s = 200;
trialEnd_s   = 260;

%% ================================================================
%  1. MOTOR / TARGET SETUP
%% ================================================================

PWM_frequency = 10e3;
T_pwm         = 1/PWM_frequency;

Ts            = T_pwm;
Ts_simulink   = T_pwm/2;
Ts_motor      = T_pwm/2;
Ts_inverter   = T_pwm/2;
Ts_speed      = 10*Ts;

dataType = 'single';

pmsm_motor1 = mcb_SetPMSMMotorParameters('Teknic2310P');
pmsm_motor1.PositionOffset = 0.1687;

pmsm_motor2 = mcb_SetPMSMMotorParameters('Teknic2310P');
pmsm_motor2.PositionOffset = 0.1655;

target = mcb_SetProcessorDetails('F28069M', PWM_frequency);

inverter_motor1 = mcb_SetInverterParameters('BoostXL-DRV8305');
inverter_motor2 = mcb_SetInverterParameters('BoostXL-DRV8305');

inverter_motor1.ADCOffsetCalibEnable = 1;
inverter_motor2.ADCOffsetCalibEnable = 1;

inverter_motor1.ADCGain = 1;
inverter_motor1.SPI_Gain_Setting = 0x5000;

inverter_motor2.ADCGain = 1;
inverter_motor2.SPI_Gain_Setting = 0x5000;

inverter_motor1.CtSensOffsetMax = 2500;
inverter_motor1.CtSensOffsetMin = 1500;

inverter_motor2.CtSensOffsetMax = 2500;
inverter_motor2.CtSensOffsetMin = 1500;

pmsm_motor1.N_base = mcb_getBaseSpeed(pmsm_motor1, inverter_motor1);
pmsm_motor2.N_base = mcb_getBaseSpeed(pmsm_motor2, inverter_motor2);

PU_System_motor1 = mcb_SetPUSystem(pmsm_motor1, inverter_motor1);
PU_System_motor2 = mcb_SetPUSystem(pmsm_motor2, inverter_motor2);

PI_params_motor1 = mcb.internal.SetControllerParameters( ...
    pmsm_motor1, inverter_motor1, PU_System_motor1, T_pwm, Ts, Ts_speed);

PI_params_motor1.delay_Currents = 0;
PI_params_motor1.delay_Position = 0;

PI_params_motor2 = mcb.internal.SetControllerParameters( ...
    pmsm_motor2, inverter_motor2, PU_System_motor2, T_pwm, Ts, Ts_speed);

PI_params_motor2.delay_Currents = 0;
PI_params_motor2.delay_Position = 0;

Kt      = pmsm_motor1.Kt;
J       = pmsm_motor1.J;
B       = pmsm_motor1.B;
BaseRPM = pmsm_motor1.N_base;

disp(table(Kt, J, B, BaseRPM))

%% ================================================================
%  2. FALLBACK SINE COMMANDS
%% ================================================================

Ts_cmd = 0.01;
Tper   = 10;
fHz    = 1/Tper;

t_sine = (0:Ts_cmd:70)';

SpeedRefRPM_sine = timeseries( ...
    single(1800 + 1200*sin(2*pi*fHz*t_sine)), t_sine);

DynoIqRef_A_sine = timeseries( ...
    single(2.0*sin(2*pi*fHz*t_sine)), t_sine);

%% ================================================================
%  3. LOAD FTP-75 AND CREATE MINI MODEL RPM COMMAND
%% ================================================================

ftp75Path = fullfile(matlabroot, ...
    'toolbox', 'autoblks', 'autoblksshared', 'cycleFTP75.mat');

S  = load(ftp75Path);
ts = S.cycleFTP75;

t = double(ts.Time(:));
v_kmh = double(ts.Data(:));

ok = isfinite(t) & isfinite(v_kmh);
t = t(ok);
v_kmh = v_kmh(ok);

[t, idx] = unique(t, 'stable');
v_kmh = v_kmh(idx);

%% ---------------- Mini FTP-75 model ----------------
if miniFtpModel
    t_full = t;
    v_kmh_full = v_kmh;

    tau_full = (t_full - t_full(1)) ./ (t_full(end) - t_full(1));

    dt_model = median(diff(t_full));
    t_model = (0:dt_model:miniDuration_s)';

    tau_model = t_model ./ t_model(end);

    v_kmh_model = interp1(tau_full, v_kmh_full, tau_model, 'linear', 'extrap');
    v_kmh_model = max(v_kmh_model, 0);

    t = t_model;
    v_kmh = v_kmh_model;

    fprintf('\nMini FTP-75 model enabled:\n');
    fprintf('  Original FTP duration = %.1f s\n', t_full(end));
    fprintf('  Mini model duration   = %.1f s\n', t(end));
    fprintf('  Start delay           = %.1f s\n', startDelay_s);
    fprintf('  Total expected run    = %.1f s\n\n', t(end) + startDelay_s);
end

v_mps = v_kmh / 3.6;

%% ---------------- Raw RPM command ----------------
motor_rpm_max = 4000;
v_norm = v_mps ./ max(v_mps);

motor_rpm_raw = motor_rpm_max .* v_norm;

dt_rpm = median(diff(t));

rpmSmooth_s          = 0.30 + 2.20*smoothness;
rpmPostSmooth_s      = 0.50 + 2.50*smoothness;
rpmSlew_RPM_per_s    = 3000 - 2200*smoothness;

rpmSmoothN     = max(5, round(rpmSmooth_s / dt_rpm));
rpmPostSmoothN = max(5, round(rpmPostSmooth_s / dt_rpm));

rpmStopBlend_mps = 0.75;

rpmStopGain = min(max(v_mps ./ rpmStopBlend_mps, 0), 1);
rpmStopGain = rpmStopGain.^2 .* (3 - 2*rpmStopGain);

motor_rpm_raw_enveloped = motor_rpm_raw .* rpmStopGain;

motor_rpm_smooth = smoothdata(motor_rpm_raw_enveloped, 'gaussian', rpmSmoothN);

motor_rpm_slew = zeros(size(motor_rpm_smooth));
motor_rpm_slew(1) = motor_rpm_smooth(1);

for k = 2:length(motor_rpm_smooth)
    dt_k = t(k) - t(k-1);

    if ~isfinite(dt_k) || dt_k <= 0
        dt_k = dt_rpm;
    end

    dRPM_allowed = rpmSlew_RPM_per_s * dt_k;
    dRPM_request = motor_rpm_smooth(k) - motor_rpm_slew(k-1);

    dRPM_limited = max(min(dRPM_request, dRPM_allowed), -dRPM_allowed);

    motor_rpm_slew(k) = motor_rpm_slew(k-1) + dRPM_limited;
end

motor_rpm_cmd = smoothdata(motor_rpm_slew, 'gaussian', rpmPostSmoothN);

motor_rpm_cmd = min(max(motor_rpm_cmd, 0), motor_rpm_max);
motor_rpm_cmd(~isfinite(motor_rpm_cmd)) = 0;

fprintf('\nFTP-75 RPM command created:\n');
fprintf('  Command duration      = %.1f s\n', t(end));
fprintf('  Max speed             = %.2f km/h\n', max(v_kmh));
fprintf('  Max raw RPM           = %.1f RPM\n', max(motor_rpm_raw));
fprintf('  Max final RPM         = %.1f RPM\n', max(motor_rpm_cmd));
fprintf('  Smoothness gauge      = %.2f\n', smoothness);
fprintf('  RPM smoothing window  = %.2f s\n', rpmSmooth_s);
fprintf('  RPM post smoothing    = %.2f s\n', rpmPostSmooth_s);
fprintf('  RPM stop blend speed  = %.2f m/s\n', rpmStopBlend_mps);
fprintf('  RPM slew-rate limit   = %.1f RPM/s\n\n', rpmSlew_RPM_per_s);

%% ================================================================
%  4. FINAL LAB 2 MOTOR 2 IQ COMMAND
%% ================================================================

m_vehicle_kg = 1350;
r_wheel_m    = 0.30;
gearRatio    = 8.0;
eta_drive    = 0.90;

A_road_N      = 120;
B_road_Ns_m   = 2.0;
C_road_Ns2_m2 = 0.40;

Iq_peak_A          = 7.0;

Iq_posTarget_A     = 3.0 * loadMagnitude;
Iq_negTarget_A     = 3.0 * loadMagnitude;

roadLoadGain       = 1.00;
inertiaGain        = 0.45;
inertiaForceCap_N  = 300;

speedSmooth_s      = 0.50 + 2.00*smoothness;
accelSmooth_s      = 0.60 + 2.40*smoothness;
iqSmooth_s         = 0.10 + 0.90*smoothness;
iqPostSmooth_s     = 0.35 + 1.50*smoothness;

Iq_slew_A_per_s    = 4.0 - 3.0*smoothness;
accelDeadband      = 0.010 + 0.030*smoothness;

t_iq = t(:);
v_iq = v_mps(:);

dt = median(diff(t_iq));

speedSmoothN    = max(5, round(speedSmooth_s / dt));
accelSmoothN    = max(5, round(accelSmooth_s / dt));
iqSmoothN       = max(5, round(iqSmooth_s / dt));
iqPostSmoothN   = max(5, round(iqPostSmooth_s / dt));

v_smooth = smoothdata(v_iq, 'gaussian', speedSmoothN);

iqStopBlend_mps = 0.60;

movingGain = min(max(v_smooth ./ iqStopBlend_mps, 0), 1);
movingGain = movingGain.^2 .* (3 - 2*movingGain);

accel_mps2 = gradient(v_smooth, t_iq);
accel_mps2 = smoothdata(accel_mps2, 'gaussian', accelSmoothN);

accel_for_force = accel_mps2;
accel_for_force(abs(accel_for_force) < accelDeadband) = 0;

F_roadload_N = A_road_N + B_road_Ns_m .* v_smooth + C_road_Ns2_m2 .* v_smooth.^2;
F_roadload_N = roadLoadGain .* F_roadload_N .* movingGain;

F_inertia_raw_N = m_vehicle_kg .* accel_for_force;
F_inertia_raw_N = min(max(F_inertia_raw_N, -inertiaForceCap_N), inertiaForceCap_N);

F_inertia_N = inertiaGain .* F_inertia_raw_N .* movingGain;

F_total_N = F_roadload_N + F_inertia_N;

T_roadload_motor_Nm = (F_roadload_N .* r_wheel_m) ./ (gearRatio .* eta_drive);
T_inertia_motor_Nm  = (F_inertia_N  .* r_wheel_m) ./ (gearRatio .* eta_drive);
T_total_motor_Nm    = (F_total_N    .* r_wheel_m) ./ (gearRatio .* eta_drive);

Kt_used = Kt;

Iq_equiv_A = T_total_motor_Nm ./ Kt_used;

positiveMask = Iq_equiv_A > 0;
negativeMask = Iq_equiv_A < 0;

posVals = abs(Iq_equiv_A(positiveMask));
negVals = abs(Iq_equiv_A(negativeMask));

if isempty(posVals)
    posRef = 1;
else
    posRef = max(prctile(posVals, 95), 1e-6);
end

if isempty(negVals)
    negRef = 1;
else
    negRef = max(prctile(negVals, 95), 1e-6);
end

Iq_raw_A = zeros(size(Iq_equiv_A));

Iq_raw_A(positiveMask) = Iq_posTarget_A .* Iq_equiv_A(positiveMask) ./ posRef;
Iq_raw_A(negativeMask) = Iq_negTarget_A .* Iq_equiv_A(negativeMask) ./ negRef;

Iq_raw_A = Iq_peak_A .* tanh(Iq_raw_A ./ Iq_peak_A);
Iq_raw_A = Iq_raw_A .* movingGain;

Iq_smooth_A = smoothdata(Iq_raw_A, 'gaussian', iqSmoothN);

Iq_slew_A = zeros(size(Iq_smooth_A));
Iq_slew_A(1) = Iq_smooth_A(1);

for k = 2:length(Iq_smooth_A)
    dt_k = t_iq(k) - t_iq(k-1);

    if ~isfinite(dt_k) || dt_k <= 0
        dt_k = dt;
    end

    dIq_allowed = Iq_slew_A_per_s * dt_k;
    dIq_request = Iq_smooth_A(k) - Iq_slew_A(k-1);

    dIq_limited = max(min(dIq_request, dIq_allowed), -dIq_allowed);

    Iq_slew_A(k) = Iq_slew_A(k-1) + dIq_limited;
end

Iq_cmd_A = smoothdata(Iq_slew_A, 'gaussian', iqPostSmoothN);

Iq_cmd_A = min(max(Iq_cmd_A, -Iq_peak_A), Iq_peak_A);
Iq_cmd_A(~isfinite(Iq_cmd_A)) = 0;

fprintf('\nMini FTP-75 Iq command created:\n');
fprintf('  Smoothness gauge         = %.2f\n', smoothness);
fprintf('  Load magnitude gauge     = %.2f\n', loadMagnitude);
fprintf('  Kt used                  = %.4f N*m/A\n', Kt_used);
fprintf('  Iq clamp                 = +/- %.2f A\n', Iq_peak_A);
fprintf('  Iq slew-rate limit       = %.2f A/s\n', Iq_slew_A_per_s);
fprintf('  Max Iq command           = %.3f A\n', max(Iq_cmd_A));
fprintf('  Min Iq command           = %.3f A\n', min(Iq_cmd_A));

%% ================================================================
%  4B. OPTIONAL SHORTEN TRIAL AFTER SMOOTHING
%      Usually OFF when miniFtpModel = true.
%% ================================================================

if shortenTrial && ~miniFtpModel
    keepTrial = (t_iq >= trialStart_s) & (t_iq <= trialEnd_s);

    if nnz(keepTrial) < 10
        error('Short trial window is too small. Check trialStart_s and trialEnd_s.');
    end

    t_ftp75_original = t_iq(keepTrial);

    t_short = t_iq(keepTrial);
    t_short = t_short - t_short(1);

    t_iq = t_short;
    t   = t_short;

    v_kmh = v_kmh(keepTrial);
    v_mps = v_mps(keepTrial);
    v_iq  = v_iq(keepTrial);
    v_smooth = v_smooth(keepTrial);

    motor_rpm_raw = motor_rpm_raw(keepTrial);
    motor_rpm_raw_enveloped = motor_rpm_raw_enveloped(keepTrial);
    motor_rpm_smooth = motor_rpm_smooth(keepTrial);
    motor_rpm_slew = motor_rpm_slew(keepTrial);
    motor_rpm_cmd = motor_rpm_cmd(keepTrial);

    accel_mps2 = accel_mps2(keepTrial);

    F_roadload_N = F_roadload_N(keepTrial);
    F_inertia_N  = F_inertia_N(keepTrial);
    F_total_N    = F_total_N(keepTrial);

    T_roadload_motor_Nm = T_roadload_motor_Nm(keepTrial);
    T_inertia_motor_Nm  = T_inertia_motor_Nm(keepTrial);
    T_total_motor_Nm    = T_total_motor_Nm(keepTrial);

    Iq_raw_A    = Iq_raw_A(keepTrial);
    Iq_smooth_A = Iq_smooth_A(keepTrial);
    Iq_slew_A   = Iq_slew_A(keepTrial);
    Iq_cmd_A    = Iq_cmd_A(keepTrial);

    fprintf('\nTrial shortened after smoothing:\n');
    fprintf('  Original FTP window = %.1f to %.1f s\n', trialStart_s, trialEnd_s);
    fprintf('  FTP data duration   = %.1f s\n', t_iq(end));
    fprintf('  Samples kept        = %d\n\n', nnz(keepTrial));
else
    t_ftp75_original = t_iq;
end

%% ================================================================
%  4C. ADD 5 SECOND START DELAY
%% ================================================================

if startDelay_s > 0
    dt_cmd = median(diff(t_iq));

    t_delay = (0:dt_cmd:(startDelay_s - dt_cmd))';
    nDelay = numel(t_delay);

    t_iq = [t_delay; t_iq + startDelay_s];
    t   = t_iq;

    motor_rpm_raw            = [zeros(nDelay,1); motor_rpm_raw];
    motor_rpm_raw_enveloped  = [zeros(nDelay,1); motor_rpm_raw_enveloped];
    motor_rpm_smooth         = [zeros(nDelay,1); motor_rpm_smooth];
    motor_rpm_slew           = [zeros(nDelay,1); motor_rpm_slew];
    motor_rpm_cmd            = [zeros(nDelay,1); motor_rpm_cmd];

    Iq_raw_A    = [zeros(nDelay,1); Iq_raw_A];
    Iq_smooth_A = [zeros(nDelay,1); Iq_smooth_A];
    Iq_slew_A   = [zeros(nDelay,1); Iq_slew_A];
    Iq_cmd_A    = [zeros(nDelay,1); Iq_cmd_A];

    v_kmh    = [zeros(nDelay,1); v_kmh];
    v_mps    = [zeros(nDelay,1); v_mps];
    v_iq     = [zeros(nDelay,1); v_iq];
    v_smooth = [zeros(nDelay,1); v_smooth];

    accel_mps2 = [zeros(nDelay,1); accel_mps2];

    F_roadload_N = [zeros(nDelay,1); F_roadload_N];
    F_inertia_N  = [zeros(nDelay,1); F_inertia_N];
    F_total_N    = [zeros(nDelay,1); F_total_N];

    T_roadload_motor_Nm = [zeros(nDelay,1); T_roadload_motor_Nm];
    T_inertia_motor_Nm  = [zeros(nDelay,1); T_inertia_motor_Nm];
    T_total_motor_Nm    = [zeros(nDelay,1); T_total_motor_Nm];

    fprintf('\nStart delay added:\n');
    fprintf('  Delay duration       = %.2f s\n', startDelay_s);
    fprintf('  Final trial duration = %.2f s\n\n', t_iq(end));
end

fprintf('Final command summary:\n');
fprintf('  Final duration            = %.1f s\n', t_iq(end));
fprintf('  Max final RPM             = %.1f RPM\n', max(motor_rpm_cmd));
fprintf('  Max final Iq command      = %.3f A\n', max(Iq_cmd_A));
fprintf('  Min final Iq command      = %.3f A\n', min(Iq_cmd_A));
fprintf('  Percent positive samples  = %.1f %%\n', 100*mean(Iq_cmd_A > 0));
fprintf('  Percent negative samples  = %.1f %%\n', 100*mean(Iq_cmd_A < 0));
fprintf('  Percent near-zero samples = %.1f %%\n\n', 100*mean(abs(Iq_cmd_A) < 1e-3));

%% ================================================================
%  4D. FINAL SIMULINK FROM WORKSPACE SIGNALS
%% ================================================================

FTP75_motorRPM_sig.time = t_iq;
FTP75_motorRPM_sig.signals.values = single(motor_rpm_cmd);
FTP75_motorRPM_sig.signals.dimensions = 1;

FTP75_motorRPM_ts = timeseries(single(motor_rpm_cmd), t_iq);
FTP75_motorRPM_ts.Name = "FTP75_motorRPM";

FTP75_IqRef_A_sig.time = t_iq;
FTP75_IqRef_A_sig.signals.values = single(Iq_cmd_A);
FTP75_IqRef_A_sig.signals.dimensions = 1;

FTP75_IqRef_A_ts = timeseries(single(Iq_cmd_A), t_iq);
FTP75_IqRef_A_ts.Name = "FTP75_IqRef_A";

%% ================================================================
%  5. PLOT LAB 2 COMMANDS
%% ================================================================

figure('Name','Lab 2 Mini FTP-75 Rounded RPM and Doubled Load Command','Color','w');
tiledlayout(8,1);

nexttile
plot(t_iq, v_kmh, 'LineWidth', 1.2);
grid on;
ylabel('km/h');
title(sprintf('Mini FTP-75 Model | Smoothness = %.2f | Load Magnitude = %.2f', ...
    smoothness, loadMagnitude));
xlim([0 t_iq(end)]);

nexttile
plot(t_iq, motor_rpm_raw, 'LineWidth', 1.0);
hold on;
plot(t_iq, motor_rpm_cmd, 'LineWidth', 1.4);
hold off;
grid on;
ylabel('RPM');
title('Raw vs Rounded Final Motor Speed Command');
legend('Raw RPM', 'Final RPM', 'Location', 'best');
xlim([0 t_iq(end)]);

nexttile
dRPM_dt = [0; diff(motor_rpm_cmd)./diff(t_iq)];
plot(t_iq, dRPM_dt, 'LineWidth', 1.2);
hold on;
yline(rpmSlew_RPM_per_s, '--');
yline(-rpmSlew_RPM_per_s, '--');
hold off;
grid on;
ylabel('RPM/s');
title('Final RPM Slew Rate');
xlim([0 t_iq(end)]);

nexttile
plot(t_iq, accel_mps2, 'LineWidth', 1.2);
yline(0, '--');
grid on;
ylabel('m/s^2');
title('Smoothed Vehicle Acceleration Used for Load');
xlim([0 t_iq(end)]);

nexttile
plot(t_iq, F_roadload_N, 'LineWidth', 1.2);
hold on;
plot(t_iq, F_inertia_N, 'LineWidth', 1.0);
plot(t_iq, F_total_N, 'LineWidth', 1.2);
yline(0, '--');
hold off;
grid on;
ylabel('N');
title('Road Load + Preserved Positive/Negative Inertia');
legend('Road load', 'Inertia', 'Net total', 'Zero', 'Location', 'best');
xlim([0 t_iq(end)]);

nexttile
plot(t_iq, T_total_motor_Nm, 'LineWidth', 1.2);
yline(0, '--');
grid on;
ylabel('N*m');
title('Vehicle-Equivalent Motor Shaft Torque Command');
xlim([0 t_iq(end)]);

nexttile
plot(t_iq, Iq_raw_A, 'LineWidth', 1.0);
hold on;
plot(t_iq, Iq_smooth_A, 'LineWidth', 1.0);
plot(t_iq, Iq_cmd_A, 'LineWidth', 1.4);
yline(0, '--');
hold off;
grid on;
ylabel('Mtr2 IqRef A');
title('Raw vs Smoothness-Filtered vs Rounded Final Motor 2 Iq Command');
legend('Raw scaled Iq', 'Smoothness filtered', 'Final Iq', 'Zero', 'Location', 'best');
xlim([0 t_iq(end)]);
ylim([-Iq_peak_A - 0.5, Iq_peak_A + 0.5]);

nexttile
dIq_dt = [0; diff(Iq_cmd_A)./diff(t_iq)];
plot(t_iq, dIq_dt, 'LineWidth', 1.2);
hold on;
yline(Iq_slew_A_per_s, '--');
yline(-Iq_slew_A_per_s, '--');
hold off;
grid on;
ylabel('A/s');
xlabel('Time (s)');
title('Final Iq Slew Rate');
xlim([0 t_iq(end)]);
ylim([-1.2*Iq_slew_A_per_s, 1.2*Iq_slew_A_per_s]);

%% ================================================================
%  6. OPEN LAB 2 HOST MODEL AND SET FTP-75 BLOCKS/SWITCHES ROBUSTLY
%% ================================================================

modelName = 'mcb_pmsm_foc_host_model_dyno_f28069m_Lab_2_GITHUB';

candidateModelFiles = {
    fullfile('C:\CourseDev\DualMotorDynoUsingC2000ProcessorsExample', [modelName '.slx'])
    fullfile('C:\CourseDev\DMD', [modelName '.slx'])
    fullfile(pwd, [modelName '.slx'])
};

modelFile = '';

for kk = 1:numel(candidateModelFiles)
    if isfile(candidateModelFiles{kk})
        modelFile = candidateModelFiles{kk};
        break;
    end
end

if isempty(modelFile)
    error('Could not find %s.slx. Put it in C:\CourseDev\DualMotorDynoUsingC2000ProcessorsExample or C:\CourseDev\DMD.', modelName);
end

fprintf('\nOpening Lab 2 host model:\n  %s\n', modelFile);

open_system(modelFile);
load_system(modelFile);

[~, loadedModelName, ~] = fileparts(modelFile);

%% ---------------- FIND AND SET FROM WORKSPACE BLOCKS ----------------
fromWsBlocks = find_system(loadedModelName, ...
    'LookUnderMasks', 'all', ...
    'FollowLinks', 'on', ...
    'BlockType', 'FromWorkspace');

fprintf('\nFound From Workspace blocks:\n');
for k = 1:numel(fromWsBlocks)
    fprintf('  %d: %s\n', k, fromWsBlocks{k});
end

rpmBlock = '';
iqBlock  = '';

for k = 1:numel(fromWsBlocks)
    blk = fromWsBlocks{k};

    blkName = string(get_param(blk, 'Name'));

    varName = "";
    try
        varName = string(get_param(blk, 'VariableName'));
    catch
    end

    searchText = lower(char(string(blk) + " " + blkName + " " + varName));

    if contains(searchText, lower('FTP75_motorRPM_sig'))
        rpmBlock = blk;
    end

    if contains(searchText, lower('FTP75_IqRef_A_sig'))
        iqBlock = blk;
    end
end

if isempty(rpmBlock)
    warning('Could not automatically find the FTP75_motorRPM_sig From Workspace block.');
else
    set_param(rpmBlock, 'VariableName', 'FTP75_motorRPM_sig');
    fprintf('\nSet RPM From Workspace block:\n  %s\n', rpmBlock);
end

if isempty(iqBlock)
    warning('Could not automatically find the FTP75_IqRef_A_sig From Workspace block.');
else
    set_param(iqBlock, 'VariableName', 'FTP75_IqRef_A_sig');
    fprintf('\nSet Iq From Workspace block:\n  %s\n', iqBlock);
end

%% ---------------- FIND MANUAL SWITCHES ----------------
switchBlocks = find_system(loadedModelName, ...
    'LookUnderMasks', 'all', ...
    'FollowLinks', 'on', ...
    'BlockType', 'ManualSwitch');

fprintf('\nFound Manual Switch blocks:\n');
for k = 1:numel(switchBlocks)
    fprintf('  %d: %s\n', k, switchBlocks{k});
end

%% ---------------- TRACE SWITCH INPUTS UPSTREAM ----------------
rpmSwitch = '';
iqSwitch  = '';

rpmInputIndex = NaN;
iqInputIndex  = NaN;

for k = 1:numel(switchBlocks)
    swBlk = switchBlocks{k};
    ph = get_param(swBlk, 'PortHandles');
    inports = ph.Inport;

    fprintf('\nSwitch: %s\n', swBlk);

    for p = 1:numel(inports)
        upstreamText = traceUpstreamText(inports(p), 12);
        upstreamLower = lower(char(upstreamText));

        fprintf('  Input %d upstream contains:\n    %s\n', p, char(upstreamText));

        if contains(upstreamLower, lower('FTP75_motorRPM_sig'))
            rpmSwitch = swBlk;
            rpmInputIndex = p;
        end

        if contains(upstreamLower, lower('FTP75_IqRef_A_sig'))
            iqSwitch = swBlk;
            iqInputIndex = p;
        end
    end
end

%% ---------------- SET RPM SWITCH TO FTP75 MOTOR RPM ----------------
if isempty(rpmSwitch)
    warning('Could not find RPM Manual Switch by upstream tracing.');

    try
        set_param([loadedModelName '/Manual Switch'], 'sw', '1');
        fprintf('\nFallback set RPM switch: Manual Switch -> lower input.\n');
    catch
        warning('Fallback RPM switch set failed. Set it manually to the lower FTP75_motorRPM_sig input.');
    end
else
    if rpmInputIndex == 1
        set_param(rpmSwitch, 'sw', '0');
    elseif rpmInputIndex == 2
        set_param(rpmSwitch, 'sw', '1');
    else
        warning('Could not determine RPM FTP75 input index.');
    end

    fprintf('\nRPM switch set to FTP75_motorRPM_sig:\n');
    fprintf('  Switch: %s\n', rpmSwitch);
    fprintf('  FTP75 input index: %d\n', rpmInputIndex);
end

%% ---------------- SET IQ SWITCH TO FTP75 IQ ----------------
if isempty(iqSwitch)
    warning('Could not find Iq Manual Switch by upstream tracing.');

    try
        set_param([loadedModelName '/Manual Switch1'], 'sw', '1');
        fprintf('\nFallback set Iq switch: Manual Switch1 -> upper input.\n');
    catch
        warning('Fallback Iq switch set failed. Set it manually to the upper FTP75_IqRef_A_sig input.');
    end
else
    if iqInputIndex == 1
        set_param(iqSwitch, 'sw', '1');
    elseif iqInputIndex == 2
        set_param(iqSwitch, 'sw', '0');
    else
        warning('Could not determine Iq FTP75 input index.');
    end

    fprintf('\nIq switch set to FTP75_IqRef_A_sig:\n');
    fprintf('  Switch: %s\n', iqSwitch);
    fprintf('  FTP75 input index: %d\n', iqInputIndex);
end

%% ---------------- OPTIONAL: FORCE FTP75 IQ GAIN TO 1 ----------------
gainBlocks = find_system(loadedModelName, ...
    'LookUnderMasks', 'all', ...
    'FollowLinks', 'on', ...
    'BlockType', 'Gain');

for k = 1:numel(gainBlocks)
    gainBlk = gainBlocks{k};
    ph = get_param(gainBlk, 'PortHandles');

    if ~isempty(ph.Inport)
        upstreamText = traceUpstreamText(ph.Inport(1), 12);
        if contains(lower(char(upstreamText)), lower('FTP75_IqRef_A_sig'))
            set_param(gainBlk, 'Gain', '1');
            fprintf('\nSet FTP75 Iq Gain block to 1:\n  %s\n', gainBlk);
        end
    end
end

%% ---------------- SAVE MODEL ----------------
save_system(loadedModelName);

fprintf('\nLab 2 host model configured.\n');
fprintf('  Model opened: %s\n', loadedModelName);
fprintf('  RPM source should now be FTP75_motorRPM_sig.\n');
fprintf('  Iq source should now be FTP75_IqRef_A_sig.\n');
fprintf('  Visually verify switches before running hardware.\n\n');

%% ================================================================
%  LOCAL HELPER FUNCTION
%% ================================================================

function txt = traceUpstreamText(portH, maxDepth)
    if nargin < 2
        maxDepth = 8;
    end

    txt = "";

    if maxDepth <= 0 || portH == -1
        return;
    end

    try
        lineH = get_param(portH, 'Line');
    catch
        return;
    end

    if lineH == -1
        return;
    end

    try
        srcPortH = get_param(lineH, 'SrcPortHandle');
        srcBlk   = get_param(srcPortH, 'Parent');
    catch
        return;
    end

    blkName = "";
    blkType = "";
    varName = "";

    try
        blkName = string(get_param(srcBlk, 'Name'));
    catch
    end

    try
        blkType = string(get_param(srcBlk, 'BlockType'));
    catch
    end

    try
        varName = string(get_param(srcBlk, 'VariableName'));
    catch
    end

    txt = txt + " " + string(srcBlk) + ...
          " " + blkName + ...
          " " + blkType + ...
          " " + varName;

    try
        phSrc = get_param(srcBlk, 'PortHandles');
        srcInports = phSrc.Inport;

        for ii = 1:numel(srcInports)
            txt = txt + " " + traceUpstreamText(srcInports(ii), maxDepth - 1);
        end
    catch
    end
end

