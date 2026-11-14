function B = sp_loadPose(cfg, cut)
% SP_LOADPOSE  Sophie's own pose-pipeline EPM summaries for the whole cohort, joined to treatment.
%  READ-ONLY on her analysis tree. This function never writes under cfg.poseRoot.
%
%  Her pipeline produces 30 measures per mouse per cut (5min and 15min), including protected and unprotected head
%  dips, the arm-transition matrix and transition entropy. Her A11 and S3 summaries are separate files; the A15
%  (batch15) mice sit inside her S3 EPM block, because that EPM was run as part of the same session block.
%
%  IMPORTANT. These numbers are NOT interchangeable with Arnau's DLC route (sp_stage4): different pose estimation
%  and different zone geometry, e.g. 9567 pctOpen 11.6 % here against 18.3 % there. B.source records which is
%  which; never put the two in one figure.
%
%  B.tbl   one row per mouse: treatment, dose, batch, condition + her measures
%  B.cut   '5min' | '15min'
%  B.source 'pose (Sophie python pipeline)'
%  B.missing ids in the cohort with no row in her summaries
if nargin < 1, cfg = sp_config(); end
if nargin < 2, cut = cfg.poseCut; end
assert(cfg.poseFile.isKey(cut), 'sp_loadPose: unknown cut "%s"', cut);

A = sp_animals(cfg); C = A.tbl;
S = table();
for b = cfg.poseBatchDir.keys
    f = fullfile(cfg.poseRoot, cfg.poseBatchDir(b{1}), cfg.poseFile(cut));
    if ~isfile(f)
        fprintf('sp_loadPose: missing %s\n', f); continue
    end
    t = readtable(f, 'VariableNamingRule', 'preserve');
    t.poseBatchFile = repmat(string(cfg.poseBatchDir(b{1})), height(t), 1);
    S = [S; t]; %#ok<AGROW>
end
assert(~isempty(S), 'sp_loadPose: no pose summaries found under %s', cfg.poseRoot);
S.Properties.VariableNames{strcmp(S.Properties.VariableNames, 'animalID')} = 'mouse';
S = S(ismember(S.mouse, C.mouse), :);
[~, ia] = unique(S.mouse, 'stable'); S = S(ia, :);          % a mouse can appear in two of her files

meta = C(:, {'mouse','treatment','dose_mg_kg','solvent','batch','condition','imaging_included'});
B.tbl = innerjoin(meta, S, 'Keys', 'mouse');
B.cut = cut;
B.source = 'pose (Sophie python pipeline)';
B.missing = setdiff(C.mouse, S.mouse)';
B.file = cfg.poseFile(cut);

fprintf('sp_loadPose [%s, %s]: %d of %d cohort mice\n', cut, B.source, height(B.tbl), height(C));
for t = cfg.treatments
    n = sum(B.tbl.treatment == t{1}); if n, fprintf('  %-16s %d\n', t{1}, n); end
end
if ~isempty(B.missing), fprintf('  no pose row for: %s\n', mat2str(B.missing)); end
end
