%% Plot Motor 1 Reference vs Feedback Speed

% === Load data ===
debug1 = readmatrix('dyno_session_20251024_083158/debug_1.csv');  % Motor 1 Reference Speed
debug2 = readmatrix('dyno_session_20251024_083158/debug_2.csv');  % Motor 1 Feedback Speed

% --- Normalize shapes ---
debug1 = ensureTwoCols(debug1);
debug2 = ensureTwoCols(debug2);

t = debug1(:,1);
ref_speed = debug1(:,2);
fb_speed  = debug2(:,2);

% --- Equalize lengths ---
n = min([numel(t), numel(ref_speed), numel(fb_speed)]);
t = t(1:n); 
ref_speed = ref_speed(1:n); 
fb_speed  = fb_speed(1:n);

% --- Trim edges if long run ---
if range(t) > 20
    mask = (t >= (t(1)+10)) & (t <= (t(end)-10));
else
    mask = true(size(t));
end
t = t(mask); 
ref_speed = ref_speed(mask); 
fb_speed  = fb_speed(mask);

% --- Plot ---
figure('Color','w');
plot(t, ref_speed, 'r','LineWidth',1.4); hold on;
plot(t, fb_speed,  'b','LineWidth',1.2);
xlabel('Time (s)');
ylabel('Speed (RPM)');
legend('Motor 1 Ref Speed','Motor 1 Feedback','Location','best');
grid on; box on; 
ax = gca; 
ax.XMinorGrid = 'on'; 
ax.YMinorGrid = 'on';
title('Motor 1 Reference vs Feedback Speed');

%% --- Helper ---
function A = ensureTwoCols(A)
    % Ensures Nx2 numeric [time, value] format
    if size(A,2) == 1
        A = [(0:length(A)-1)' A]; % auto time vector (samples)
    end
end
