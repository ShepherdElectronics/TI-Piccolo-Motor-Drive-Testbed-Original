function check_models()
%CHECK_MODELS Basic CI validation for Simulink models in the repo.
repoRoot = pwd;
addpath(genpath(repoRoot));

reportDir = fullfile(repoRoot, "ci_reports");
if ~exist(reportDir, "dir")
    mkdir(reportDir);
end

reportFile = fullfile(reportDir, "model_check_report.txt");
fid = fopen(reportFile, "w");
cleanupObj = onCleanup(@() fclose(fid));

fprintf(fid, "TI-Piccolo Motor Drive Testbed CI Model Check\n");
fprintf(fid, "Repository root: %s\n", repoRoot);
fprintf(fid, "Timestamp: %s\n\n", string(datetime("now")));

modelFiles = dir(fullfile(repoRoot, "**", "*.slx"));
failures = strings(0);

fprintf(fid, "Found %d .slx files.\n\n", numel(modelFiles));

for k = 1:numel(modelFiles)
    modelPath = fullfile(modelFiles(k).folder, modelFiles(k).name);
    [~, modelName] = fileparts(modelPath);

    fprintf(fid, "[CHECK] %s\n", modelPath);

    try
        load_system(modelPath);
        set_param(modelName, "SimulationCommand", "update");
        close_system(modelName, 0);
        fprintf(fid, "[PASS]  %s\n\n", modelName);
    catch ME
        failures(end+1) = modelPath + " :: " + ME.message;
        fprintf(fid, "[FAIL]  %s\n", modelName);
        fprintf(fid, "        %s\n\n", ME.message);
        try
            bdclose(modelName);
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
    error("CI model check failed for %d model(s). See %s", numel(failures), reportFile);
end

fprintf(fid, "\nAll checked models passed.\n");
disp("All checked Simulink models passed.");
end
