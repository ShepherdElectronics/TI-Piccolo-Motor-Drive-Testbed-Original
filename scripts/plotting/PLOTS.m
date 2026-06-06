% === Setup ===
baseDir = pwd;
runs = dir(fullfile(baseDir, 'dyno_exports_*'));

nRuns = numel(runs);
figure('Color','w');
tiledlayout(nRuns,2,'TileSpacing','compact','Padding','compact');

cols = lines(nRuns);

for k = 1:nRuns
    runPath = fullfile(baseDir, runs(k).name);

    % === Load data ===
    debug1 = readmatrix(fullfile(runPath, 'debug_1.csv'));  % DRIVE
    debug2 = readmatrix(fullfile(runPath, 'debug_2.csv'));  % LOAD
    RPM     = readmatrix(fullfile(runPath, 'RPM.csv'));
    Iq_Ref  = readmatrix(fullfile(runPath, 'Iq_Ref.csv'));

    % --- Normalize shapes ---
    debug1 = ensureTwoCols(debug1);
    debug2 = ensureTwoCols(debug2);
    RPM    = ensureTwoCols(RPM);
    Iq_Ref = ensureTwoCols(Iq_Ref);

    t = debug1(:,1);
    Pm_drive = debug1(:,2);
    Pm_load  = debug2(:,2);

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

    % --- Efficiency ---
    eta = abs(Pm_load) ./ max(abs(Pm_drive), eps);
    eta_s = movmean(eta, 100, 'omitnan');
    mean_eta = mean(eta_s(~isnan(eta_s)));

    % --- Conditions ---
    rpm_val = round(mean(RPM(:,2)),0);
    iq_val  = round(mean(Iq_Ref(:,2)),1);

    % === Plot Power ===
    nexttile((k-1)*2+1);
    plot(t, Pm_drive, 'r','LineWidth',1.2); hold on;
    plot(t, Pm_load,  'b','LineWidth',1.2);
    ylabel('P (W)');
    legend('Drive','Load','Location','best');
    title(sprintf('Run %d — %d RPM @ %.1f A', k, rpm_val, iq_val));
    grid on; box on; ax=gca; ax.XMinorGrid='on'; ax.YMinorGrid='on';

    % === Plot Efficiency ===
    nexttile((k-1)*2+2);
    plot(t, eta_s, 'k','LineWidth',1.3);
    xlabel('Time (s)'); ylabel('\eta');
    ylim([0 1.2]);
    grid on; box on; ax=gca; ax.XMinorGrid='on'; ax.YMinorGrid='on';
    title(sprintf('Mean Efficiency = %.2f', mean_eta));
end

sgtitle('Dyno Test Results: Power & Efficiency','FontWeight','bold');

%% --- Helper ---
function A = ensureTwoCols(A)
    if size(A,2) == 1
        A = [(0:length(A)-1)' A];
    end
end

