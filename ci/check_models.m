function check_models()
%CHECK_MODELS Level 1 CI validation for selected active Simulink models.
%
% Purpose:
%   This is the first CI/CD sanity check for the TI-Piccolo Motor Drive
%   Testbed repository.
%
% This check verifies:
%   1. Selected active .slx files exist.
%   2. Each selected model can be loaded by MATLAB/Simulink.
%   3. Each model closes cleanly.
%   4. A CI report is written for review.
%
% This check intentionally does NOT:
%   - Simulate models.
%   - Run update diagram.
%   - Build/deploy to F28069M.
%   - Require C2000 hardware setup.
%   - Require Speedgoat setup.
%
% Later CI levels can add update/build checks after the model paths,
% callbacks, and required setup scripts are made repo-relative.

repoRoot = pwd;

reportDir = fullfile(repoRoot, "ci_reports");
if ~exist(reportDir, "dir")
    mkdir(reportDir);
end

reportFile = fullfile(reportDir, "model_check_report.txt");
fid = fopen(reportFile, "w");

if fid < 0
    error("Could not open CI report file: %s", reportFile);
end

cleanupObj = onCleanup(@() fclose(fid));

fprintf(fid, "TI-Piccolo Motor Drive Testbed CI Model Check\n");
fprintf(fid, "Repository root: %s\n", repoRoot);
fprintf(fid, "Timestamp: %s\n\n", string(datetime("now")));

% Level 1 selected active models.
% These should load without requiring hardware deployment or old absolute paths.
modelList = [
    fullfile(repoRoot, "models", "motor_control", "current_control.slx")
    fullfile(repoRoot, "models", "motor_control", "foc_sensorless_algorithm.slx")
    fullfile(repoRoot, "models", "motor_control", "sensorless_algorithm.slx")
    fullfile(repoRoot, "models", "can", "examples", "CAN_rx1.slx")
];

failures = strings(0);

fprintf(fid, "Checking %d selected active model(s).\n\n", numel(modelList));

for k = 1:numel(modelList)
    modelPath = modelList(k);

    if ~isfile(modelPath)
        failures(end+1) = modelPath + " :: file not found"; %#ok<AGROW>
        fprintf(fid, "[FAIL] %s\n", modelPath);
        fprintf(fid, "       File not found.\n\n");
        continue;
    end

    [~, modelName] = fileparts(modelPath);

    fprintf(fid, "[CHECK] %s\n", modelPath);

    try
        bdclose all
        load_system(modelPath);
        close_system(modelName, 0);

        fprintf(fid, "[PASS]  %s loaded successfully.\n\n", modelName);

    catch ME
        failures(end+1) = modelPath + " :: " + ME.message; %#ok<AGROW>

        fprintf(fid, "[FAIL]  %s\n", modelName);
        fprintf(fid, "        %s\n\n", ME.message);

        try
            bdclose all
        catch
        end
    end
end

fprintf(fid, "\nSummary\n");
fprintf(fid, "-------\n");
fprintf(fid, "Failures: %d\n", numel(failures));

if ~isempty(failures)
    fprintf(fid, "\nFailure details:\n");

    for i = 1:numel(failures)
        fprintf(fid, "- %s\n", failures(i));
    end

    error("CI model load check failed for %d model(s). See %s", numel(failures), reportFile);
end

fprintf(fid, "\nAll selected active Simulink models loaded successfully.\n");
disp("All selected active Simulink models loaded successfully.");
end