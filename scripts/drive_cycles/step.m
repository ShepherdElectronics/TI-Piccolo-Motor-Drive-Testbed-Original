Ts        = 0.001;    % sample time (s)
delayTime = 5;        % first 5 seconds at 100 rpm
stepSize  = 50;       % 50 rpm step height
maxRPM    = 4000;     % top value
holdTime  = 3;        % each step lasts 2 seconds

% Compute total sim time
numSteps = maxRPM / stepSize;          % 80 steps
Tsim     = delayTime + numSteps*holdTime;

% Time vector
t = (0:Ts:Tsim)';

% Preallocate
rpm = zeros(size(t),'single');

% First 5 seconds = 100 rpm
rpm(t < delayTime) = single(100);

% Generate staircase starting AFTER the 5-second 100 rpm hold
for k = 0:(numSteps-1)
    tStart = delayTime + k * holdTime;
    tEnd   = delayTime + (k+1) * holdTime;
    rpm(t >= tStart & t < tEnd) = single(100 + k * stepSize);
end

% Final value = 100 + 80*50 = 4100, but we clamp at 4000 rpm
rpm(rpm > maxRPM) = single(maxRPM);

% Build timeseries for From Workspace
refSignal = timeseries(rpm, t);


figure; plot(t,rpm); grid on;
xlabel('Time (s)'); ylabel('refSignal');
