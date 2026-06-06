%% Save Dyno Test Data
% This script exports logged signals from the workspace (debug_1, debug_2, RPM, Iq_Ref)
% into CSV files for easy post-processing later.

% === Create output directory ===
outDir = fullfile(pwd, 'dyno_exports');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

% === Helper to save timeseries as CSV ===
saveTS = @(ts, name) ...
    writematrix([ts.Time(:), ts.Data(:)], ...
        fullfile(outDir, [name '.csv']), ...
        'Delimiter', ',');

% === Export timeseries signals ===
if evalin('base','exist("debug_1","var")')
    S = evalin('base','debug_1');
    saveTS(S, 'debug_1');
end

if evalin('base','exist("debug_2","var")')
    S = evalin('base','debug_2');
    saveTS(S, 'debug_2');
end

% === Export array signals (already double matrices) ===
if evalin('base','exist("RPM","var")')
    R = evalin('base','RPM');
    writematrix(R, fullfile(outDir,'RPM.csv'));
end

if evalin('base','exist("Iq_Ref","var")')
    I = evalin('base','Iq_Ref');
    writematrix(I, fullfile(outDir,'Iq_Ref.csv'));
end

% === Optional: save everything as a single .mat file ===
save(fullfile(outDir,'dyno_session.mat'), 'debug_1', 'debug_2', 'RPM', 'Iq_Ref', '-v7');

fprintf('\n✅ Dyno data exported to folder:\n%s\n', outDir);
