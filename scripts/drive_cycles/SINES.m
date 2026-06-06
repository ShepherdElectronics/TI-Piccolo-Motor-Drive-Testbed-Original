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
