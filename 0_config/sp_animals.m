function A = sp_animals(cfg)
% SP_ANIMALS  The cohort of SophiesPaper, read from 0_config\sp_animals.csv - the ONLY place where a mouse is
%  assigned a treatment or excluded. Frozen from Sophie's Notion Experiment database (Mice table) on 14 Nov 2026.
%
%  A CSV rather than an xlsx on purpose: it diffs in git, and it cannot be left locked by an open Excel window.
%  Open it in Excel freely; just save it back as CSV.
%
%  Columns
%   mouse                 numeric id (her database writes them as ALU-0XXXX)
%   treatment             Vehicle | DOI | Alprazolam | Tabernanthalog, taken from the EPM-prefixed token of her
%                         Group field ONLY. EPMVehTWAALVehTWAAEDOI2 is a VEHICLE mouse on the maze.
%   dose_mg_kg            2 for DOI, 0.5 for alprazolam, 10 or 50 for tabernanthalog, blank for vehicle
%   solvent               where known; NOT matched across batches, which is a real confound
%   batch                 A11 (Arnau's batch11), S3, A15 (Arnau's batch15), E1
%   condition             Master | Yoked | blank, for the A15 Master/Yoked mice
%   excl_epm_sophie       her own Excl. EPM flag
%   pose_sophie           which of her pose summaries the mouse is in (A11 or S3)
%   dlc_in_arnau_folders  1 if video timestamps AND a DLC csv are present in Arnau's own folders
%   imaging_included      her Included Imaging flag
%   group_string          her full Group string, kept verbatim so the parse can always be re-checked
%
%  Output
%   A.tbl                 the whole table, after exclusions
%   A.all                 the table before exclusions
%   A.<treatment>         ids per treatment, e.g. A.Vehicle, A.DOI, A.Alprazolam, A.Tabernanthalog
%   A.byBatch.<t>.<b>     ids per treatment and batch
%   A.excluded            ids dropped, with reasons
if nargin < 1, cfg = sp_config(); end
T = readtable(cfg.animalsFile, 'TextType', 'string', 'VariableNamingRule', 'preserve');
% Blank vehicle doses make readtable type this column numeric, which then will not compare against strings.
% Normalise it to string once, here, so every downstream comparison is string-to-string.
if ~isstring(T.dose_mg_kg)
    d = string(T.dose_mg_kg); d(ismissing(d) | d == "NaN") = ""; T.dose_mg_kg = d;
end
A.all = T;

drop = []; why = strings(0);
if cfg.useSophieExclusions
    q = T.excl_epm_sophie == "Yes";
    drop = [drop; T.mouse(q)]; why = [why; repmat("Excl. EPM = Yes (Sophie)", sum(q), 1)];
end
if ~isempty(cfg.extraExclude)
    q = ismember(T.mouse, cfg.extraExclude);
    drop = [drop; T.mouse(q)]; why = [why; repmat("cfg.extraExclude", sum(q), 1)];
end
q = T.treatment == "unassigned" | T.treatment == "unknown";
drop = [drop; T.mouse(q)]; why = [why; repmat("no EPM treatment in her Group field", sum(q), 1)];
[drop, ia] = unique(drop, 'stable'); why = why(ia);
A.excluded = table(drop, why, 'VariableNames', {'mouse', 'reason'});
A.tbl = T(~ismember(T.mouse, drop), :);

for t = cfg.treatments
    A.(t{1}) = A.tbl.mouse(A.tbl.treatment == t{1})';
    for b = unique(A.tbl.batch)'
        ids = A.tbl.mouse(A.tbl.treatment == t{1} & A.tbl.batch == b)';
        if ~isempty(ids), A.byBatch.(t{1}).(char(b)) = ids; end
    end
end

if nargout == 0 || true
    fprintf('SophiesPaper cohort (%s)\n', cfg.allocationSource);
    for t = cfg.treatments
        ids = A.(t{1}); if isempty(ids), continue; end
        d = unique(A.tbl.dose_mg_kg(A.tbl.treatment == t{1}));
        d = d(~ismissing(d) & d ~= ""); ds = '-'; if ~isempty(d), ds = char(strjoin(d', '/')); end
        fprintf('  %-16s n=%2d  dose %-7s  batches %s\n', t{1}, numel(ids), ds, ...
            strjoin(unique(A.tbl.batch(A.tbl.treatment == t{1}))', ' '));
    end
    if height(A.excluded)
        fprintf('  excluded: %s\n', strjoin(compose('%d (%s)', A.excluded.mouse, A.excluded.reason)', '; '));
    end
end
end
