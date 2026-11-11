%VIZ04_SIDE_VIEW_REV1 Figure 4: why the main beam is out of reach for a legal drone beyond about 1.2 km.
%   Vertical cross-section along the pointing azimuth of the Wallops NEN
%   WG1 dish (11.3 m, 10 m high). Filled: where one drone, at that distance
%   and height, exceeds the short-term criterion when the dish points at
%   5 deg (accent) or 10 deg (gray). The band is the 14 CFR 107.51 ceiling
%   of 400 ft (121.92 m). The vertical scale is exaggerated.
%
%   Output: ../../docs/figures/viz/viz04_side_view.{png,pdf}.

here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..')); addpath(fullfile(here, '..', '..', '..', 'itu_p528', 'src'));
out_dir = string(fullfile(here, '..', '..', 'docs', 'figures', 'viz'));
c = viz_colors_rev1();
f_mhz = 8160; eirp_meas_dB = 41.84 - 41.3;
p = uwb_eess_params_rev1(); p.es.diam_m = 11.3; p.es.h_m = 10;
crit = eess_criteria_rev1(f_mhz, p);
F = p528_loss_table_rev1(f_mhz, p.es.h_m);
e10 = uwb_power_in_band_rev1(f_mhz, p.crit.ref_bw_MHz, p.uwb);
geo = struct('ae_km', p.prop.k_factor * p.prop.re_km, 'r1_km', p.prop.k_factor * p.prop.re_km + p.es.h_m / 1000);
ant = struct('diam_m', p.es.diam_m, 'f_mhz', f_mhz, 'eff', p.es.eff, 'pattern', "single");
ceil_m = p.drone.h_max_m;

d = 0.02:0.002:3.5; h = 1:1:450;                      % km along the azimuth, m above ground
[D, H] = meshgrid(d, h);
field = @(el) reshape(10 * log10(device_interference_rev1( ...
    struct('r_km', D(:), 'az_rad', zeros(numel(D), 1), 'h_m', H(:), 'p_time', repmat(50, numel(D), 1), 'p_loc', []), ...
    struct('el_rad', repmat(deg2rad(el), numel(D), 1), 'az_rad', zeros(numel(D), 1)), ...
    geo, F, ant, e10 - eirp_meas_dB - p.uwb.pol_loss_dB)), size(D));
I5 = field(5); I10 = field(10);
% Farthest point at or below the ceiling where the 5 deg region exists
ok5 = I5 > crit.short_dBm & H <= ceil_m;
d_reach5 = max(D(ok5));
ok10 = I10 > crit.short_dBm & H <= ceil_m;
d_reach10 = max(D(ok10));
% Beam centerlines on a 4/3 Earth
ae_m = 1000 * geo.ae_km;
cl = @(el) p.es.h_m + 1000 * d * tand(el) + (1000 * d).^2 / (2 * ae_m);
d_cross5 = interp1(cl(5), d, ceil_m);
fprintf('5 deg: centerline crosses 400 ft at %.2f km; exceedance at or below 400 ft out to %.2f km. 10 deg: %.2f km.\n', ...
    d_cross5, d_reach5, d_reach10);

fig = figure('Visible', 'off', 'Units', 'inches', 'Position', [0 0 11 7], 'Color', 'w');
ax = axes(fig, 'Position', [0.08 0.13 0.88 0.52]);
hold(ax, 'on');
fill(ax, [0 3.5 3.5 0], [0 0 ceil_m ceil_m], c.panel, 'EdgeColor', 'none');
contourf(ax, D, H, double(I10 > crit.short_dBm), [0.5 0.5], 'FaceColor', c.light, 'LineColor', c.context);
contourf(ax, D, H, double(I5 > crit.short_dBm), [0.5 0.5], 'FaceColor', c.accent, 'LineColor', c.text);
plot(ax, d, cl(5), '-', 'Color', c.text, 'LineWidth', 0.8);
plot(ax, d, cl(10), '-', 'Color', c.context, 'LineWidth', 0.8);
yline(ax, ceil_m, '-', 'Color', c.text, 'LineWidth', 1.4);
text(ax, 3.45, ceil_m - 6, 'Part 107 ceiling, 400 ft (121.92 m): drones fly below this line', 'FontName', c.font, ...
    'FontSize', 10, 'Color', c.text, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top');
plot(ax, 0, p.es.h_m, '^', 'MarkerSize', 10, 'MarkerFaceColor', c.alert, 'MarkerEdgeColor', c.alert);
text(ax, 0.15, 3, 'Dish, 10 m', 'VerticalAlignment', 'bottom', 'FontName', c.font, 'FontSize', 10, 'Color', c.text);
plot(ax, d_reach5, ceil_m, 'o', 'MarkerSize', 8, 'MarkerFaceColor', 'w', 'MarkerEdgeColor', c.text, 'LineWidth', 1.4);
text(ax, d_reach5 + 0.06, ceil_m - 45, sprintf('5° pass: the region leaves the drone band at %.2f km', d_reach5), ...
    'FontName', c.font, 'FontSize', 10.5, 'FontWeight', 'bold', 'Color', c.text);
text(ax, 2.6, interp1(d, cl(5), 2.6) - 28, 'Beam centerline, 5° pass', 'FontName', c.font, 'FontSize', 10, 'Color', c.text);
text(ax, 1.9, interp1(d, cl(10), 1.9) - 28, 'Beam centerline, 10° pass', 'FontName', c.font, 'FontSize', 10, ...
    'Color', c.context);
xlim(ax, [0 3.5]); ylim(ax, [0 450]);
xlabel(ax, 'Distance from the dish along its pointing azimuth (km)');
ylabel(ax, 'Height above ground (m)');
set(ax, 'FontName', c.font, 'FontSize', 10, 'XColor', c.text, 'YColor', c.text, 'Layer', 'top');
box(ax, 'off');

viz_page_rev1(fig, ...
    sprintf("Past %.2f km, the beam of a 5° pass is above the 400 ft ceiling, so no drone flying under Part 107 can reach the main beam there", d_reach5), ...
    sprintf("Wallops NEN WG1, 11.3 m, 10 m high. Filled: where one drone exceeds the short-term criterion when the dish points at 5° (blue) or 10° (gray), AirTag-measured EIRP, P.528 median loss. The short-term distance on boresight is 5.6 km, but only above the ceiling. Vertical scale exaggerated about %.0f times.", ...
        (3.5 * 1000 / 450) * (0.52 * 7) / (0.88 * 11)), ...
    "Source: nicklasorte/7GHz_UWB_NRPM, matlab/viz/viz04_side_view_rev1.m (device_interference_rev1, 4/3-Earth geometry); 14 CFR 107.51.", ...
    sprintf("Side-view cross-section along the pointing azimuth of the Wallops NEN dish. The region where one drone exceeds the short-term criterion follows the beam upward. For a 5 degree pass it leaves the band below the 400 ft drone ceiling at %.2f km; for a 10 degree pass, at %.2f km.", d_reach5, d_reach10), ...
    "viz04_side_view", out_dir);
close(fig);
