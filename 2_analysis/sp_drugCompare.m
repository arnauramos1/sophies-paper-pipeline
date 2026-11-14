function R = sp_drugCompare(cfg, cut, measures)
% SP_DRUGCOMPARE  Vehicle vs DOI vs alprazolam vs tabernanthalog on the EPM, on Sophie's pose measures.
%
%  THE DESIGN PROBLEM THIS IS BUILT AROUND. Each drug lives in its own batch or batches, and the vehicle arms
%  themselves differ between batches (on Arnau's DLC route: open-arm 7.2 % in A11 against 12.7 % in the August
%  batches, P = 0.029; closed-arm P = 0.020, with locomotion identical). Vehicle solvent also differs - 0.9 % NaCl
%  in A11, 2.5 % DMSO in S3/A15. So "drug" is partly confounded with batch, and a straight four-group test would
%  hand batch differences to the drugs.
%
%  Therefore, in order:
%    1. VEHICLE-ONLY batch test. With cfg.batchPoolTest = true, pooling is refused for any measure on which the
%       vehicle arms differ, and that measure is reported within-batch only.
%    2. each drug against the vehicle arm OF ITS OWN BATCH (or batches).
%    3. a four-group table, clearly marked descriptive, for the measures that passed step 1.
%
%  Statistics from first principles: all tests are rank-based (Mann-Whitney / Kruskal-Wallis), which ask whether
%  values from one group tend to sit above values from the other when all are put in one ordered list. No
%  normality is assumed, which matters at these group sizes. With n of 7-22 per arm, a P near 0.05 is weak
%  evidence; the per-mouse values are printed so the overlap can be judged by eye.
if nargin < 1 || isempty(cfg), cfg = sp_config(); end
if nargin < 2 || isempty(cut), cut = cfg.poseCut; end
if nargin < 3 || isempty(measures)
    measures = {'pctOpen','pctClosed','pctCenter','nOpenEntries','nHeadDips','nHeadDipsUnprotected', ...
                'nHeadDipsProtected','totalDistanceCm','meanVelocityCmPerS','latencyOpenSec', ...
                'transitionEntropyBits','pClosedToOpen'};
end
B = sp_loadPose(cfg, cut); T = B.tbl;
measures = measures(ismember(measures, T.Properties.VariableNames));
ref = cfg.refTreatment;

isTx = @(t) T.treatment == t;
batchesOf = @(t) unique(T.batch(isTx(t)))';

fprintf('\n################ SophiesPaper drug comparison [%s, %s] ################\n', cut, B.source);

%% 1. vehicle-only batch test
fprintf('\n--- 1. vehicle arms across batches (pooling is only valid where these agree) ---\n');
vb = unique(T.batch(isTx(ref)))';
vcounts = arrayfun(@(b) sum(isTx(ref) & T.batch == b), vb);
vb = vb(vcounts >= 3);   % only batches with enough vehicle mice to test
fprintf('vehicle arms with n>=3: %s\n', strjoin(compose('%s (n=%d)', vb', arrayfun(@(b) sum(isTx(ref) & T.batch==b), vb)')', ', '));
poolOK = true(1, numel(measures));
if numel(vb) >= 2
    fprintf('%-24s', 'measure');
    fprintf('%14s', vb{:}); fprintf('%10s %8s\n', 'P', 'pool?');
    for k = 1:numel(measures)
        g = arrayfun(@(b) {double(T.(measures{k})(isTx(ref) & T.batch == b))}, vb);
        g = cellfun(@(x) {x(isfinite(x))}, g);
        if numel(vb) == 2, p = ranksum(g{1}, g{2});
        else, grp = []; val = []; for q = 1:numel(g), val = [val; g{q}]; grp = [grp; repmat(q, numel(g{q}), 1)]; end
              p = kruskalwallis(val, grp, 'off'); end
        poolOK(k) = p >= cfg.alpha;
        fprintf('%-24s', measures{k}); fprintf('%14.2f', cellfun(@median, g));
        fprintf('%10.3f %8s\n', p, char(string(poolOK(k))));
    end
else
    fprintf('(only one vehicle arm with n>=3; no batch test possible)\n');
end
if cfg.batchPoolTest
    fprintf('\nMeasures that may be pooled across batches: %s\n', strjoin(measures(poolOK), ', '));
    fprintf('Measures that may NOT (within-batch only): %s\n', strjoin(measures(~poolOK), ', '));
end

%% 2. each drug against its own batch's vehicle
fprintf('\n--- 2. each drug against the vehicle arm of its own batch(es) ---\n');
R = struct([]); n = 0;
for t = setdiff(cfg.treatments, {ref})
    tn = t{1}; if ~any(isTx(tn)), continue; end
    for dose = unique(T.dose_mg_kg(isTx(tn)))'
        sel = isTx(tn) & T.dose_mg_kg == dose;
        bs = unique(T.batch(sel))';
        vsel = isTx(ref) & ismember(T.batch, bs);
        if sum(vsel) < 3   % no vehicle in that batch: fall back to all vehicle and say so
            vsel = isTx(ref);
            note = sprintf('no vehicle arm in %s; compared against ALL vehicle - confounded', strjoin(bs, '+'));
        else
            note = sprintf('vehicle from %s', strjoin(unique(T.batch(vsel))', '+'));
        end
        fprintf('\n%s %s mg/kg (n=%d, %s) vs vehicle (n=%d) [%s]\n', tn, dose, sum(sel), strjoin(bs,'+'), sum(vsel), note);
        fprintf('  %-24s %10s %10s %8s\n', 'measure', 'vehicle', tn, 'P');
        for k = 1:numel(measures)
            x = double(T.(measures{k})(vsel)); y = double(T.(measures{k})(sel));
            x = x(isfinite(x)); y = y(isfinite(y));
            if numel(x) < 3 || numel(y) < 3, continue; end
            p = ranksum(x, y);
            star = ''; if p < cfg.alpha, star = ' *'; end
            fprintf('  %-24s %10.2f %10.2f %8.3f%s\n', measures{k}, median(x), median(y), p, star);
            n = n + 1;
            R(n).treatment = tn; R(n).dose = dose; R(n).measure = measures{k};
            R(n).nVeh = numel(x); R(n).nDrug = numel(y);
            R(n).medVeh = median(x); R(n).medDrug = median(y); R(n).p = p;
            R(n).batches = strjoin(bs, '+'); R(n).note = note; R(n).poolable = poolOK(k);
        end
    end
end

%% 3. four-group descriptive
fprintf('\n--- 3. all treatments together (descriptive; batch-confounded where pool? was false) ---\n');
fprintf('%-24s', 'measure');
for t = cfg.treatments, fprintf('%14s', t{1}); end
fprintf('%10s %8s\n', 'KW P', 'pool?');
for k = 1:numel(measures)
    val = []; grp = []; med = nan(1, numel(cfg.treatments));
    for q = 1:numel(cfg.treatments)
        x = double(T.(measures{k})(isTx(cfg.treatments{q}))); x = x(isfinite(x));
        med(q) = median(x); val = [val; x]; grp = [grp; repmat(q, numel(x), 1)]; %#ok<AGROW>
    end
    p = NaN; if numel(unique(grp)) > 1, p = kruskalwallis(val, grp, 'off'); end
    fprintf('%-24s', measures{k}); fprintf('%14.2f', med);
    fprintf('%10.3f %8s\n', p, char(string(poolOK(k))));
end

if ~isempty(R)
    Rt = struct2table(R);
    if ~isfolder(cfg.anaDir), mkdir(cfg.anaDir); end
    writetable(Rt, fullfile(cfg.anaDir, sprintf('sp_drugCompare_%s.csv', cut)));
    save(fullfile(cfg.anaDir, sprintf('sp_drugCompare_%s.mat', cut)), 'Rt', 'T', 'cut');
    fprintf('\nwrote %s\n', fullfile(cfg.anaDir, sprintf('sp_drugCompare_%s.csv', cut)));
end
fprintf('\nNOTE: %d drug x measure tests with no multiplicity correction. Treat single P values near 0.05 as\n', n);
fprintf('weak evidence, and prefer measures that move together across cuts (5min and 15min) and batches.\n');
fprintf('=== SP_DRUGCOMPARE DONE\n');
end
