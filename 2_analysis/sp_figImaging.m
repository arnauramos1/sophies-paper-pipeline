function sp_figImaging(cfg)
% SP_FIGIMAGING  Behaviour of the mice that have usable EPM imaging, with the time dependency that decides
%  whether alprazolam is anxiolytic early and then stops being so.
%
%  THE SUBSET. Every one of the 63 cohort mice has raw and cropped EPM miniscope data, so "has imaging, even if
%  unprocessed" does not narrow anything. What narrows it is Sophie's own Included Imaging flag - the mice whose
%  lens, expression and recording quality make neurons recoverable. That is 25 mice: 12 vehicle, 8 DOI,
%  5 alprazolam and NO tabernanthalog, so TAB cannot enter any imaging experiment as things stand.
%
%  THE TIME TEST, and why it is done this way. Her pose pipeline gives a 5-min cut and a whole-session cut, not
%  arbitrary bins. The late window could be derived arithmetically, but that needs the exact session length her
%  "15min" file actually covers, and that is not recorded. So the test here is the per-mouse change from the
%  first 5 min to the whole session. That quantity is monotone in the late-window value, so it tests the same
%  hypothesis without assuming a session length: a drug whose effect is early-only must drift DOWN relative to
%  vehicle, and one whose effect is sustained must not.
%  Panel h adds the exact per-minute course from Arnau's DLC route, which has real frame times, for the imaging
%  mice where it exists (vehicle 12, alprazolam 5; DOI only 2, so DOI is omitted there and said so).
if nargin < 1 || isempty(cfg), cfg = sp_config(); end

E = sp_loadPose(cfg, '5min');  E = E.tbl;
W = sp_loadPose(cfg, '15min'); W = W.tbl;
IM = readtable(fullfile(cfg.code, '0_config', 'sp_imaging.csv'), 'VariableNamingRule', 'preserve');
keep = IM.mouse(IM.imaging_included == 1);
E = E(ismember(E.mouse, keep), :); W = W(ismember(W.mouse, keep), :);
[~, ia] = ismember(E.mouse, W.mouse); assert(all(ia > 0));
W = W(ia, :);

groups = {'Vehicle', 'DOI', 'Alprazolam'};
col = [0.35 0.35 0.38; 0.85 0.33 0.10; 0.00 0.45 0.74];
gi = zeros(height(E), 1);
for g = 1:numel(groups), gi(E.treatment == groups{g}) = g; end
E = E(gi > 0, :); W = W(gi > 0, :); gi = gi(gi > 0);
n = arrayfun(@(g) sum(gi == g), 1:numel(groups));

FH = 17.0;
f = figure('Units', 'centimeters', 'Position', [1 1 20 FH], 'Color', 'w', 'PaperPositionMode', 'auto');
AX = @(x, y, w, h) axes('Parent', f, 'Units', 'centimeters', 'Position', [x y w h], 'Box', 'off', ...
                        'TickDir', 'out', 'FontSize', 7, 'LineWidth', 0.6, 'Layer', 'top');
LB = @(x, y, s) annotation(f, 'textbox', [x/20 y/FH .04 .04], 'String', s, 'EdgeColor', 'none', ...
                        'FontWeight', 'bold', 'FontSize', 9, 'VerticalAlignment', 'middle');
R1 = 12.8; R2 = 8.1; R3 = 3.4;      % row baselines, cm

%% a. imaging availability
ax = AX(1.4, R1, 3.3, 3.2); hold(ax, 'on'); LB(0.45, R1 + 3.4, 'a');
allTx = {'Vehicle','DOI','Alprazolam','Tabernanthalog'};
tot = [22 13 14 14]; img = [12 8 5 0];
bar(ax, 1:4, tot, 0.62, 'FaceColor', [0.85 0.85 0.87], 'EdgeColor', 'none');
bar(ax, 1:4, img, 0.62, 'FaceColor', [0.25 0.25 0.3], 'EdgeColor', 'none');
for k = 1:4, text(ax, k, img(k) + 1.1, sprintf('%d', img(k)), 'HorizontalAlignment', 'center', 'FontSize', 7); end
set(ax, 'XTick', 1:4, 'XTickLabel', {'Veh','DOI','Alp','TAB'}, 'XLim', [0.4 4.6], 'YLim', [0 26]);
ylabel(ax, 'mice'); title(ax, {'imaging availability', 'grey = all, dark = usable'}, 'FontSize', 7.5, 'FontWeight', 'normal');

%% b-c-e. open-arm early, whole, change
dotPanel(AX(5.6, R1, 3.1, 3.2), E.pctOpen, gi, groups, col, 'open arm, first 5 min (%)', n); LB(4.75, R1 + 3.4, 'b');
dotPanel(AX(9.6, R1, 3.1, 3.2), W.pctOpen, gi, groups, col, 'open arm, whole session (%)', n); LB(8.75, R1 + 3.4, 'c');

% d. paired early -> whole
ax = AX(13.6, R1, 5.0, 3.2); hold(ax, 'on'); LB(12.75, R1 + 3.4, 'd');
for g = 1:numel(groups)
    q = gi == g; x = [1 2] + (g - 2)*0.26;
    plot(ax, x, [E.pctOpen(q) W.pctOpen(q)]', '-', 'Color', [col(g,:) 0.35], 'LineWidth', 0.5);
    plot(ax, x, median([E.pctOpen(q) W.pctOpen(q)]), '-o', 'Color', col(g,:), 'LineWidth', 1.6, ...
         'MarkerFaceColor', col(g,:), 'MarkerSize', 4);
end
set(ax, 'XTick', [1 2], 'XTickLabel', {'first 5 min', 'whole session'}, 'XLim', [0.5 2.5]);
ylabel(ax, 'open arm (%)'); title(ax, 'each mouse, early vs whole', 'FontSize', 7.5, 'FontWeight', 'normal');
for g = 1:numel(groups)
    text(ax, 2.33, median(W.pctOpen(gi == g)), groups{g}, 'Color', col(g,:), 'FontSize', 7);
end

%% e. the change, with P vs vehicle  <- the alprazolam question
d = W.pctOpen - E.pctOpen;
ax = dotPanel(AX(1.4, R2, 3.1, 3.2), d, gi, groups, col, 'change in open arm (pp)', n);
LB(0.45, R2 + 3.4, 'e'); yline(ax, 0, ':', 'Color', [0.5 0.5 0.5]);
pv = nan(1, numel(groups));
for g = 2:numel(groups)
    pv(g) = ranksum(d(gi == 1), d(gi == g));
    yl = ylim(ax);
    text(ax, g, yl(2) - 0.06*diff(yl), sprintf('P=%.3f', pv(g)), 'HorizontalAlignment', 'center', 'FontSize', 6.5);
end
title(ax, 'whole minus first 5 min', 'FontSize', 7.5, 'FontWeight', 'normal');

%% f-g. centre and head dips
dotPanel(AX(5.6, R2, 3.1, 3.2), W.pctCenter, gi, groups, col, 'centre, whole session (%)', n); LB(4.75, R2 + 3.4, 'f');
dotPanel(AX(9.6, R2, 3.1, 3.2), W.nHeadDips, gi, groups, col, 'head dips, whole session', n); LB(8.75, R2 + 3.4, 'g');

%% h. exact per-minute course from the DLC route
ax = AX(13.6, R2, 5.0, 3.2); hold(ax, 'on'); LB(12.75, R2 + 3.4, 'h');
P = perMinuteDLC(cfg, keep);
if isempty(P)
    text(ax, 0.5, 0.5, 'DLC route unavailable', 'Units', 'normalized', 'HorizontalAlignment', 'center', 'FontSize', 7);
    axis(ax, 'off');
else
    for g = [1 3]
        M = P.(groups{g});
        if isempty(M) || size(M, 1) < 3, continue; end
        md = median(M, 1, 'omitnan');
        lo = prctile(M, 25, 1); hi = prctile(M, 75, 1);
        x = 1:numel(md);
        fill(ax, [x fliplr(x)], [lo fliplr(hi)], col(g,:), 'FaceAlpha', 0.14, 'EdgeColor', 'none');
        plot(ax, x, md, '-o', 'Color', col(g,:), 'LineWidth', 1.4, 'MarkerFaceColor', col(g,:), 'MarkerSize', 3);
        text(ax, numel(md) + 0.15, md(end), sprintf('%s (n=%d)', groups{g}, size(M, 1)), 'Color', col(g,:), 'FontSize', 6.5);
    end
    xlabel(ax, 'minute of the session'); ylabel(ax, 'open arm (%)');
    set(ax, 'XLim', [0.5 13]);
    title(ax, {'exact per-minute course, DLC route', 'DOI omitted: only 2 imaging mice have DLC here'}, ...
          'FontSize', 7.5, 'FontWeight', 'normal');
end

%% ROW 3: is the imaging subset representative, and what do the FULL arms say?
EA = sp_loadPose(cfg, '5min');  EA = EA.tbl;
WA = sp_loadPose(cfg, '15min'); WA = WA.tbl;
[~, ja] = ismember(EA.mouse, WA.mouse); WA = WA(ja, :);
dA = WA.pctOpen - EA.pctOpen;
hasImg = ismember(EA.mouse, keep);

% i. selection check: alprazolam, imaging vs not
ax = AX(1.4, R3, 3.1, 3.2); hold(ax, 'on'); LB(0.45, R3 + 3.4, 'i');
qa = EA.treatment == "Alprazolam";
sets = {EA.pctOpen(qa & hasImg), EA.pctOpen(qa & ~hasImg)};
for s = 1:2
    v = sets{s}; jx = s + (rand(numel(v), 1) - 0.5)*0.26;
    fc = col(3,:); if s == 2, fc = 1 - 0.45*(1 - col(3,:)); end   % lighter fill for the no-imaging set
    plot(ax, jx, v, 'o', 'MarkerSize', 3.6, 'MarkerFaceColor', fc, 'MarkerEdgeColor', 'none');
    plot(ax, s + [-0.2 0.2], [median(v) median(v)], '-', 'Color', col(3,:), 'LineWidth', 1.8);
end
pSel = ranksum(sets{1}, sets{2});
set(ax, 'XTick', 1:2, 'XTickLabel', {sprintf('imaging\\newline n=%d', numel(sets{1})), ...
    sprintf('no imaging\\newline n=%d', numel(sets{2}))}, 'XLim', [0.45 2.55]);
ylabel(ax, 'open arm, first 5 min (%)');
title(ax, sprintf('alprazolam: is the subset\\newlinerepresentative?  P=%.2f', pSel), 'FontSize', 7.5, 'FontWeight', 'normal');

% j-k. the FULL arms, for comparison with b/c/e
giA = zeros(height(EA), 1);
for g = 1:numel(groups), giA(EA.treatment == groups{g}) = g; end
EA = EA(giA > 0, :); WA = WA(giA > 0, :); dA = dA(giA > 0); giA = giA(giA > 0);
nA = arrayfun(@(g) sum(giA == g), 1:numel(groups));
dotPanel(AX(5.6, R3, 3.1, 3.2), EA.pctOpen, giA, groups, col, 'open arm, first 5 min (%)', nA);
LB(4.75, R3 + 3.4, 'j'); title(gca, 'FULL arms, early', 'FontSize', 7.5, 'FontWeight', 'normal');
ax = dotPanel(AX(9.6, R3, 3.1, 3.2), dA, giA, groups, col, 'change in open arm (pp)', nA);
LB(8.75, R3 + 3.4, 'k'); yline(ax, 0, ':', 'Color', [0.5 0.5 0.5]);
for g = 2:numel(groups)
    p = ranksum(dA(giA == 1), dA(giA == g)); yl = ylim(ax);
    text(ax, g, yl(2) - 0.06*diff(yl), sprintf('P=%.3f', p), 'HorizontalAlignment', 'center', 'FontSize', 6.5);
end
title(ax, 'FULL arms, whole minus early', 'FontSize', 7.5, 'FontWeight', 'normal');

% l. summary text
ax = AX(13.6, R3, 5.0, 3.2); axis(ax, 'off'); LB(12.75, R3 + 3.4, 'l');
pE = @(g) ranksum(EA.pctOpen(giA == 1), EA.pctOpen(giA == g));
pD = @(g) ranksum(dA(giA == 1), dA(giA == g));
txt = { 'Does alprazolam show anxiolysis at first?', '', ...
    sprintf('FULL arm (n=%d vs %d vehicle)', nA(3), nA(1)), ...
    sprintf('   first 5 min   %.1f vs %.1f %%   P = %.3f', median(EA.pctOpen(giA==3)), median(EA.pctOpen(giA==1)), pE(3)), ...
    sprintf('   time change   %+.1f vs %+.1f pp   P = %.3f', median(dA(giA==3)), median(dA(giA==1)), pD(3)), '', ...
    sprintf('IMAGING subset (n=%d vs %d vehicle)', n(3), n(1)), ...
    sprintf('   first 5 min   %.1f vs %.1f %%   P = %.3f', median(E.pctOpen(gi==3)), median(E.pctOpen(gi==1)), ...
            ranksum(E.pctOpen(gi==1), E.pctOpen(gi==3))), ...
    sprintf('   time change   %+.1f vs %+.1f pp   P = %.3f', median(d(gi==3)), median(d(gi==1)), pv(3)), '', ...
    'The time dependency is the robust effect.', 'The early rise is not significant, and the', ...
    'five imaging mice do not show it at all.'};
text(ax, 0, 1, txt, 'Units', 'normalized', 'VerticalAlignment', 'top', 'FontSize', 7, 'Interpreter', 'none');

annotation(f, 'textbox', [0.012 0.002 0.98 0.038], 'EdgeColor', 'none', 'FontSize', 6.5, ...
    'Color', [0.3 0.3 0.3], 'String', sprintf(['a-h: mice with usable EPM imaging (Sophie Included Imaging = Yes): ' ...
    'vehicle %d, DOI %d, alprazolam %d, tabernanthalog 0 - TAB cannot enter an imaging experiment. ' ...
    'i-l: the full arms, for comparison. Behaviour from her pose pipeline except panel h (DLC route). ' ...
    'Dots are mice, bars medians, Mann-Whitney vs vehicle, no multiplicity correction.'], n(1), n(2), n(3)));

if ~isfolder(cfg.figDir), mkdir(cfg.figDir); end
out = fullfile(cfg.figDir, 'sp_imagingSubset_behaviour.png');
print(f, out, '-dpng', '-r300'); close(f);
fprintf('wrote %s\n', out);

fprintf('\n--- imaging subset, open arm ---\n%-12s %4s %10s %10s %10s\n', 'group','n','first5','whole','change');
for g = 1:numel(groups)
    q = gi == g;
    fprintf('%-12s %4d %10.2f %10.2f %+10.2f\n', groups{g}, sum(q), median(E.pctOpen(q)), median(W.pctOpen(q)), median(d(q)));
end
for g = 2:numel(groups)
    fprintf('%s vs vehicle: first5 P=%.3f | whole P=%.3f | CHANGE P=%.3f\n', groups{g}, ...
        ranksum(E.pctOpen(gi==1), E.pctOpen(gi==g)), ranksum(W.pctOpen(gi==1), W.pctOpen(gi==g)), pv(g));
end
end

function ax = dotPanel(ax, y, gi, groups, col, ylab, n)
hold(ax, 'on'); y = double(y);
for g = 1:numel(groups)
    q = gi == g; v = y(q); v = v(isfinite(v));
    if isempty(v), continue; end
    jx = g + (rand(numel(v), 1) - 0.5)*0.26;
    plot(ax, jx, v, 'o', 'MarkerSize', 3.4, 'MarkerFaceColor', col(g,:), 'MarkerEdgeColor', 'none');
    plot(ax, g + [-0.2 0.2], [median(v) median(v)], '-', 'Color', col(g,:), 'LineWidth', 1.8);
end
set(ax, 'XTick', 1:numel(groups), 'XTickLabel', ...
    arrayfun(@(g) sprintf('%s\\newline n=%d', shortName(groups{g}), n(g)), 1:numel(groups), 'uni', 0), ...
    'XLim', [0.45 numel(groups) + 0.55]);
ylabel(ax, ylab);
end

function s = shortName(g)
switch g, case 'Vehicle', s = 'Veh'; case 'Alprazolam', s = 'Alp'; otherwise, s = g; end
end

function P = perMinuteDLC(cfg, keep)
% exact per-minute open-arm % from Arnau's DLC route, for the imaging mice that have it
P = [];
bd = [cfg.root 'Data\Analysis\EPM_AA_paper\_pool_epm\4_behaviour\'];
if ~isfolder(bd), return; end
A = sp_animals(cfg); T = A.tbl;
P = struct('Vehicle', [], 'DOI', [], 'Alprazolam', []);
L = dir([bd '*_EPMbeh.mat']);
for k = 1:numel(L)
    S = load(fullfile(bd, L(k).name), 'E'); Eb = S.E;
    if ~ismember(Eb.mouse, keep), continue; end
    j = T.mouse == Eb.mouse; if ~any(j), continue; end
    tx = char(T.treatment(j)); if ~isfield(P, tx), continue; end
    vts = readmatrix(Eb.files.videoTS); vts = vts(:, 1);
    z = double(Eb.dlc_zone); nf = min(numel(vts), numel(z));
    rel = (vts(1:nf) - Eb.beh_testStart)/1000; z = z(1:nf);
    val = Eb.dlc_inTest(1:nf) & Eb.dlc_tracked(1:nf) & z > 0;
    row = nan(1, 12);
    for m = 0:11
        s = val & rel >= m*60 & rel < (m+1)*60;
        if sum(s) >= 50, row(m+1) = 100*sum(z(s) == 2)/sum(s); end
    end
    P.(tx) = [P.(tx); row];
end
end
