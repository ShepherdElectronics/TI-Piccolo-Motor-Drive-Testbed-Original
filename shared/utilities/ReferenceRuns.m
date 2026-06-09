%% Dyno Presentation Profiles — 0.5s Step-Hold + Exactly ~5 Sine Cycles
% Commands update only every cmdHold seconds (sample-and-hold) to prevent host glitches.
% NOW: cmdHold = 0.5 s, and each SINE profile runs ~5 cycles in the active window.
% Load/current command is between 1 and 5 A (IqRef_A).

%% ================= USER KNOBS =================
Ts = 0.01;              % base sample time for From Workspace interpolation
cmdHold = .5;          % seconds per command update (SAMPLE-AND-HOLD)  <-- UPDATED

% Speed envelope (RPM)
idleRPM  = 100;
maxRPM   = 1200;
holdIdle = 5;

% Speed sine parameters (active window is set automatically to fit 5 cycles)
speed_center   = 700;    % RPM center
speed_amp      = 400;    % RPM amplitude
nCycles_speed  = 5;      % exactly ~5 sine cycles in active window
speed_ampRampT = 3;      % seconds amplitude ramps 0->full

% Load/current (IqRef_A) envelope (A)
Iq_minA = -3;
Iq_maxA = 3;
holdIdle_load = 5;

% Load sine parameters (IqRef_A)
Iq_center     = (Iq_minA + Iq_maxA)/2;       % 3 A
Iq_amp        = (Iq_maxA - Iq_minA)/2;       % 2 A
nCycles_load  = 2;
load_ampRampT = 3;

% Regen sine sign-flip (IqRef_A) across 3 segments
regenHold1 = 18;         % seconds: positive segment
regenHold2 = 18;         % seconds: negative (regen)
regenHold3 = 18;         % seconds: positive segment
regen_rampT = 2;         % seconds ramp-in/out inside each segment
nCycles_regen_seg = 2;   % cycles per segment (so total waves are obvious)

%% ================= Helpers =================
mk_t  = @(Tend) (0:Ts:Tend)';

clamp = @(x,lo,hi) min(max(x,lo),hi);

ampRamp01 = @(t,Tr) (Tr<=0).*ones(size(t)) + (Tr>0).*min(t./Tr, 1);

mk_sine = @(t,center,amp,fHz,Tramp) ...
    (center + (amp .* ampRamp01(t,Tramp)) .* sin(2*pi*fHz*t));

holdify = @(t,y,cmdHold) localHoldify(t,y,cmdHold);

%% ================= 1) SPEED (SINE-STEP, ~5 cycles) =================
% Choose an active duration that fits an integer number of cmdHold steps cleanly
Tactive_speed = nCycles_speed * 20;          % start guess (20s per cycle) -> 100s
Tactive_speed = round(Tactive_speed/cmdHold)*cmdHold;  % align to hold grid
speed_freqHz  = nCycles_speed / Tactive_speed;         % exact ~5 cycles

T_speed = holdIdle + Tactive_speed + holdIdle;
t_speed = mk_t(T_speed);

rpm_s = zeros(size(t_speed));
rpm_s(t_speed < holdIdle) = idleRPM;

idx = (t_speed >= holdIdle) & (t_speed < holdIdle + Tactive_speed);
tRun = t_speed(idx) - holdIdle;

rpmSmooth = mk_sine(tRun, speed_center, speed_amp, speed_freqHz, speed_ampRampT);
rpmHeld   = holdify(tRun, rpmSmooth, cmdHold);

rpm_s(idx) = rpmHeld;
rpm_s(t_speed >= holdIdle + Tactive_speed) = idleRPM;

rpm_s = clamp(rpm_s, idleRPM, maxRPM);

SpeedRefRPM_sineStep = timeseries(single(rpm_s), t_speed);

%% ================= 2) LOAD / CURRENT (IqRef_A) (SINE-STEP, ~5 cycles) =================
Tactive_load = nCycles_load * 20;            % start guess
Tactive_load = round(Tactive_load/cmdHold)*cmdHold;
load_freqHz  = nCycles_load / Tactive_load;  % exact ~5 cycles

T_load = holdIdle_load + Tactive_load + holdIdle_load;
t_load = mk_t(T_load);

iq_s = zeros(size(t_load));
iq_s(t_load < holdIdle_load) = Iq_center;    % keep alive at mid current (3A)

idx = (t_load >= holdIdle_load) & (t_load < holdIdle_load + Tactive_load);
tRun2 = t_load(idx) - holdIdle_load;

iqSmooth = mk_sine(tRun2, Iq_center, Iq_amp, load_freqHz, load_ampRampT);
iqHeld   = holdify(tRun2, iqSmooth, cmdHold);

iq_s(idx) = iqHeld;
iq_s(t_load >= holdIdle_load + Tactive_load) = Iq_center;

iq_s = clamp(iq_s, Iq_minA, Iq_maxA);

DynoIqRef_A_sineStep = timeseries(single(iq_s), t_load);  % <-- name for From Workspace

%% ================= 3) REGEN (IqRef_A) (STEPPED SINE sign flip) =================
% Each segment is a sine with nCycles_regen_seg cycles, stepped at cmdHold
T_regen = holdIdle_load + regenHold1 + regenHold2 + regenHold3 + holdIdle_load;
t_regen = mk_t(T_regen);

iq_r = zeros(size(t_regen));
iq_r(t_regen < holdIdle_load) = Iq_center;

seg1 = (t_regen >= holdIdle_load) & (t_regen < holdIdle_load + regenHold1);
seg2 = (t_regen >= holdIdle_load + regenHold1) & ...
       (t_regen <  holdIdle_load + regenHold1 + regenHold2);
seg3 = (t_regen >= holdIdle_load + regenHold1 + regenHold2) & ...
       (t_regen <  holdIdle_load + regenHold1 + regenHold2 + regenHold3);

win = @(t,T,Tr) min(ampRamp01(t,Tr), ampRamp01(T - t,Tr));

f1 = nCycles_regen_seg / regenHold1;
f2 = nCycles_regen_seg / regenHold2;
f3 = nCycles_regen_seg / regenHold3;

if any(seg1)
    tA = t_regen(seg1) - holdIdle_load;
    wA = win(tA, regenHold1, regen_rampT);
    yA = (Iq_amp .* wA) .* sin(2*pi*f1*tA) + Iq_center;
    iq_r(seg1) = holdify(tA, yA, cmdHold);
end

if any(seg2)
    tB = t_regen(seg2) - (holdIdle_load + regenHold1);
    wB = win(tB, regenHold2, regen_rampT);
    yB = (-Iq_amp .* wB) .* sin(2*pi*f2*tB) + Iq_center;
    iq_r(seg2) = holdify(tB, yB, cmdHold);
end

if any(seg3)
    tC = t_regen(seg3) - (holdIdle_load + regenHold1 + regenHold2);
    wC = win(tC, regenHold3, regen_rampT);
    yC = (Iq_amp .* wC) .* sin(2*pi*f3*tC) + Iq_center;
    iq_r(seg3) = holdify(tC, yC, cmdHold);
end

iq_r(t_regen >= holdIdle_load + regenHold1 + regenHold2 + regenHold3) = Iq_center;
iq_r = clamp(iq_r, Iq_minA, Iq_maxA);

RegenIqRef_A_sineStep = timeseries(single(iq_r), t_regen);

%% ================= 4) PLOTS (scaled nicely) =================
figure('Name','Speed Reference (RPM) - Stepped Sine');
stairs(t_speed, rpm_s, 'LineWidth', 1.4); grid on;
xlabel('Time (s)'); ylabel('SpeedRef (RPM)');
title(sprintf('SpeedRef (Stepped Sine, hold=%.1fs, %d cycles)', cmdHold, nCycles_speed));
xlim([0 t_speed(end)]);
ylim([0 maxRPM*1.05]);

figure('Name','Dyno Current Command (A) - Stepped Sine');
stairs(t_load, iq_s, 'LineWidth', 1.4); grid on;
xlabel('Time (s)'); ylabel('IqRef (A)');
title(sprintf('Dyno Load / IqRef (Stepped Sine, hold=%.1fs, %d cycles)', cmdHold, nCycles_load));
xlim([0 t_load(end)]);
ylim([Iq_minA-0.2 Iq_maxA+0.2]);

figure('Name','Regen Current Command (A) - Stepped Sine Sign Flip');
stairs(t_regen, iq_r, 'LineWidth', 1.4); grid on;
xlabel('Time (s)'); ylabel('IqRef (A)');
title(sprintf('Regen Demo (Stepped Sine Sign Flip, hold=%.1fs)', cmdHold));
xlim([0 t_regen(end)]);
ylim([Iq_minA-0.2 Iq_maxA+0.2]);

disp("Created timeseries variables for From Workspace blocks:");
disp("  SpeedRefRPM_sineStep");
disp("  DynoIqRef_A_sineStep   (1 to 5 A)");
disp("  RegenIqRef_A_sineStep  (1 to 5 A)");

fprintf('\nComputed frequencies:\n');
fprintf('  speed_freqHz = %.5f Hz (period %.1fs, active %.1fs)\n', speed_freqHz, 1/speed_freqHz, Tactive_speed);
fprintf('  load_freqHz  = %.5f Hz (period %.1fs, active %.1fs)\n', load_freqHz,  1/load_freqHz,  Tactive_load);
fprintf('  regen f1/f2/f3 = %.4f / %.4f / %.4f Hz (cycles/seg=%d)\n\n', f1, f2, f3, nCycles_regen_seg);

%% ================= Local Function =================
function yHeld = localHoldify(t, y, cmdHold)
% Piecewise-constant sample-and-hold:
% tUpdate = floor(t/cmdHold)*cmdHold.

    t = t(:); y = y(:);

    tUpdate = floor(t./cmdHold).*cmdHold;
    [uTimes, ia] = unique(tUpdate, 'stable');
    yAtUpdate = y(ia);

    yHeld = interp1(uTimes, yAtUpdate, tUpdate, 'previous', 'extrap');
end
