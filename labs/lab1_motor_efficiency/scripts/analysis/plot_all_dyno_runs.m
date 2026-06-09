function plot_all_dyno_runs(parentDir)
% ==============================================================
% plot_all_dyno_runs  —  Plot dyno results from multiple exports
% Each subfolder (dyno_exports_01, etc.) must contain:
%   debug_1.csv, debug_2.csv, RPM.csv, Iq_Ref.csv
% ==============================================================

if nargin < 1
    parentDir = fullfile(pwd);  % current dir
end

folders = dir(fullfile(parentDir, 'dyno_exports_*'));
if isempty(folders)
    error('No dyno_exports_* folders found in %s', parentDir);
end

figure('Name', 'Dyno Efficiency Comparison', 'Color', 'w');
tiledlayout(2,1,'TileSpacing','compact');

% === Colors per run ===
cols = lines(numel(folders));

% === Subplots ===
nexttile(1); hold on; grid on; box on;
ylabel('Mechanical Power (W)');
title('Motor Mechanical Power vs Time');
ax1 = gca; ax1.XMinorGrid='on'; ax1.YMinorGrid='on';

nexttile(2); hold on; grid on; box on;
xlabel('Time (s)');
ylabel('Efficiency (\eta)');
title('Dyno + Inverter Efficiency Comparison');
ax2 = gca; ax2.XMinorGrid='on'; ax2.YMinorGrid='on';

for k = 1:numel(folders)
    thisDir = fullfile(folders(k).folder, folders(k).name);
    try
        % Load files
        Pm1 = readtable(fullfile(thisDir, 'debug_1.csv')).debug_1;
        Pm2 = readtable(fullfile(thisDir, 'debug_2.csv')).debug_2;
        RPM = readtable(fullfile(thisDir, 'RPM.csv')).RPM(1);
        Iq  = readtable(fullfile(thisDir, 'Iq_Ref.csv')).Iq_Ref(1);

        % Use shortest vector
        N = min([numel(Pm1), numel(Pm2)]);
        t = (0:N-1)' * 0.01; % assumes 100 Hz sample rate, adjust if needed

        % Compute efficiency (switch motors!)
        eta = abs(Pm2(1:N)) ./ max(abs(Pm1(1:N)), eps);
        eta = movmean(eta, 100, 'omitnan');
        mean_eta = mean(eta(~isnan(eta)));

        % Plot power
        nexttile(1);
        plot(t, Pm1(1:N), '-', 'Color', cols(k,:), 'LineWidth', 1.2);
        plot(t, Pm2(1:N), '--', 'Color', cols(k,:), 'LineWidth', 1.2);

        % Plot efficiency
        nexttile(2);
        plot(t, eta, 'Color', cols(k,:), 'LineWidth', 1.3, ...
            'DisplayName', sprintf('%.0f RPM @ %.1f A (η=%.2f)', RPM, Iq, mean_eta));

        % Add annotation tag
        annotation('textbox', [0.15 0.92-0.05*k 0.8 0.04], ...
            'String', sprintf('Run %d: %.0f RPM @ %.1f A (η=%.2f)', ...
                              k, RPM, Iq, mean_eta), ...
            'EdgeColor', 'none', ...
            'HorizontalAlignment', 'center', ...
            'FontSize', 10);
    catch ME
        warning('Skipping %s: %s', folders(k).name, ME.message);
    end
end

% Final legend
nexttile(2);
legend('show', 'Location', 'bestoutside');

end
