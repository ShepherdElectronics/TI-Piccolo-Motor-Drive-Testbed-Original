%% Plot Dyno Efficiency

% === Load data ===
debug1 = readmatrix('dyno_exports/debug_1.csv');  % Now DRIVE
debug2 = readmatrix('dyno_exports/debug_2.csv');  % Now LOAD
RPM     = readmatrix('dyno_exports/RPM.csv');
Iq_Ref  = readmatrix('dyno_exports/Iq_Ref.csv');

% --- Normalize shapes ---
debug1 = ensureTwoCols(debug1);
debug2 = ensureTwoCols(debug2);
RPM    = ensureTwoCols(RPM);
Iq_Ref = ensureTwoCols(Iq_Ref);

t = debug1(:,1);
Pm_drive = debug1(:,2);  % Motor 2 (Drive)
Pm_load  = debug2(:,2);  % Motor 1 (Load)

% --- Equalize lengths ---
n = min([numel(t), numel(Pm_drive), numel(Pm_load)]);
t = t(1:n); Pm_drive = Pm_drive(1:n); Pm_load = Pm_load(1:n);

% --- Trim ---
if range(t) > 20
    mask = (t >= (t(1)+10)) & (t <= (t(end)-10));
else
    mask = true(size(t));
end
t = t(mask); Pm_drive = Pm_drive(mask); Pm_load = Pm_load(mask);

% --- Efficiency (now correct) ---
eta = abs(Pm_load) ./ max(abs(Pm_drive), eps);
eta_s = movmean(eta, 100, 'omitnan');
mean_eta = mean(eta_s(~isnan(eta_s)));

% --- Conditions ---
rpm_val = round(mean(RPM(:,2)),0);
iq_val  = round(mean(Iq_Ref(:,2)),1);

% --- Plot ---
figure('Color','w');
tiledlayout(2,1,'TileSpacing','compact');

% Mechanical Power
nexttile
plot(t, Pm_drive, 'r','LineWidth',1.2); hold on;
plot(t, Pm_load,  'b','LineWidth',1.2);
ylabel('Mechanical Power (W)');
legend('Motor 2 (Drive)','Motor 1 (Load)','Location','best');
grid on; box on; ax=gca; ax.XMinorGrid='on'; ax.YMinorGrid='on';
title('Motor Mechanical Power vs Time');

% Efficiency
nexttile
plot(t, eta_s, 'k','LineWidth',1.3);
xlabel('Time (s)'); ylabel('Efficiency (\eta)');
ylim([0 1.2]);
grid on; box on; ax=gca; ax.XMinorGrid='on'; ax.YMinorGrid='on';
title(sprintf('Overall Dyno + Inverter Efficiency  (Mean \\eta = %.2f)', mean_eta));

% Annotation
annotation('textbox',[0.13 0.93 0.75 0.07], ...
    'String', sprintf('%d RPM @ %.1f A', rpm_val, iq_val), ...
    'HorizontalAlignment','center', 'VerticalAlignment','middle', ...
    'FontWeight','bold', 'FontSize',11, 'EdgeColor','none');

%% --- Helper ---
function A = ensureTwoCols(A)
    % Ensures Nx2 numeric [time, value] format
    if size(A,2) == 1
        A = [(0:length(A)-1)' A]; % auto time vector (samples)
    end
end
