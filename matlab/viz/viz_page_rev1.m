function viz_page_rev1(fig, headline, subhead, source, alt, stem, out_dir)
%VIZ_PAGE_REV1 Add the headline, subhead, source line, and marking to a figure, then export it.
%   VIZ_PAGE_REV1(fig, headline, subhead, source, alt, stem, out_dir) writes
%   <stem>.png (300 dpi), <stem>.pdf (vector), and <stem>.alt.txt to out_dir.
%   The page follows the NTIA style used by the Python figures: dark blue
%   serif text, the DRAFT//PRE-DECISIONAL marking at the top left, and the
%   source line at the bottom. Leave the top 30% and bottom 8% of the
%   figure free for the text.
%
%   Built-ins used: annotation textboxes for page text (sgtitle can't hold
%   a marking, headline, and subhead at separate sizes), exportgraphics
%   for the files.
arguments
    fig (1,1) matlab.ui.Figure
    headline (1,1) string
    subhead (1,1) string
    source (1,1) string
    alt (1,1) string
    stem (1,1) string
    out_dir (1,1) string
end
c = viz_colors_rev1();
font = 'Times New Roman';
annotation(fig, 'textbox', [0.035 0.935 0.9 0.05], 'String', 'DRAFT//PRE-DECISIONAL', 'EdgeColor', 'none', ...
    'FontName', font, 'FontSize', 10, 'FontWeight', 'bold', 'Color', c.alert, 'VerticalAlignment', 'top');
annotation(fig, 'textbox', [0.035 0.80 0.93 0.13], 'String', headline, 'EdgeColor', 'none', 'FontName', font, ...
    'FontSize', 19, 'FontWeight', 'bold', 'Color', c.text, 'VerticalAlignment', 'top', 'FitBoxToText', 'off');
annotation(fig, 'textbox', [0.035 0.70 0.90 0.10], 'String', subhead, 'EdgeColor', 'none', 'FontName', font, ...
    'FontSize', 12, 'Color', c.text, 'VerticalAlignment', 'top');
annotation(fig, 'textbox', [0.035 0.005 0.93 0.06], 'String', source, 'EdgeColor', 'none', 'FontName', font, ...
    'FontSize', 9, 'Color', c.text, 'VerticalAlignment', 'bottom');
if ~isfolder(out_dir), mkdir(out_dir); end
base = fullfile(out_dir, stem);
exportgraphics(fig, base + ".png", 'Resolution', 300, 'BackgroundColor', 'white');
exportgraphics(fig, base + ".pdf", 'ContentType', 'vector', 'BackgroundColor', 'white');
writelines(alt, base + ".alt.txt");
fprintf('Saved %s.png/.pdf\n', base);
end
