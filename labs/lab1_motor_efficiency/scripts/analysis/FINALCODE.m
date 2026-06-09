% Model        : PMSM Field Oriented Control
% Description  : Motor 1 Efficiency Map Setup - Short Dense Higher Load Sweep
% File name    : mcb_pmsm_foc_qep_dyno_f28069m_data_effmap_setup.m
%
% PURPOSE:
%   Create cleaner efficiency-map data using fixed RPM/load dwell points.
%   Short run, denser RPM/load coverage, higher-load points included.
%
% CREATES:
%   SpeedRefRPM_effmap
%   DynoIqRef_A_effmap

clear; clc;

%% ============================================================
%  PROJECT FOLDER
% ============================================================

baseDir = 'C:\CourseDev\DMD';

if exist(baseDir, 'dir')
    cd(baseDir);
else
    error('Base directory does not exist: %s', baseDir);
end

%% ============================================================
%  SIMULATION PARAMETERS
% ============================================================

PWM_frequency  = 10e3;
T_pwm          = 1/PWM_frequency;

Ts             = T_pwm;
Ts_simulink    = T_pwm/2;
Ts_motor       = T_pwm/2;
Ts_inverter    = T_pwm/2;
Ts_speed       = 10*Ts;

dataType = 'single';

%% ============================================================
%  SYSTEM PARAMETERS
% ============================================================

pmsm_motor1 = mcb_SetPMSMMotorParameters('Teknic2310P');
pmsm_motor1.PositionOffset = 0.1687;

pmsm_motor2 = mcb_SetPMSMMotorParameters('Teknic2310P');
pmsm_motor2.PositionOffset = 0.1655;

%% ============================================================
%  TARGET AND INVERTER PARAMETERS
% ============================================================

target = mcb_SetProcessorDetails('F28069M', PWM_frequency);

inverter_motor1 = mcb_SetInverterParameters('BoostXL-DRV8305');
inverter_motor2 = mcb_SetInverterParameters('BoostXL-DRV8305');

%% ============================================================
%  CALIBRATION SECTION
% ============================================================

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

%% ============================================================
%  DERIVE CHARACTERISTICS
% ============================================================

pmsm_motor1.N_base = mcb_getBaseSpeed(pmsm_motor1, inverter_motor1);
pmsm_motor2.N_base = mcb_getBaseSpeed(pmsm_motor2, inverter_motor2);

%% ============================================================
%  PU SYSTEM DETAILS
% ============================================================

PU_System_motor1 = mcb_SetPUSystem(pmsm_motor1, inverter_motor1);
PU_System_motor2 = mcb_SetPUSystem(pmsm_motor2, inverter_motor2);

%% ============================================================
%  CONTROLLER DESIGN
% ============================================================

PI_params_motor1 = mcb.internal.SetControllerParameters( ...
    pmsm_motor1, inverter_motor1, PU_System_motor1, T_pwm, Ts, Ts_speed);

PI_params_motor1.delay_Currents = 0;
PI_params_motor1.delay_Position = 0;

PI_params_motor2 = mcb.internal.SetControllerParameters( ...
    pmsm_motor2, inverter_motor2, PU_System_motor2, T_pwm, Ts, Ts_speed);

PI_params_motor2.delay_Currents = 0;
PI_params_motor2.delay_Position = 0;

%% ============================================================
%  DISPLAY MODEL VARIABLES
% ============================================================

disp(pmsm_motor1);
disp(pmsm_motor2);
disp(inverter_motor1);
disp(inverter_motor2);
disp(target);
disp(PU_System_motor1);
disp(PU_System_motor2);

Kt      = pmsm_motor1.Kt;
J       = pmsm_motor1.J;
B       = pmsm_motor1.B;
BaseRPM = pmsm_motor1.N_base;

disp(table(Kt, J, B, BaseRPM));

%% ============================================================
%  MOTOR 1 EFFICIENCY MAP COMMAND PROFILE
% ============================================================

Ts_profile = 0.01;

maxRPM = min(4000, pmsm_motor1.N_base);

% Denser RPM coverage
rpmLevels = [600 900 1200 1500 1800 2100 2400 2700 ...
             3000 3300 3600 3900 maxRPM];

% Higher load coverage added
loadIqLevels_A = [1.5 2.3 3.2 4.0 4.6];

% Short timing, but enough dwell to keep useful samples
startDelay_s        = 1.0;
speedRamp_s         = 0.22;
speedSettle_s       = 0.18;
loadRamp_s          = 0.09;
loadSettle_s        = 0.08;
loadHold_s          = 0.22;
betweenLoadZero_s   = 0.035;
betweenSpeedZero_s  = 0.05;
shutdownRamp_s      = 0.50;
finalZeroHold_s     = 0.50;

% Approx total:
% 13 speeds x 5 loads = 65 operating points
% about 33 to 36 seconds total

useCosineTransitions = true;

%% ============================================================
%  BUILD PROFILE
% ============================================================

t = [];
rpmCmd = [];
iqCmd  = [];

currentTime = 0;
currentRPM  = 0;
currentIq   = 0;

% Start delay: motor commanded off
[t, rpmCmd, iqCmd, currentTime, currentRPM, currentIq] = appendHold( ...
    t, rpmCmd, iqCmd, currentTime, currentRPM, currentIq, ...
    startDelay_s, Ts_profile);

for r = 1:numel(rpmLevels)

    targetRPM = rpmLevels(r);

    % Ramp to RPM with zero load
    [t, rpmCmd, iqCmd, currentTime, currentRPM, currentIq] = appendTransition( ...
        t, rpmCmd, iqCmd, currentTime, currentRPM, currentIq, ...
        targetRPM, 0, speedRamp_s, Ts_profile, useCosineTransitions);

    % Settle at RPM with zero load
    [t, rpmCmd, iqCmd, currentTime, currentRPM, currentIq] = appendHold( ...
        t, rpmCmd, iqCmd, currentTime, currentRPM, currentIq, ...
        speedSettle_s, Ts_profile);

    for q = 1:numel(loadIqLevels_A)

        targetIq = loadIqLevels_A(q);

        % Apply fixed load
        [t, rpmCmd, iqCmd, currentTime, currentRPM, currentIq] = appendTransition( ...
            t, rpmCmd, iqCmd, currentTime, currentRPM, currentIq, ...
            targetRPM, targetIq, loadRamp_s, Ts_profile, useCosineTransitions);

        % Let current/torque settle
        [t, rpmCmd, iqCmd, currentTime, currentRPM, currentIq] = appendHold( ...
            t, rpmCmd, iqCmd, currentTime, currentRPM, currentIq, ...
            loadSettle_s, Ts_profile);

        % Useful fixed operating point
        [t, rpmCmd, iqCmd, currentTime, currentRPM, currentIq] = appendHold( ...
            t, rpmCmd, iqCmd, currentTime, currentRPM, currentIq, ...
            loadHold_s, Ts_profile);

        % Return to zero load
        [t, rpmCmd, iqCmd, currentTime, currentRPM, currentIq] = appendTransition( ...
            t, rpmCmd, iqCmd, currentTime, currentRPM, currentIq, ...
            targetRPM, 0, loadRamp_s, Ts_profile, useCosineTransitions);

        % Short zero-load pause before next load level
        [t, rpmCmd, iqCmd, currentTime, currentRPM, currentIq] = appendHold( ...
            t, rpmCmd, iqCmd, currentTime, currentRPM, currentIq, ...
            betweenLoadZero_s, Ts_profile);
    end

    % Short zero-load pause before next speed
    [t, rpmCmd, iqCmd, currentTime, currentRPM, currentIq] = appendHold( ...
        t, rpmCmd, iqCmd, currentTime, currentRPM, currentIq, ...
        betweenSpeedZero_s, Ts_profile);
end

%% ============================================================
%  KILL MOTOR AT END
% ============================================================

[t, rpmCmd, iqCmd, currentTime, currentRPM, currentIq] = appendTransition( ...
    t, rpmCmd, iqCmd, currentTime, currentRPM, currentIq, ...
    0, 0, shutdownRamp_s, Ts_profile, useCosineTransitions);

[t, rpmCmd, iqCmd, currentTime, currentRPM, currentIq] = appendHold( ...
    t, rpmCmd, iqCmd, currentTime, currentRPM, currentIq, ...
    finalZeroHold_s, Ts_profile);

% Clamp
rpmCmd = min(max(rpmCmd, 0), maxRPM);
iqCmd  = min(max(iqCmd,  0), max(loadIqLevels_A));

% Exact final kill
rpmCmd(end) = 0;
iqCmd(end)  = 0;

%% ============================================================
%  FROM WORKSPACE TIMESERIES
% ============================================================

SpeedRefRPM_effmap = timeseries(single(rpmCmd(:)), t(:));
DynoIqRef_A_effmap = timeseries(single(iqCmd(:)),  t(:));

SpeedRefRPM_effmap.Name = "SpeedRefRPM_effmap";
DynoIqRef_A_effmap.Name = "DynoIqRef_A_effmap";

assignin('base', 'SpeedRefRPM_effmap', SpeedRefRPM_effmap);
assignin('base', 'DynoIqRef_A_effmap', DynoIqRef_A_effmap);

assignin('base', 'rpmLevels_effmap', rpmLevels);
assignin('base', 'loadIqLevels_A_effmap', loadIqLevels_A);
assignin('base', 'Ts_profile_effmap', Ts_profile);

%% ============================================================
%  VERIFICATION PLOTS
% ============================================================

figure('Name','Lab 1 Dense Higher Load RPM Command','Color','w');
plot(t, rpmCmd, 'b', 'LineWidth', 1.3);
grid on;
xlabel('Time (s)');
ylabel('Speed Command (RPM)');
title('Motor 1 RPM Command: Dense Higher Load Efficiency Map');

figure('Name','Lab 1 Dense Higher Load Dyno Iq Command','Color','w');
plot(t, iqCmd, 'r', 'LineWidth', 1.3);
grid on;
xlabel('Time (s)');
ylabel('Dyno Iq Command (A)');
title('Dyno Load Command: Dense Higher Load Efficiency Map');

figure('Name','Commanded RPM x Iq Operating Points','Color','w');
scatter(rpmCmd, iqCmd, 12, 'filled');
grid on;
xlabel('Motor 1 Speed Command (RPM)');
ylabel('Dyno Iq Command (A)');
title('Commanded Dense Higher-Load RPM x Iq Coverage');
xlim([0 maxRPM*1.05]);
ylim([-0.2 max(loadIqLevels_A)+0.2]);

fprintf('\nCreated dense higher-load efficiency-map setup signals:\n');
fprintf('  SpeedRefRPM_effmap\n');
fprintf('  DynoIqRef_A_effmap\n');

fprintf('\nTiming:\n');
fprintf('  Start delay:       %.3f s\n', startDelay_s);
fprintf('  Speed ramp:        %.3f s\n', speedRamp_s);
fprintf('  Speed settle:      %.3f s\n', speedSettle_s);
fprintf('  Load ramp:         %.3f s\n', loadRamp_s);
fprintf('  Load settle:       %.3f s\n', loadSettle_s);
fprintf('  Load hold:         %.3f s\n', loadHold_s);
fprintf('  Between loads:     %.3f s\n', betweenLoadZero_s);
fprintf('  Between speeds:    %.3f s\n', betweenSpeedZero_s);
fprintf('  Shutdown ramp:     %.3f s\n', shutdownRamp_s);
fprintf('  Final zero hold:   %.3f s\n', finalZeroHold_s);
fprintf('  Total run time:    %.3f s\n', t(end));

fprintf('\nSweep coverage:\n');
fprintf('  RPM levels: %s\n', mat2str(rpmLevels));
fprintf('  Iq levels:  %s A\n', mat2str(loadIqLevels_A));
fprintf('  Operating points: %d speeds x %d loads = %d points\n', ...
    numel(rpmLevels), numel(loadIqLevels_A), ...
    numel(rpmLevels)*numel(loadIqLevels_A));

fprintf('\nBase folder:\n  %s\n', baseDir);

%% ============================================================
%  OPEN HOST MODEL FILE
% ============================================================

hostModelName = 'mcb_pmsm_foc_host_model_dyno_f28069m_DEMO';

hostModelSlx = fullfile(baseDir, [hostModelName '.slx']);

if exist(hostModelSlx, 'file')

    open_system(hostModelSlx);

    fprintf('\nHost model opened:\n  %s\n', hostModelSlx);

else

    searchResult = dir(fullfile(baseDir, '**', [hostModelName '.slx']));

    if ~isempty(searchResult)

        hostModelSlx = fullfile(searchResult(1).folder, searchResult(1).name);
        open_system(hostModelSlx);

        fprintf('\nHost model opened:\n  %s\n', hostModelSlx);

    else

        warning('Host model file not found under: %s', baseDir);
        fprintf('\nExpected host model name:\n  %s.slx\n', hostModelName);

    end
end

fprintf('\nUse SpeedRefRPM_effmap and DynoIqRef_A_effmap in the host model.\n');
fprintf('No RPM/Iq switches were modified by this setup script.\n');
fprintf('End command forces RPM = 0 and Iq = 0 to kill/unload the motor.\n\n');

%% ============================================================
%  LOCAL FUNCTIONS
% ============================================================

function [t, rpmCmd, iqCmd, currentTime, currentRPM, currentIq] = appendHold( ...
    t, rpmCmd, iqCmd, currentTime, currentRPM, currentIq, ...
    holdTime, Ts)

    if holdTime <= 0
        return;
    end

    n = max(1, round(holdTime / Ts));
    tt = currentTime + (0:n-1).' * Ts;

    t      = [t; tt]; %#ok<AGROW>
    rpmCmd = [rpmCmd; currentRPM .* ones(n,1)]; %#ok<AGROW>
    iqCmd  = [iqCmd;  currentIq  .* ones(n,1)]; %#ok<AGROW>

    currentTime = tt(end) + Ts;
end

function [t, rpmCmd, iqCmd, currentTime, currentRPM, currentIq] = appendTransition( ...
    t, rpmCmd, iqCmd, currentTime, currentRPM, currentIq, ...
    targetRPM, targetIq, transitionTime, Ts, useCosine)

    if transitionTime <= 0
        currentRPM = targetRPM;
        currentIq  = targetIq;
        return;
    end

    n = max(2, round(transitionTime / Ts));
    tt = currentTime + (0:n-1).' * Ts;

    u = linspace(0, 1, n).';

    if useCosine
        s = 0.5 - 0.5*cos(pi*u);
    else
        s = u;
    end

    rpmSegment = currentRPM + (targetRPM - currentRPM).*s;
    iqSegment  = currentIq  + (targetIq  - currentIq).*s;

    t      = [t; tt]; %#ok<AGROW>
    rpmCmd = [rpmCmd; rpmSegment]; %#ok<AGROW>
    iqCmd  = [iqCmd;  iqSegment]; %#ok<AGROW>

    currentTime = tt(end) + Ts;
    currentRPM  = targetRPM;
    currentIq   = targetIq;
end