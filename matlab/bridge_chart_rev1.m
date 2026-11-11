function fig = bridge_chart_rev1(br, title_str, opts)
%BRIDGE_CHART_REV1 Waterfall chart of the bridge from the boresight worst case to normal conditions.
%   fig = BRIDGE_CHART_REV1(br, title_str) plots the table from
%   BRIDGE_STEPS_REV1. The first bar (A) and the B bar are absolute; the
%   bars between are the change at each step; the decision bars are
%   changes from B, drawn in a separate color. The horizontal line at
%   0 dB is the allowance: above it, the criterion is exceeded.
%
%   Name-value options: floor_dB (default -60; values below it, including
%   zero exceedance, are drawn at the floor and labeled), file (PNG path;
%   default "" = do not save).
%
%   Built-ins considered: MATLAB has no waterfall bar chart (waterfall is a
%   3-D mesh plot), so the floating bars are drawn with patch.
arguments
    br table
    title_str (1,1) string = ""
    opts.floor_dB (1,1) double = -60
    opts.file (1,1) string = ""
end
v = max(br.ratio_dB, opts.floor_dB);
n = height(br);
fig = figure('Visible', 'off', 'Position', [100 100 1100 520]);
theme(fig, 'light');
ax = axes(fig); hold(ax, 'on'); grid(ax, 'on');
col.physics = [0.20 0.45 0.75]; col.result = [0.15 0.15 0.15]; col.decision = [0.85 0.45 0.10]; col.start = [0.70 0.10 0.10];
iB = find(br.kind == "result", 1);
for k = 1:n
    switch br.kind(k)
        case "result"
            y0 = opts.floor_dB; y1 = v(k); c = col.result;
        case "decision"
            y0 = v(iB); y1 = v(k); c = col.decision;
        otherwise
            if k == 1
                y0 = opts.floor_dB; y1 = v(k); c = col.start;
            else
                y0 = v(k - 1); y1 = v(k); c = col.physics;
            end
    end
    patch(ax, k + [-0.35 0.35 0.35 -0.35], [y0 y0 y1 y1], c, 'EdgeColor', 'none');
    lbl = sprintf('%+.0f dB', br.ratio_dB(k));
    if ~isfinite(br.ratio_dB(k)) || br.ratio_dB(k) < opts.floor_dB, lbl = sprintf('below %d dB', opts.floor_dB); end
    text(ax, k, max(y0, y1) + 2, lbl, 'HorizontalAlignment', 'center', 'FontSize', 9);
end
yline(ax, 0, 'k--', 'Allowance (0.005% of time)', 'LabelHorizontalAlignment', 'left', 'LineWidth', 1.2);
xticks(ax, 1:n);
xticklabels(ax, cellstr(br.step + ": " + extractAfter(br.label, ": ")));
xtickangle(ax, 25);
ylabel(ax, 'Time above short-term criterion vs allowance (dB)');
ylim(ax, [opts.floor_dB, max(v) + 8]);
xlim(ax, [0.4, n + 0.6]);
title(ax, {char(title_str), 'Red: worst case. Blue: one assumption changed at a time. Black: normal conditions. Orange: decisions, measured from B.'});
if strlength(opts.file) > 0
    exportgraphics(fig, opts.file, 'Resolution', 200);
end
end
