function D = sp_engineCheck(cfg)
% SP_ENGINECHECK  Compare SophiesPaper\_engine\ against the live EPM_AA_paper it was copied from, and report
%  drift. Run this before any analysis that will be published.
%
%  Four outcomes per file:
%    same     the copy matches the live file - nothing to do
%    DRIFTED  the live file has changed since the copy was taken. Arnau may have fixed a bug this project still
%             has, or changed behaviour this project should NOT inherit. Decide deliberately, then either
%             re-copy with sp_makeEngine(cfg, true) or record why not.
%    EDITED   the copy itself was changed after being recorded in the manifest. Intentional divergence is fine,
%             but it must be deliberate - a copy edited by accident is the worst case.
%    gone     the source file no longer exists upstream (renamed or deleted).
%
%  Nothing is copied or changed by this function.
if nargin < 1 || isempty(cfg), cfg = sp_config(); end
assert(isfile(cfg.engineManifest), 'no manifest at %s - run sp_makeEngine first', cfg.engineManifest);
M = readtable(cfg.engineManifest, 'TextType', 'string', 'VariableNamingRule', 'preserve');

st = strings(height(M), 1);
for i = 1:height(M)
    d = fullfile(cfg.engineDir, M.engineFile(i));
    s = fullfile(cfg.engineSource, M.sourceRelPath(i));
    if ~isfile(d), st(i) = "copy missing"; continue; end
    hd = md5(d);
    if hd ~= M.md5(i), st(i) = "EDITED"; continue; end      % local copy changed since recorded
    if ~isfile(s), st(i) = "gone upstream"; continue; end
    if md5(s) ~= M.md5(i), st(i) = "DRIFTED"; else, st(i) = "same"; end
end
D = M(:, {'engineFile', 'sourceRelPath', 'sourceCommit'}); D.status = st;

n = @(s) sum(st == s);
fprintf('\nsp_engineCheck  %s\n  vs %s\n', cfg.engineDir, cfg.engineSource);
fprintf('  same %d | DRIFTED %d | EDITED %d | gone upstream %d | copy missing %d  (of %d)\n\n', ...
    n("same"), n("DRIFTED"), n("EDITED"), n("gone upstream"), n("copy missing"), height(M));
bad = D(st ~= "same", :);
if isempty(bad)
    fprintf('  engine is identical to the live pipeline.\n');
else
    for i = 1:height(bad)
        fprintf('  %-10s %-26s (from %s)\n', bad.status(i), bad.engineFile(i), bad.sourceRelPath(i));
    end
    fprintf('\n  DRIFTED: decide whether to pull the change across - sp_makeEngine(cfg, true) re-copies ALL files.\n');
    fprintf('  EDITED : this project''s copy was changed locally. If deliberate, re-record it with sp_makeEngine.\n');
end
if ~isfolder(cfg.anaDir), mkdir(cfg.anaDir); end
writetable(D, fullfile(cfg.anaDir, 'sp_engineCheck.csv'));
end

function h = md5(f)
fid = fopen(f, 'r'); b = fread(fid, '*uint8'); fclose(fid);
b(b == 13) = [];
while ~isempty(b) && any(b(end) == [32 9 10 13]), b(end) = []; end
d = java.security.MessageDigest.getInstance('MD5');
h = string(lower(reshape(dec2hex(typecast(d.digest(b), 'uint8') + 0)', 1, [])));
end
