function outDir = save_debug_session(varList, outDir)
% Save debug_* timeseries to CSV + MAT and also save RPM / Iq_Ref if present.
% USAGE:
%   save_debug_session
%   save_debug_session({'debug_1','debug_2'})
%   save_debug_session([], 'C:\logs\my_run')

W = evalin('base','whos');

% ---- discover debug_* timeseries ----
isTS = strcmp({W.class}, 'timeseries');
if nargin < 1 || isempty(varList)
    names = {W(isTS).name};
    varList = names(startsWith(names,'debug_','IgnoreCase',true));
else
    varList = varList(:)';
    varList = varList( ...
        cellfun(@(n) evalin('base',sprintf('exist(''%s'',''var'')',n))==1, varList) );
    varList = varList( ...
        cellfun(@(n) strcmp(evalin('base',['class(' n ')']),'timeseries'), varList) );
end
assert(~isempty(varList), 'No timeseries found (debug_*).');

% ---- constants to include if present (scalar or timeseries) ----
constNames = {};
for k = 1:numel(W)
    nm = W(k).name;
    if any(strcmpi(nm, {'RPM','Iq_Ref','IqRef','iq_ref'}))
        constNames{end+1} = nm; %#ok<AGROW>
    end
end

% ---- output folder ----
if nargin < 2 || isempty(outDir)
    outDir = fullfile(pwd, ['dyno_session_' datestr(now,'yyyymmdd_HHMMSS')]);
end
if ~exist(outDir,'dir'), mkdir(outDir); end

% ---- export debug_* to CSV and bundle struct ----
Bundle = struct();
for k = 1:numel(varList)
    vname = varList{k};
    ts    = evalin('base', vname);
    t     = double(ts.Time(:));
    y     = double(ts.Data(:));
    T = table(t, y, 'VariableNames', {'time_s','value'});
    writetable(T, fullfile(outDir, [vname '.csv']));
    Bundle.(vname) = ts;
end

% ---- save RPM / Iq_Ref (scalar or timeseries) ----
for k = 1:numel(constNames)
    nm = constNames{k};
    val = evalin('base', nm);
    if isa(val,'timeseries')
        t = double(val.Time(:)); y = double(val.Data(:));
        T = table(t, y, 'VariableNames', {'time_s','value'});
        writetable(T, fullfile(outDir, [nm '.csv']));
    else
        T = table(double(val), 'VariableNames', {'value'});
        writetable(T, fullfile(outDir, [nm '.csv']));
    end
    Bundle.(nm) = val; %#ok<STRNU>
end

% ---- save MAT bundle ----
save(fullfile(outDir,'dyno_session.mat'), '-struct', 'Bundle', '-v7');

% ---- readme ----
fid = fopen(fullfile(outDir,'README.txt'),'w');
fprintf(fid, 'Dyno session exported: %s\n', datestr(now));
fprintf(fid, 'Signals: %s\n', strjoin(varList, ', '));
if ~isempty(constNames)
    fprintf(fid, 'Constants: %s\n', strjoin(constNames, ', '));
end
fprintf(fid, 'CSV format: debug_* -> time_s,value; constants -> value OR time_s,value\n');
fclose(fid);

fprintf('Saved %d debug signals (+%d constants) to %s\n', numel(varList), numel(constNames), outDir);
end
