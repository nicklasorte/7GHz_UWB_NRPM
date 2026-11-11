%VIZ05_BEAM_DWELL_REV1 Figure 5: how long the moving beam stays on a hovering drone at the Wallops NEN dish.
%   Left: one real pass, re-propagated at 1 s steps. A drone hovers at 400 ft
%   at the spot the dish points to at the moment of longest dwell; the line
%   is the angle between the dish boresight and the drone over time, and the
%   shaded window is when that angle is inside the exceedance cone.
%   Right: the longest dwell in each of the 556 passes in 30 days.
%
%   Output: ../../docs/figures/viz/viz05_beam_dwell.{png,pdf}.

here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..')); addpath(fullfile(here, '..', '..', '..', 'itu_p528', 'src'));
out_dir = string(fullfile(here, '..', '..', 'docs', 'figures', 'viz'));
res = fullfile(here, '..', '..', 'docs', 'bridge_results');
c = viz_colors_rev1();
f_mhz = 8160;
p = uwb_eess_params_rev1(); p.es.diam_m = 11.3; p.es.h_m = 10;
v = victim_systems_rev2(); k = contains(v.name, "WG1");
site = struct('name', "WG1 Wallops", 'lat_deg', v.lat_deg(k), 'lon_deg', v.lon_deg(k), 'alt_m', 10);
F = p528_loss_table_rev1(f_mhz, p.es.h_m);
T = readtable(fullfile(res, 'beam_dwell_passes_wallops.csv'));
med = median(T.max_dwell_s);

% A low pass whose longest dwell is closest to the median
low = find(T.el_at_max_dwell_deg < 15);
[~, j] = min(abs(T.max_dwell_s(low) - med));
j = low(j);
t0 = datetime(T.start(j), 'InputFormat', 'dd-MMM-yyyy HH:mm:ss', 'TimeZone', 'UTC');
ps = pass_statistics_rev1(site, 'tle_file', string(fullfile(here, '..', '..', 'data', 'tle_eess.txt')), ...
    'start_utc', t0 - minutes(1), 'duration_days', (T.duration_s(j) + 120) / 86400, 'sample_s', 1);
bd = beam_dwell_rev1(p, ps, F, f_mhz, 'eirp_offset_dB', 41.84 - 41.3);
[dmax, i0] = max(bd.dwell_s);
u = [cosd(ps.el_deg) .* sind(ps.az_deg), cosd(ps.el_deg) .* cosd(ps.az_deg), sind(ps.el_deg)];
phi = acosd(min(max(u * u(i0, :)', -1), 1));         % angle between boresight and the hovering drone
ts = seconds(ps.t - ps.t(i0));
in = phi <= bd.phi_x_deg(i0);
w = ts(in & abs(ts) < 120);
fprintf('Pass %d (%s): dwell %.1f s at %.1f deg elevation, cone half-angle %.3f deg, rate %.3f deg/s.\n', j, ...
    string(t0), dmax, bd.el_deg(i0), bd.phi_x_deg(i0), bd.omega_deg_s(i0));

fig = figure('Visible', 'off', 'Units', 'inches', 'Position', [0 0 11 7], 'Color', 'w');
ax = axes(fig, 'Position', [0.07 0.13 0.48 0.52]);
hold(ax, 'on');
fill(ax, [min(w) max(w) max(w) min(w)], [0 0 1.5 1.5], c.accent, 'FaceAlpha', 0.35, 'EdgeColor', 'none');
plot(ax, ts, phi, '-', 'Color', c.text, 'LineWidth', 2);
yline(ax, bd.phi_x_deg(i0), '--', 'Color', c.context, 'LineWidth', 1.2);
text(ax, -58, bd.phi_x_deg(i0) + 0.04, sprintf('Exceedance cone, %.2f° half-angle', bd.phi_x_deg(i0)), ...
    'FontName', c.font, 'FontSize', 10, 'Color', c.text, 'VerticalAlignment', 'bottom');
text(ax, max(w) + 2, 0.15, sprintf('Above the criterion\nfor %.0f s', max(w) - min(w) + 1), 'FontName', c.font, ...
    'FontSize', 11, 'FontWeight', 'bold', 'Color', c.text);
xlim(ax, [-60 60]); ylim(ax, [0 1.5]);
xlabel(ax, 'Time from the moment the beam points at the drone (s)');
ylabel(ax, 'Angle between boresight and the drone (deg)');
title(ax, sprintf('One pass, %s UTC, dish at %.0f° elevation', datestr(ps.t(i0), 'dd mmm HH:MM'), bd.el_deg(i0)), ...
    'FontWeight', 'normal', 'FontSize', 11); %#ok<DATST> short label
set(ax, 'FontName', c.font, 'FontSize', 10, 'XColor', c.text, 'YColor', c.text);

ax2 = axes(fig, 'Position', [0.64 0.13 0.32 0.52]);
hold(ax2, 'on');
histogram(ax2, T.max_dwell_s, 0:1:ceil(max(T.max_dwell_s)) + 1, 'FaceColor', c.context, 'EdgeColor', 'w');
xline(ax2, med, '-', 'Color', c.accent, 'LineWidth', 2.4);
text(ax2, med + 0.4, ax2.YLim(2) * 0.92, sprintf('Median %.1f s', med), 'FontName', c.font, 'FontSize', 11, ...
    'FontWeight', 'bold', 'Color', c.text);
xlabel(ax2, 'Longest dwell in the pass (s)'); ylabel(ax2, 'Passes');
title(ax2, sprintf('All %d passes in 30 days', height(T)), 'FontWeight', 'normal', 'FontSize', 11);
set(ax2, 'FontName', c.font, 'FontSize', 10, 'XColor', c.text, 'YColor', c.text);

viz_page_rev1(fig, ...
    sprintf("The tracking beam sweeps past a hovering drone: even at the best spot, the drone is above the criterion for about %.0f seconds per pass", med), ...
    "Wallops NEN WG1, 11.3 m, EESS 8160 MHz, Aqua, Terra, and Landsat 8 and 9 passes from November 1, 2026. One drone at 400 ft placed where the dish points at the moment of longest dwell; AirTag-measured EIRP for the left panel, the device at the limit for the pass table on the right.", ...
    "Source: nicklasorte/7GHz_UWB_NRPM, matlab/viz/viz05_beam_dwell_rev1.m (pass_statistics_rev1 at 1 s steps, beam_dwell_rev1); docs/bridge_results/beam_dwell_passes_wallops.csv.", ...
    sprintf("Two panels. Left: the angle between the Wallops dish boresight and a hovering drone over one pass, dipping inside the exceedance cone for about %.0f seconds. Right: histogram of the longest dwell in each of %d passes over 30 days, with a median of %.1f seconds.", ...
        max(w) - min(w) + 1, height(T), med), ...
    "viz05_beam_dwell", out_dir);
close(fig);
