

function outDir = save_debug_session(varList, outDir, runName)
% Save debug_* timeseries to CSV + MAT and also save RPM / Iq_Ref if present.
%
% UPDATED:
%   If runName = 'trial01', output folder becomes:
%       <outDir>\trial01
%
%   If outDir is empty, output folder becomes:
%       <current folder>\trial01
%
% USAGE:
%   save_debug_session
%   save_debug_session({'debug_1','debug_2'})
%   save_debug_session([], pwd, 'trial01')
%   save_debug_session([], 'C:\Users\jcherna1\Downloads\Software\c2b\DMD', 'trial01')

W = evalin('base','whos');

%% ---- discover debug_* timeseries ----
isTS = strcmp({W.class}, 'timeseries');

if nargin < 1 || isempty(varList)
    names = {W(isTS).name};
    varList = names(startsWith(names,'debug_','IgnoreCase',true));
else
    varList = varList(:)';

    varList = varList( ...
        cellfun(@(n) evalin('base',sprintf('exist(''%s'',''var'')',n)) == 1, varList) );

    varList = varList( ...
        cellfun(@(n) strcmp(evalin('base',sprintf('class(%s)',n)),'timeseries'), varList) );
end

assert(~isempty(varList), 'No timeseries found (debug_*).');

%% ---- constants to include if present ----
constNames = {};

for k = 1:numel(W)
    nm = W(k).name;

    if any(strcmpi(nm, {'RPM','Iq_Ref','IqRef','iq_ref'}))
        constNames{end+1} = nm; %#ok<AGROW>
    end
end

%% ---- ask user for folder name if not provided ----
if nargin < 3 || isempty(runName)

    prompt = sprintf([ ...
        '\nName this trial folder.\n', ...
        'Examples:\n', ...
        '  trial01\n', ...
        '  trial02\n', ...
        '  trial03\n', ...
        '  trial04\n\n', ...
        'Folder name: ']);

    runName = input(prompt, 's');

    if isempty(strtrim(runName))
        runName = 'trial01';
    end
end

% make folder name filesystem-safe
runName = strtrim(runName);
runName = regexprep(runName, '[^\w\-]', '_');

%% ---- output folder ----
if nargin < 2 || isempty(outDir)
    parentDir = pwd;
else
    parentDir = outDir;
end

% IMPORTANT:
% Create exactly <parentDir>\<runName>, no timestamp, no dyno_session prefix.
outDir = fullfile(parentDir, runName);

%% ---- handle existing folder ----
if exist(outDir, 'dir')
    overwriteChoice = input(sprintf( ...
        '\nFolder already exists:\n%s\nOverwrite files inside it? y/n: ', outDir), 's');

    if ~strcmpi(strtrim(overwriteChoice), 'y')
        error('Export cancelled. Folder already exists.');
    end
else
    mkdir(outDir);
end

%% ---- export debug_* to CSV and bundle struct ----
Bundle = struct();

for k = 1:numel(varList)
    vname = varList{k};
    ts = evalin('base', vname);

    t = double(ts.Time(:));
    y = double(ts.Data(:));

    T = table(t, y, 'VariableNames', {'time_s','value'});
    writetable(T, fullfile(outDir, [vname '.csv']));

    Bundle.(vname) = ts;
end

%% ---- save RPM / Iq_Ref / constants if present ----
for k = 1:numel(constNames)
    nm = constNames{k};
    val = evalin('base', nm);

    if isa(val,'timeseries')
        t = double(val.Time(:));
        y = double(val.Data(:));

        T = table(t, y, 'VariableNames', {'time_s','value'});
        writetable(T, fullfile(outDir, [nm '.csv']));
    else
        T = table(double(val), 'VariableNames', {'value'});
        writetable(T, fullfile(outDir, [nm '.csv']));
    end

    Bundle.(nm) = val;
end

%% ---- metadata file ----
metaFile = fullfile(outDir, 'session_info.txt');

fid = fopen(metaFile,'w');
fprintf(fid, 'Run name: %s\n', runName);
fprintf(fid, 'Export time: %s\n', datestr(now));
fprintf(fid, 'Output folder: %s\n', outDir);
fprintf(fid, 'Signals: %s\n', strjoin(varList, ', '));

if ~isempty(constNames)
    fprintf(fid, 'Constants: %s\n', strjoin(constNames, ', '));
end

fclose(fid);

%% ---- save MAT bundle ----
save(fullfile(outDir,'dyno_session.mat'), '-struct', 'Bundle', '-v7');

%% ---- readme ----
fid = fopen(fullfile(outDir,'README.txt'),'w');

fprintf(fid, 'Dyno session exported: %s\n', datestr(now));
fprintf(fid, 'Run name: %s\n', runName);
fprintf(fid, 'Output folder: %s\n', outDir);
fprintf(fid, '\n');
fprintf(fid, 'Signals exported: %s\n', strjoin(varList, ', '));

if ~isempty(constNames)
    fprintf(fid, 'Constants exported: %s\n', strjoin(constNames, ', '));
end

fprintf(fid, '\n');
fprintf(fid, 'CSV format:\n');
fprintf(fid, '  debug_* timeseries -> time_s,value\n');
fprintf(fid, '  constants -> value OR time_s,value\n');

fclose(fid);

fprintf('\nSaved %d debug signals (+%d constants) to:\n%s\n', ...
    numel(varList), numel(constNames), outDir);

end

