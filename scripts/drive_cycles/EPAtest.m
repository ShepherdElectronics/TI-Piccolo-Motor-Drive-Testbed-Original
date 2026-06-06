%% -------- LOAD FTP-75 EPA CYCLE --------

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
