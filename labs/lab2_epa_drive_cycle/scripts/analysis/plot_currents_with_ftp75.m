load('cycleFTP75.mat')    % loads FTP-75 timeseries
tC = double(cycleFTP75.Time(:));
vC = double(cycleFTP75.Data(:));

% Keep only first 450 s
mask = tC <= 450;
tC = tC(mask);
vC = vC(mask);

% === Get both motor currents ===
m1 = evalin('base','debug_1');   % Motor 1 current
m2 = evalin('base','debug_2');   % Motor 2 current

t1 = double(m1.Time(:));
i1 = double(m1.Data(:));
t2 = double(m2.Time(:));
i2 = double(m2.Data(:));

% === Plot ===
figure('Name','Motor Currents with FTP-75 overlay (0–450 s)');
yyaxis left
plot(t1, i1, 'r', 'LineWidth', 1.5); hold on;       % red
plot(t2, i2, 'b', 'LineWidth', 1.5);                % blue
ylabel('Motor Current (A)');
legend('Motor 1 Current','Motor 2 Current','Location','best');

yyaxis right
plot(tC, vC, '--k', 'LineWidth', 1.2);              % black dashed
ylabel('Vehicle Speed (mph)');

xlabel('Time (s)');
title('Motor Currents with FTP-75 Speed Overlay (0–450 s)');
grid on; box on;
