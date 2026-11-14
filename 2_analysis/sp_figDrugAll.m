function sp_figDrugAll(cfg)
% SP_FIGDRUGALL  Every mouse with EPM behaviour, pooled across batches, no imaging filter:
%  vehicle vs DOI vs alprazolam vs tabernanthalog, with the time dimension.
%
%  WHAT IS IN AND WHAT IS NOT. Her database holds 159 mice with a drug at the EPM across nine batches, but
%  tracking output exists for only some of them:
%     her pose pipeline  : A11 (16) and the S3 block (50, which contains the A15 mice) -> 66, all four treatments
%     Arnau's DLC route  : A11 and A15 only (60 of the 159 have a DLC csv in his folders)
%     no tracking at all : A9 (6 DOI), A13 (8 alprazolam 0.25), S1 (10 alprazolam), S4, S5 (10 of compound 50615)
%  A9, A13 and E1 have videos and Bonsai timestamps but no DLC; S1 has neither in Arnau's folders. Adding them
%  means running DeepLabCut on ~100 videos, or getting her tracking for those batches.
%  This figure therefore uses HER pose pipeline, which is the only source covering all four treatments, and says
%  so. It never mixes in the DLC route: the two disagree systematically (open-arm x0.73, head dips x2.12).
%
%  THE BATCH CONFOUND. DOI is A11 + S3, alprazolam is A15 + S3, TAB is E1 only, and the vehicle arms differ
%  between A11 and the August batches (open-arm 5.97 vs 11.61 %, P = 0.023). Panels f-h therefore show each drug
%  as a difference from the vehicle arm OF ITS OWN BATCH, which is the only batch-safe comparison.
if nargin < 1 || isempty(cfg), cfg = sp_config(); end

E = sp_loadPose(cfg, '5min');  E = E.tbl;
W = sp_loadPose(cfg, '15min'); W = W.tbl;
[~, ia] = ismember(E.mouse, W.mouse); W = W(ia, :);
groups = {'Vehicle', 'DOI', 'Alprazolam', 'Tabernanthalog'};
short  = {'Veh', 'DOI', 'Alp', 'TAB'};
col = [0.35 0.35 0.38; 0.85 0.33 0.10; 0.00 0.45 0.74; 0.47 0.67 0.19];
gi = zeros(height(E), 1);
for g = 1:numel(groups), gi(E.treatment == groups{g}) = g; end
E = E(gi > 0, :); W = W(gi > 0, :); gi = gi(gi > 0);
n = arrayfun(@(g) sum(gi == g), 1:numel(groups));
d = W.pctOpen - E.pctOpen;

FH = 12.6;
f = figure('Units', 'centimeters', 'Position', [1 1 21 FH], 'Color', 'w', 'PaperPositionMode', 'auto');
AX = @(x, y, w, h) axes('Parent', f, 'Units', 'centimeters', 'Position', [x y w h], 'Box', 'off', ...
                        'TickDir', 'out', 'FontSize', 7, 'LineWidth', 0.6, 'Layer', 'top');
LB = @(x, y, s) annotation(f, 'textbox', [x/21 y/FH .04 .04], 'String', s, 'EdgeColor', 'none', ...
                        'FontWeight', 'bold', 'FontSize', 9, 'VerticalAlignment', 'middle');
R1 = 7.8; R2 = 2.3;

%% a. what exists
ax = AX(1.3, R1, 3.6, 3.3); hold(ax, 'on'); LB(0.35, R1 + 3.5, 'a');
have = n; miss = [0 6 18 0];                       % A9 DOI 6; A13 8 + S1 10 alprazolam
bar(ax, 1:4, have + miss, 0.64, 'FaceColor', [0.88 0.88 0.9], 'EdgeColor', 'none');
bar(ax, 1:4, have, 0.64, 'FaceColor', [0.3 0.3 0.34], 'EdgeColor', 'none');
for k = 1:4
    text(ax, k, have(k) + 1.4, sprintf('%d', have(k)), 'HorizontalAlignment', 'center', 'FontSize', 7);
    if miss(k), text(ax, k, have(k) + miss(k) + 1.4, sprintf('+%d', miss(k)), 'HorizontalAlignment', 'center', ...
                     'FontSize', 6.5, 'Color', [0.55 0.55 0.6]); end
end
set(ax, 'XTick', 1:4, 'XTickLabel', short, 'XLim', [0.4 4.6], 'YLim', [0 38]);
ylabel(ax, 'mice'); title(ax, {'behaviour available', 'grey = exists but untracked'}, 'FontSize', 7.5, 'FontWeight', 'normal');

%% b-e
dotP(AX(5.9, R1, 3.4, 3.3), W.pctOpen, gi, short, col, 'open arm, whole (%)', n, 1); LB(4.95, R1 + 3.5, 'b');
dotP(AX(10.4, R1, 3.4, 3.3), E.pctOpen, gi, short, col, 'open arm, first 5 min (%)', n, 1); LB(9.45, R1 + 3.5, 'c');
ax = dotP(AX(14.9, R1, 3.4, 3.3), d, gi, short, col, 'change in open arm (pp)', n, 1); LB(13.95, R1 + 3.5, 'd');
yline(ax, 0, ':', 'Color', [0.5 0.5 0.5]); title(ax, 'whole minus first 5 min', 'FontSize', 7.5, 'FontWeight', 'normal');

dotP(AX(1.3, R2, 3.6, 3.3), W.pctCenter, gi, short, col, 'centre, whole (%)', n, 1); LB(0.35, R2 + 3.5, 'e');
dotP(AX(5.9, R2, 3.4, 3.3), W.nHeadDipsUnprotected, gi, short, col, 'unprotected head dips', n, 1); LB(4.95, R2 + 3.5, 'f');
dotP(AX(10.4, R2, 3.4, 3.3), W.totalDistanceCm, gi, short, col, 'distance (cm)', n, 1); LB(9.45, R2 + 3.5, 'g');

%% h. alprazolam vs DOI head to head, each against its OWN batch vehicle
ax = AX(14.9, R2, 3.4, 3.3); hold(ax, 'on'); LB(13.95, R2 + 3.5, 'h');
meas = {'pctOpen', 'pctCenter', 'nHeadDipsUnprotected', 'nOpenEntries', 'totalDistanceCm'};
lbl  = {'open arm', 'centre', 'unprot. dips', 'open entries', 'distance'};
for mi = 1:numel(meas)
    for g = [2 3]
        bs = unique(W.batch(gi == g));
        v = double(W.(meas{mi})(gi == 1 & ismember(W.batch, bs)));
        y = double(W.(meas{mi})(gi == g));
        v = v(isfinite(v)); y = y(isfinite(y));
        if numel(v) < 3 || numel(y) < 3, continue; end
        eff = (median(y) - median(v)) / median(v) * 100;      % % change from own-batch vehicle
        p = ranksum(v, y);
        yy = mi + (g - 2.5)*0.3;
        plot(ax, eff, yy, 'o', 'MarkerSize', 5.5, 'MarkerFaceColor', col(g,:), 'MarkerEdgeColor', 'none');
        if p < 0.05, text(ax, eff, yy + 0.17, '*', 'HorizontalAlignment', 'center', 'FontSize', 10, 'Color', col(g,:)); end
    end
end
xline(ax, 0, '-', 'Color', [0.6 0.6 0.6]);
set(ax, 'YTick', 1:numel(meas), 'YTickLabel', lbl, 'YLim', [0.4 numel(meas) + 0.7], 'YDir', 'reverse');
xlabel(ax, '% change vs own-batch vehicle');
title(ax, 'DOI (orange) vs alprazolam (blue)', 'FontSize', 7.5, 'FontWeight', 'normal');

%% stats to the command window
fprintf('\n=== ALL mice with EPM behaviour, her pose pipeline ===\n');
fprintf('%-16s %4s %10s %10s %10s\n', 'treatment', 'n', 'open whole', 'open 5min', 'change');
for g = 1:numel(groups)
    q = gi == g;
    fprintf('%-16s %4d %10.2f %10.2f %+10.2f\n', groups{g}, sum(q), median(W.pctOpen(q)), median(E.pctOpen(q)), median(d(q)));
end
fprintf('\nvs OWN-BATCH vehicle:\n');
for g = 2:numel(groups)
    bs = unique(W.batch(gi == g)); vq = gi == 1 & ismember(W.batch, bs);
    if sum(vq) < 3, vq = gi == 1; end
    fprintf('  %-16s (vs %d veh from %s)  open whole P=%.4f | open 5min P=%.4f | change P=%.4f | centre P=%.4f\n', ...
        groups{g}, sum(vq), strjoin(bs', '+'), ranksum(W.pctOpen(vq), W.pctOpen(gi==g)), ...
        ranksum(E.pctOpen(vq), E.pctOpen(gi==g)), ranksum(d(vq), d(gi==g)), ...
        ranksum(W.pctCenter(vq), W.pctCenter(gi==g)));
end
fprintf('\nALPRAZOLAM vs DOI directly: open whole P=%.4f | change P=%.4f | centre P=%.4f\n', ...
    ranksum(W.pctOpen(gi==2), W.pctOpen(gi==3)), ranksum(d(gi==2), d(gi==3)), ...
    ranksum(W.pctCenter(gi==2), W.pctCenter(gi==3)));

annotation(f, 'textbox', [0.01 0.002 0.98 0.042], 'EdgeColor', 'none', 'FontSize', 6.4, 'Color', [0.3 0.3 0.3], ...
  'String', ['All mice with EPM tracking, no imaging filter, from Sophie''s pose pipeline (batches A11, S3 and A15). ' ...
  'Grey in a = drug mice that exist but have no tracking in either pipeline: A9 (6 DOI), A13 (8 alprazolam 0.25) ' ...
  'and S1 (10 alprazolam) have videos but no DLC. Panel h shows each drug against the vehicle arm of its OWN ' ...
  'batch, the only batch-safe comparison; * = P < 0.05, Mann-Whitney, no multiplicity correction.']);

if ~isfolder(cfg.figDir), mkdir(cfg.figDir); end
out = fullfile(cfg.figDir, 'sp_allMice_drugBehaviour.png');
print(f, out, '-dpng', '-r300'); close(f);
fprintf('\nwrote %s\n', out);
end

function ax = dotP(ax, y, gi, short, col, ylab, n, ~)
hold(ax, 'on'); y = double(y);
for g = 1:numel(short)
    q = gi == g; v = y(q); v = v(isfinite(v));
    if isempty(v), continue; end
    jx = g + (rand(numel(v), 1) - 0.5)*0.3;
    plot(ax, jx, v, 'o', 'MarkerSize', 3.1, 'MarkerFaceColor', col(g,:), 'MarkerEdgeColor', 'none');
    plot(ax, g + [-0.22 0.22], [median(v) median(v)], '-', 'Color', col(g,:), 'LineWidth', 1.8);
end
set(ax, 'XTick', 1:numel(short), 'XLim', [0.45 numel(short) + 0.55], 'XTickLabel', ...
    arrayfun(@(g) sprintf('%s\\newline%d', short{g}, n(g)), 1:numel(short), 'uni', 0));
ylabel(ax, ylab);
end
