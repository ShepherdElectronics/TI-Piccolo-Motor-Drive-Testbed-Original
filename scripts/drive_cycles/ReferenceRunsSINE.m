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

