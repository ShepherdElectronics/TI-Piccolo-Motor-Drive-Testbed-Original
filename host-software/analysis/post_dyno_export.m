function post_dyno_export
% Called automatically at sim stop. Saves debug_* logs and RPM/Iq_Ref scalars.

% --- harvest constants (scalar or timeseries -> scalar) ---
RPM   = get_const_or_scalar('RPM');     %#ok<NASGU>
Iq_Ref = get_const_or_scalar('Iq_Ref'); %#ok<NASGU>

% Re-inject as scalars so the exporter and plots see them cleanly
if ~isempty(RPM),   assignin('base','RPM',   RPM);   end
if ~isempty(Iq_Ref),assignin('base','Iq_Ref',Iq_Ref);end

% --- export session ---
try
    save_debug_session;  % your fixed exporter (grabs debug_* + constants)
    fprintf('post_dyno_export: session saved.\n');
catch ME
    warning('post_dyno_export: save failed: %s', ME.message);
end

% OPTIONAL: make a plot right away (comment out if you don’t want it)
try
    plot_dyno_efficiency_annotated;  % your plotting script with annotation
catch ME
    warning('post_dyno_export: plot failed: %s', ME.message);
end
end

function val = get_const_or_scalar(name)
% Return a scalar for "name" if it exists (scalar or timeseries). [] if missing.
if ~evalin('base', sprintf('exist(''%s'',''var'')', name)), val = []; return; end
v = evalin('base', name);
if isa(v,'timeseries')
    d = double(v.Data(:));
    val = median(d,'omitnan');       % robust for constant TS
elseif isnumeric(v)
    val = double(v(1));              % scalar or first element
else
    val = [];
end
end
