% Model         :   PMSM Field Oriented Control
% Description   :   Set Parameters for PMSM Field Oriented Control
% File name     :   mcb_pmsm_foc_qep_dyno_f28069m_data.m

% Copyright 2020 The MathWorks, Inc.

%% Simulation Parameters

%% Set PWM Switching frequency
PWM_frequency 	= 10e3;    %Hz          // converter s/w freq
T_pwm           = 1/PWM_frequency;  %s  // PWM switching time period

%% Set Sample Times
Ts          	= T_pwm;        %sec        // simulation time step for controller
Ts_simulink     = T_pwm/2;      %sec        // simulation time step for model simulation
Ts_motor        = T_pwm/2;      %Sec        // Simulation sample time
Ts_inverter     = T_pwm/2;      %sec        // simulation time step for average value inverter
Ts_speed        = 10*Ts;        %Sec        // Sample time for speed controller

%% Set data type for controller & code-gen
% Uncomment the required data type and comment out the other
%dataType = fixdt(1,32,17);    % Fixed point code-generation
dataType = 'single';           % Floating point code-generation
%% System Parameters // Hardware parameters 

pmsm_motor1 = mcb_SetPMSMMotorParameters('Teknic2310P');
pmsm_motor1.PositionOffset = 0.1687; % Enter offset values from calibration

pmsm_motor2 = mcb_SetPMSMMotorParameters('Teknic2310P');
pmsm_motor2.PositionOffset = 0.1655; % Enter offset values from calibration

%% Target & Inverter Parameters
target = mcb_SetProcessorDetails('F28069M',PWM_frequency);

inverter_motor1 = mcb_SetInverterParameters('BoostXL-DRV8305');
inverter_motor2 = mcb_SetInverterParameters('BoostXL-DRV8305');

%% Calibration section

% Enable automatic calibration of ADC offset for current measurement
inverter_motor1.ADCOffsetCalibEnable = 1; % Enable: 1, Disable:0
inverter_motor2.ADCOffsetCalibEnable = 1; % Enable: 1, Disable:0

% If automatic ADC offset calibration is disabled, uncomment and update the 
% offset values below manually
% inverter_motor1.CtSensAOffset = 2265;      % ADC Offset for phase current A 
% inverter_motor1.CtSensBOffset = 2286;      % ADC Offset for phase current B
% 
% inverter_motor2.CtSensAOffset = 2265;      % ADC Offset for phase current A 
% inverter_motor2.CtSensBOffset = 2286;      % ADC Offset for phase current B

% BoostXL-DRV8305 Current sense gain remains 10 V/V (default value)
inverter_motor1.ADCGain = 1;   % ADC Range = +- 19.300A wrt 0-4095 counts
inverter_motor1.SPI_Gain_Setting = 0x5000;

inverter_motor2.ADCGain = 1;   % ADC Range = +- 19.300A wrt 0-4095 counts
inverter_motor2.SPI_Gain_Setting = 0x5000;
% Max and min ADC counts for current sense offsets for both inverters
inverter_motor1.CtSensOffsetMax = 2500; 
inverter_motor1.CtSensOffsetMin = 1500;

inverter_motor2.CtSensOffsetMax = 2500;
inverter_motor2.CtSensOffsetMin = 1500;

%% Derive Characteristics
pmsm_motor1.N_base = mcb_getBaseSpeed(pmsm_motor1,inverter_motor1); %rpm // Base speed of motor at given Vdc
pmsm_motor2.N_base = mcb_getBaseSpeed(pmsm_motor2,inverter_motor2); %rpm // Base speed of motor at given Vdc
% mcb_getCharacteristics(pmsm_motor1,inverter_motor1);
% mcb_getCharacteristics(pmsm_motor2,inverter_motor2);

%% PU System details // Set base values for pu conversion

PU_System_motor1 = mcb_SetPUSystem(pmsm_motor1,inverter_motor1);
PU_System_motor2 = mcb_SetPUSystem(pmsm_motor2,inverter_motor2);

%% Controller design // Get ballpark values!
% for motor 1 
PI_params_motor1 = mcb.internal.SetControllerParameters(pmsm_motor1,inverter_motor1,PU_System_motor1,T_pwm,Ts,Ts_speed);

%Updating delays for simulation
PI_params_motor1.delay_Currents    = 0; %int32(Ts/Ts_simulink);
PI_params_motor1.delay_Position    = 0; %int32(Ts/Ts_simulink);

% mcb_getControlAnalysis(pmsm_motor1,inverter_motor1,PU_System_motor1,PI_params_motor1,Ts,Ts_speed); 

% for motor 2
PI_params_motor2 = mcb.internal.SetControllerParameters(pmsm_motor2,inverter_motor2,PU_System_motor2,T_pwm,Ts,Ts_speed);

%Updating delays for simulation
PI_params_motor2.delay_Currents    = 0; %int32(Ts/Ts_simulink);
PI_params_motor2.delay_Position    = 0; %int32(Ts/Ts_simulink);

% mcb_getControlAnalysis(pmsm_motor2,inverter_motor2,PU_System_motor2,PI_params_motor2,Ts,Ts_speed); 
%% Displaying model variables
disp(pmsm_motor1);
disp(pmsm_motor2);
disp(inverter_motor1);
disp(inverter_motor2);
disp(target);
disp(PU_System_motor1);
disp(PU_System_motor2);

Kt = pmsm_motor1.Kt;     % N*m/A  (peak torque constant)
J  = pmsm_motor1.J;      % kg*m^2 (combined rotor+coupler inertia used by the example)
B  = pmsm_motor1.B;      % N*m*s/rad (viscous friction)
BaseRPM = pmsm_motor1.N_base;  % rpm (from your DC bus and motor params)
disp(table(Kt,J,B,BaseRPM))



%% ReferenceRuns — SINE Profile Generator (stretchable) for From Workspace
% Produces: refSignal = timeseries(rpm, t)
% You control “stretching” by changing the sine period/frequency OR by using
% a time-warp factor (stretchFactor) that scales the sine time base.

%% ---------------- USER SETTINGS ----------------
Ts        = 0.001;      % sample time (s)

% Hold at the beginning (safe start)
delayTime = 5;          % seconds
startRPM  = 100;        % RPM during delay

% Total run time AFTER delay (seconds)
runTime   = 120;        % e.g., 2 minutes total after delay

% Sine settings (choose ONE method to control stretching)
% Method A: direct frequency/period
freqHz    = 0.05;       % Hz  (0.05 Hz = 20 s period)  <-- “stretch” here
% periodS = 20;         % If you prefer period, set periodS and compute freqHz=1/periodS

% Method B: time-warp stretch (optional)
stretchFactor = 1.0;    % >1 stretches (slower), <1 compresses (faster)

% Amplitude + offset (keep safe)
rpmCenter = 1200;       % center RPM about which sine oscillates
rpmAmp    = 400;        % amplitude (peak deviation)

% Optional: clamp to a safe RPM window
minRPM    = 100;
maxRPM    = 4000;

% Optional: smooth amplitude ramp-in (avoids sudden jump at delay end)
ampRampTime = 5;        % seconds to ramp amplitude from 0 → rpmAmp (set 0 to disable)

%% ---------------- BUILD TIME BASE ----------------
Tsim = delayTime + runTime;
t    = (0:Ts:Tsim)';

rpm = zeros(size(t),'single');

% First delayTime seconds = startRPM
rpm(t < delayTime) = single(startRPM);

%% ---------------- SINE SECTION ----------------
idx = (t >= delayTime);
tRun = t(idx) - delayTime;          % time since end of delay

% Apply time-warp stretch (this is your “stretch knob” if you want it)
tWarp = tRun ./ stretchFactor;

% Sine wave
s = sin(2*pi*freqHz*tWarp);

% Optional amplitude ramp-in
if ampRampTime > 0
    ramp = min(tRun/ampRampTime, 1);     % 0→1
else
    ramp = ones(size(tRun));
end

rpmSine = rpmCenter + (rpmAmp .* ramp) .* s;

% Apply to output
rpm(idx) = single(rpmSine);

% Clamp to safe bounds
rpm(rpm < minRPM) = single(minRPM);
rpm(rpm > maxRPM) = single(maxRPM);

%% ---------------- OUTPUT TIMESERIES ----------------
refSignal = timeseries(rpm, t);

%% ---------------- QUICK PLOT ----------------
figure('Color','w'); 
plot(t, double(rpm), 'LineWidth', 1.2); grid on;
xlabel('Time (s)'); ylabel('refSignal (RPM)');
title(sprintf('Sine Speed Reference: center=%g, amp=%g, f=%g Hz, stretch=%g', ...
    rpmCenter, rpmAmp, freqHz, stretchFactor));



%% Dyno Presentation Profiles — FULLY SMOOTH SINE (no steps), 10s period
% Continuous sine waves at regular intervals (default: 10 second period).
% Speed limited to maxRPM=3500.
% Current command limited to -3..+3 A.

%% ================= USER KNOBS =================
Ts = 0.01;              % base sample time for From Workspace interpolation

% Common sine timing
Tper = 10;              % seconds per sine period  <-- requested
fHz  = 1/Tper;

% Speed limits (RPM)
idleRPM  = 100;
maxRPM   = 3500;
holdIdle = 5;           % seconds at idle before/after
Tactive_speed = 60;     % active sine duration (s)  <-- pick any; should be multiple of Tper for clean cycles

% Speed sine shape
speed_center   = 1800;  % RPM center
speed_amp      = 1600;  % RPM amplitude (center±amp should fit within [idleRPM,maxRPM])
speed_ampRampT = 3;     % seconds amplitude ramps 0->full (smooth)

% Load/current (IqRef_A) limits (A)
Iq_minA = -3;
Iq_maxA = +3;
holdIdle_load = 5;      % seconds at center before/after
Tactive_load  = 60;     % active sine duration (s)

% Load sine shape
Iq_center     = 0;      % center at 0 A
Iq_amp        = 3;      % amplitude so it hits ±3 A
load_ampRampT = 3;      % seconds amplitude ramps 0->full

% Regen sign-flip demo (smooth sines, no steps)
regenHold1 = 30;        % seconds positive segment
regenHold2 = 30;        % seconds negative (regen) segment
regenHold3 = 30;        % seconds positive segment
regen_rampT = 2;        % seconds fade-in/out per segment

%% ================= Helpers =================
mk_t  = @(Tend) (0:Ts:Tend)';

clamp = @(x,lo,hi) min(max(x,lo),hi);

% Smooth 0->1 ramp (no stepping)
ampRamp01 = @(t,Tr) (Tr<=0).*ones(size(t)) + (Tr>0).*min(t./Tr, 1);

% Smooth sine with amplitude ramp-in
mk_sine = @(t,center,amp,fHz,Tramp) ...
    (center + (amp .* ampRamp01(t,Tramp)) .* sin(2*pi*fHz*t));

% Smooth window to fade in/out within a segment (no steps)
win = @(t,T,Tr) min(ampRamp01(t,Tr), ampRamp01(T - t,Tr));

%% ================= 1) SPEED (SMOOTH SINE, 10s period) =================
T_speed = holdIdle + Tactive_speed + holdIdle;
t_speed = mk_t(T_speed);

rpm_s = zeros(size(t_speed));
rpm_s(t_speed < holdIdle) = idleRPM;

idx = (t_speed >= holdIdle) & (t_speed < holdIdle + Tactive_speed);
tRun = t_speed(idx) - holdIdle;

rpmSmooth = mk_sine(tRun, speed_center, speed_amp, fHz, speed_ampRampT);
rpm_s(idx) = rpmSmooth;

rpm_s(t_speed >= holdIdle + Tactive_speed) = idleRPM;

% Clamp to allowable bounds
rpm_s = clamp(rpm_s, idleRPM, maxRPM);

SpeedRefRPM_sine = timeseries(single(rpm_s), t_speed);

%% ================= 2) LOAD / CURRENT (IqRef_A) (SMOOTH SINE, 10s period) =================
T_load = holdIdle_load + Tactive_load + holdIdle_load;
t_load = mk_t(T_load);

iq_s = zeros(size(t_load));
iq_s(t_load < holdIdle_load) = Iq_center;

idx = (t_load >= holdIdle_load) & (t_load < holdIdle_load + Tactive_load);
tRun2 = t_load(idx) - holdIdle_load;

iqSmooth = mk_sine(tRun2, Iq_center, Iq_amp, fHz, load_ampRampT);
iq_s(idx) = iqSmooth;

iq_s(t_load >= holdIdle_load + Tactive_load) = Iq_center;

iq_s = clamp(iq_s, Iq_minA, Iq_maxA);

DynoIqRef_A_sine = timeseries(single(iq_s), t_load);

%% ================= 3) REGEN (IqRef_A) (SMOOTH SINE sign flip) =================
T_regen = holdIdle_load + regenHold1 + regenHold2 + regenHold3 + holdIdle_load;
t_regen = mk_t(T_regen);

iq_r = zeros(size(t_regen));
iq_r(t_regen < holdIdle_load) = Iq_center;

seg1 = (t_regen >= holdIdle_load) & (t_regen < holdIdle_load + regenHold1);
seg2 = (t_regen >= holdIdle_load + regenHold1) & ...
       (t_regen <  holdIdle_load + regenHold1 + regenHold2);
seg3 = (t_regen >= holdIdle_load + regenHold1 + regenHold2) & ...
       (t_regen <  holdIdle_load + regenHold1 + regenHold2 + regenHold3);

if any(seg1)
    tA = t_regen(seg1) - holdIdle_load;
    wA = win(tA, regenHold1, regen_rampT);
    yA = (Iq_amp .* wA) .* sin(2*pi*fHz*tA) + Iq_center;
    iq_r(seg1) = yA;
end

if any(seg2)
    tB = t_regen(seg2) - (holdIdle_load + regenHold1);
    wB = win(tB, regenHold2, regen_rampT);
    yB = (-Iq_amp .* wB) .* sin(2*pi*fHz*tB) + Iq_center;
    iq_r(seg2) = yB;
end

if any(seg3)
    tC = t_regen(seg3) - (holdIdle_load + regenHold1 + regenHold2);
    wC = win(tC, regenHold3, regen_rampT);
    yC = (Iq_amp .* wC) .* sin(2*pi*fHz*tC) + Iq_center;
    iq_r(seg3) = yC;
end

iq_r(t_regen >= holdIdle_load + regenHold1 + regenHold2 + regenHold3) = Iq_center;
iq_r = clamp(iq_r, Iq_minA, Iq_maxA);

RegenIqRef_A_sine = timeseries(single(iq_r), t_regen);

%% ================= 4) PLOTS =================
figure('Name','Speed Reference (RPM) - Smooth Sine');
plot(t_speed, rpm_s, 'LineWidth', 1.4); grid on;
xlabel('Time (s)'); ylabel('SpeedRef (RPM)');
title(sprintf('SpeedRef (Smooth Sine, period=%.1fs)', Tper));
xlim([0 t_speed(end)]);
ylim([0 maxRPM*1.05]);

figure('Name','Dyno Current Command (A) - Smooth Sine');
plot(t_load, iq_s, 'LineWidth', 1.4); grid on;
xlabel('Time (s)'); ylabel('IqRef (A)');
title(sprintf('Dyno Load / IqRef (Smooth Sine, period=%.1fs)', Tper));
xlim([0 t_load(end)]);
ylim([Iq_minA-0.2 Iq_maxA+0.2]);

figure('Name','Regen Current Command (A) - Smooth Sine Sign Flip');
plot(t_regen, iq_r, 'LineWidth', 1.4); grid on;
xlabel('Time (s)'); ylabel('IqRef (A)');
title(sprintf('Regen Demo (Smooth Sine Sign Flip, period=%.1fs)', Tper));
xlim([0 t_regen(end)]);
ylim([Iq_minA-0.2 Iq_maxA+0.2]);

disp("Created timeseries variables for From Workspace blocks:");
disp("  SpeedRefRPM_sine");
disp("  DynoIqRef_A_sine   (-3 to +3 A)");
disp("  RegenIqRef_A_sine  (-3 to +3 A)");

fprintf('\nSine timing:\n');
fprintf('  fHz = %.5f Hz (period %.2f s)\n\n', fHz, Tper);


% Load the only available cycle
S  = load("C:\Program Files\MATLAB\R2023b\toolbox\autoblks\autoblksshared\cycleFTP75.mat");
ts = S.cycleFTP75;

% Extract time and speed
t = double(ts.Time(:));
v = double(ts.Data(:));     % km/h

% Clean data
ok = isfinite(t) & isfinite(v);
t = t(ok); 
v = v(ok);

% Ensure monotonic unique time
[t, idx] = unique(t,'stable');
v = v(idx);

% Convert km/h -> m/s
v_mps = v / 3.6;

%% -------- TIMESERIES (for plotting / analysis) --------
FTP75_speed_mps_ts = timeseries(v_mps, t);
FTP75_speed_mps_ts.Name = "FTP75_speed_mps";

%% -------- SIMULINK FROM-WORKSPACE SIGNAL --------
FTP75_speed_mps_sig.time = t;
FTP75_speed_mps_sig.signals.values = v_mps;
FTP75_speed_mps_sig.signals.dimensions = 1;

%% -------- QUICK SANITY CHECK --------
fprintf("FTP-75 duration: %.1f s\n", t(end));
fprintf("FTP-75 max speed: %.2f m/s (%.1f km/h)\n", max(v_mps), max(v));
 %% -------- SCALE FTP-75 TO MOTOR RPM --------

motor_rpm_max = 4000;      % your motor limit

% Original speed
v_kmh = v;                % from earlier
v_mps = v_mps;            % already computed

% Normalize cycle
v_norm = v_mps / max(v_mps);

% Scale to motor RPM
motor_rpm_cmd = motor_rpm_max * v_norm;

%% -------- PLOT --------
figure; 
tiledlayout(2,1)

% --- Vehicle speed plot ---
nexttile
plot(t, v_kmh, 'LineWidth', 1.2)
grid on
ylabel('Speed (km/h)')
title('FTP-75 EPA Drive Cycle (Raw)')
xlim([0 t(end)])

% --- Motor RPM command plot ---
nexttile
plot(t, motor_rpm_cmd, 'LineWidth', 1.2)
grid on
ylabel('Motor Speed Command (RPM)')
xlabel('Time (s)')
title('FTP-75 Scaled to 4000 RPM Motor Command')
ylim([0 motor_rpm_max*1.05])
xlim([0 t(end)])

FTP75_motorRPM_sig.time = t;
FTP75_motorRPM_sig.signals.values = motor_rpm_cmd;
FTP75_motorRPM_sig.signals.dimensions = 1;
filePath = 'C:\Users\jcherna1\Downloads\Software\c2b\DMD\mcb_pmsm_foc_host_model_dyno_f28069m_DEMO.slx';

open_system(filePath);

