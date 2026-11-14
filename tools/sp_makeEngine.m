function sp_makeEngine(cfg, force)
% SP_MAKEENGINE  Copy the shared processing functions from Arnau's EPM_AA_paper into SophiesPaper\_engine\ and
%  record exactly what was copied in MANIFEST.csv (relative source path, md5, bytes, source file date, and the
%  originating git commit if one can be read).
%
%  WHY COPY AT ALL. Arnau develops EPM_AA_paper actively and pushes to it from more than one machine. If this
%  project referenced his live code, Sophie's published numbers could change without anyone touching this repo.
%  Copying freezes them.
%
%  WHY A MANIFEST. The cost of copying is silent divergence - a bug fixed in his pipeline stays broken here, and
%  nobody notices. The manifest plus sp_engineCheck makes divergence visible, so pulling a fix across is a
%  deliberate act with a record. Run sp_engineCheck before any analysis that will be published.
%
%  Only the functions this project actually uses are copied. His pipeline is 273 files; the rest is imaging,
%  heart rate, opto, validation and figure code that SophiesPaper does not touch.
if nargin < 1 || isempty(cfg), cfg = sp_config(); end
if nargin < 2, force = false; end

FILES = { ...
    '0_config\EPM_config.m', '0_config\epmaa_path.m', '0_config\epmaa_config.m', ...
    '4_behaviour\functions\EPM_dlcBehavior.m', '4_behaviour\functions\EPM_zones.m', ...
    '4_behaviour\functions\EPM_transitions.m', '4_behaviour\functions\EPM_mapFiles.m', ...
    '4_behaviour\functions\EPM_groupOf.m', '4_behaviour\functions\EPM_trackingQC.m', ...
    '4_behaviour\functions\EPM_qcFigure.m', '4_behaviour\functions\EPM_resample20.m', ...
    '4_behaviour\functions\EPM_processMouse.m', '4_behaviour\functions\EPM_syncTraces.m', ...
    'lib\pp_ax.m', 'lib\pp_fig.m', 'lib\pp_s.m', 'lib\pp_style.m', 'lib\pp_box.m', ...
    'lib\pp_paired.m', 'lib\pp_sig.m', 'lib\pp_pstr.m', 'lib\pp_title.m', 'lib\pp_save.m', ...
    'lib\pp_txt.m', 'lib\pp_trace.m', 'lib\pp_band.m', 'lib\pp_cstat.m'};

src = cfg.engineSource; dst = cfg.engineDir;
if ~isfolder(dst), mkdir(dst); end
commit = gitCommit(src);

rows = {}; nCopied = 0; nSkipped = 0;
for i = 1:numel(FILES)
    rel = FILES{i}; s = fullfile(src, rel);
    if ~isfile(s), fprintf('MISSING in source: %s\n', rel); continue; end
    [~, nm, ex] = fileparts(rel); flat = [nm ex];
    d = fullfile(dst, flat);
    if isfile(d) && ~force
        nSkipped = nSkipped + 1;
    else
        copyfile(s, d); nCopied = nCopied + 1;
    end
    info = dir(d);
    rows{end+1} = {flat, rel, md5(d), info.bytes, datestr(dir(s).datenum, 'yyyy-mm-dd HH:MM'), commit}; %#ok<AGROW>
end
M = cell2table(vertcat(rows{:}), 'VariableNames', ...
    {'engineFile', 'sourceRelPath', 'md5', 'bytes', 'sourceFileDate', 'sourceCommit'});
writetable(M, cfg.engineManifest);
fprintf('sp_makeEngine: %d copied, %d already present, %d recorded\n', nCopied, nSkipped, height(M));
fprintf('  source : %s (commit %s)\n  engine : %s\n  manifest: %s\n', src, commit, dst, cfg.engineManifest);
fprintf('Run sp_engineCheck before publishing anything built on these.\n');
end

function h = md5(f)
fid = fopen(f, 'r'); b = fread(fid, '*uint8'); fclose(fid);
b(b == 13) = [];                                     % normalise CRLF so Windows/Unix copies compare equal
while ~isempty(b) && any(b(end) == [32 9 10 13]), b(end) = []; end
d = java.security.MessageDigest.getInstance('MD5');
h = lower(reshape(dec2hex(typecast(d.digest(b), 'uint8') + 0)', 1, []));
end

function c = gitCommit(p)
c = 'unknown';
try
    [st, out] = system(sprintf('git -C "%s" rev-parse --short HEAD', p));
    if st == 0 && ~isempty(strtrim(out)), c = strtrim(out); end
catch
end
if strcmp(c, 'unknown')
    % the deployed tree on tachyon is not a git checkout; the repo lives elsewhere, so record the date instead
    c = ['no-git-' datestr(now, 'yyyy-mm-dd')]; %#ok<TNOW1,DATST>
end
end
