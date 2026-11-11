function [fig, tbl] = tornado_chart_rev1(names, low, high, base, opts)
%TORNADO_CHART_REV1 Ranking chart: how far each input moves the result around a base case.
%   [fig, tbl] = TORNADO_CHART_REV1(names, low, high, base) draws one
%   horizontal bar per input, from the result with the input at its low
%   value to the result at its high value, sorted so the input with the
%   widest span is at the top. base is the result with every input at its
%   base value. tbl lists the inputs in ranked order with their spans.
%
%   Name-value options: xlabel_str, title_str, ref (vertical reference
%   line, default 0 = the allowance), low_labels and high_labels (strings
%   naming each end of each bar), file (PNG path; default "" = do not save).
%
%   Built-ins considered: barh with 'stacked' cannot float bars around an
%   arbitrary base, so each bar is a patch.
arguments
    names (:,1) string
    low (:,1) double
    high (:,1) double
    base (1,1) double
    opts.xlabel_str (1,1) string = "Time above short-term criterion vs allowance (dB)"
    opts.title_str (1,1) string = ""
    opts.ref (1,1) double = 0
    opts.low_labels (:,1) string = strings(0, 1)
    opts.high_labels (:,1) string = strings(0, 1)
    opts.file (1,1) string = ""
end
n = numel(names);
if numel(low) ~= n || numel(high) ~= n
    error('tornado_chart_rev1:size', 'names, low, and high must have the same length.');
end
lo_lbl = opts.low_labels; hi_lbl = opts.high_labels;
if isempty(lo_lbl), lo_lbl = repmat("", n, 1); end
if isempty(hi_lbl), hi_lbl = repmat("", n, 1); end
span = abs(high - low);
[~, ord] = sort(span, 'ascend');                     % widest at the top of the plot
tbl = table(names(flipud(ord)), low(flipud(ord)), high(flipud(ord)), span(flipud(ord)), ...
    'VariableNames', {'input', 'result_low', 'result_high', 'span'});
fig = figure('Visible', 'off', 'Position', [100 100 1000 80 + 55 * n]);
theme(fig, 'light');
ax = axes(fig); hold(ax, 'on'); grid(ax, 'on');
for j = 1:n
    k = ord(j);
    a = min(low(k), high(k)); b = max(low(k), high(k));
    patch(ax, [a b b a], j + [-0.3 -0.3 0.3 0.3], [0.20 0.45 0.75], 'EdgeColor', 'none');
    text(ax, low(k), j, " " + lo_lbl(k) + " ", 'HorizontalAlignment', ifelse(low(k) <= high(k)), 'FontSize', 8);
    text(ax, high(k), j, " " + hi_lbl(k) + " ", 'HorizontalAlignment', ifelse(high(k) < low(k)), 'FontSize', 8);
end
xline(ax, base, 'k-', 'Base case', 'LineWidth', 1.2, 'LabelVerticalAlignment', 'bottom', 'LabelOrientation', 'horizontal');
xline(ax, opts.ref, 'r--', 'Allowance', 'LineWidth', 1.2, 'LabelVerticalAlignment', 'bottom', 'LabelOrientation', 'horizontal', ...
    'LabelHorizontalAlignment', 'left');
ylim(ax, [0 n + 0.6]);                                % room under the bars for the line labels
yticks(ax, 1:n); yticklabels(ax, cellstr(names(ord)));
xlabel(ax, opts.xlabel_str);
title(ax, opts.title_str);
if strlength(opts.file) > 0
    exportgraphics(fig, opts.file, 'Resolution', 200);
end
end

function h = ifelse(left_side)
if left_side, h = 'right'; else, h = 'left'; end
end
