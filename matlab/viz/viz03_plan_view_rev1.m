%VIZ03_PLAN_VIEW_REV1 Figure 3: where on the ground one drone can exceed the criterion at the Wallops NEN dish.
%   Plan view around the WG1 11.3 m dish pointed north at 5 deg elevation.
%   One drone at 400 ft, AirTag-measured EIRP, 3 dB polarization loss,
%   P.528 median loss, ITU-R SA.509-3 envelope pattern. Left: a 4 km map
%   with the dish, the pointing azimuth, and the exceedance regions. Right:
%   a zoom on the short-term region with its dimensions.
%
%   Uses the analysis functions directly (device_interference_rev1,
%   eess_criteria_rev1, region_chord_rev1), so the figure can't drift from
%   the model. Output: ../../docs/figures/viz/viz03_plan_view.{png,pdf}.

here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..')); addpath(fullfile(here, '..', '..', '..', 'itu_p528', 'src'));
out_dir = string(fullfile(here, '..', '..', 'docs', 'figures', 'viz'));
c = viz_colors_rev1();
f_mhz = 8160; el_pt = 5; eirp_meas_dB = 41.84 - 41.3;
p = uwb_eess_params_rev1(); p.es.diam_m = 11.3; p.es.h_m = 10;
v = victim_systems_rev2(); k = contains(v.name, "WG1");
lat0 = v.lat_deg(k); lon0 = v.lon_deg(k);
crit = eess_criteria_rev1(f_mhz, p);
F = p528_loss_table_rev1(f_mhz, p.es.h_m);
e10 = uwb_power_in_band_rev1(f_mhz, p.crit.ref_bw_MHz, p.uwb);
geo = struct('ae_km', p.prop.k_factor * p.prop.re_km, 'r1_km', p.prop.k_factor * p.prop.re_km + p.es.h_m / 1000);
ant = struct('diam_m', p.es.diam_m, 'f_mhz', f_mhz, 'eff', p.es.eff, 'pattern', "single");
field_dBm = @(X, Y) reshape(10 * log10(device_interference_rev1( ...
    struct('r_km', hypot(X(:), Y(:)), 'az_rad', atan2(X(:), Y(:)), 'h_m', repmat(p.drone.h_max_m, numel(X), 1), ...
           'p_time', repmat(50, numel(X), 1), 'p_loc', []), ...
    struct('el_rad', repmat(deg2rad(el_pt), numel(X), 1), 'az_rad', zeros(numel(X), 1)), ...
    geo, F, ant, e10 - eirp_meas_dB - p.uwb.pol_loss_dB)), size(X));

% Overview grid (5 m) and zoom grid (0.5 m by 1 m)
xo = -0.6:0.005:0.6; yo = 0:0.005:2.2; [Xo, Yo] = meshgrid(xo, yo); Io = field_dBm(Xo, Yo);
xz = -0.04:0.0005:0.04; yz = 1.0:0.001:1.4; [Xz, Yz] = meshgrid(xz, yz); Iz = field_dBm(Xz, Yz);
rg = region_chord_rev1(xz, yz, Iz, crit.short_dBm);
rgA = region_chord_rev1(xo, yo, Io, crit.short_dBm - 20);
[ri, ci] = find(Iz > crit.short_dBm);
y_near = 1000 * yz(min(ri)); y_far = 1000 * yz(max(ri));
fprintf('Short-term region: %.0f m long, %.0f m wide, %.4f km^2, from %.0f m to %.0f m out.\n', ...
    1000 * rg.length_km, 1000 * rg.width_km, rg.area_km2, y_near, y_far);

fig = figure('Visible', 'off', 'Units', 'inches', 'Position', [0 0 11 7], 'Color', 'w');
% Left: overview map in latitude and longitude
km2lat = 1 / 111.32; km2lon = 1 / (111.32 * cosd(lat0));
gx = geoaxes(fig, 'Position', [0.06 0.10 0.40 0.56]);
try
    geobasemap(gx, 'streets-light');
catch
    geobasemap(gx, 'grayland');                       % offline fallback
end
hold(gx, 'on');
CA = contourc(xo, yo, double(Io > crit.short_dBm - 20), [0.5 0.5]);
plot_contour_geo(gx, CA, lat0, lon0, km2lat, km2lon, c.context, '--', 1.4);
CS = contourc(xz, yz, double(Iz > crit.short_dBm), [0.5 0.5]);
plot_contour_geo(gx, CS, lat0, lon0, km2lat, km2lon, c.accent, '-', 2.5);
geoplot(gx, lat0 + [0 2.0] * km2lat, lon0 + [0 0], ':', 'Color', c.text, 'LineWidth', 1.2);
geoscatter(gx, lat0, lon0, 60, c.alert, 'filled');
text(gx, lat0 - 0.08 * km2lat, lon0 + 0.05 * km2lon, 'WG1 dish (11.3 m)', 'FontName', c.font, 'FontSize', 10, ...
    'Color', c.text, 'FontWeight', 'bold');
text(gx, lat0 + 2.02 * km2lat, lon0 + 0.02 * km2lon, 'Pointing azimuth (north), 5° elevation', 'FontName', c.font, ...
    'FontSize', 9.5, 'Color', c.text);
text(gx, lat0 + (y_near / 1000) * km2lat, lon0 + 0.06 * km2lon, sprintf('Short-term region\n%.0f m x %.0f m', ...
    1000 * rg.length_km, 1000 * rg.width_km), 'FontName', c.font, 'FontSize', 10, 'FontWeight', 'bold', 'Color', c.text);
geolimits(gx, lat0 + [-0.3 2.3] * km2lat, lon0 + [-1.3 1.3] * km2lon);
gx.FontName = c.font; gx.FontSize = 9;

% Right: zoom on the short-term region, local meters
ax = axes(fig, 'Position', [0.58 0.12 0.38 0.52]);
hold(ax, 'on'); box(ax, 'off');
contourf(ax, 1000 * xz, 1000 * yz, double(Iz > crit.short_dBm), [0.5 0.5], 'FaceColor', c.accent, 'LineColor', c.text);
xline(ax, 0, ':', 'Color', c.text);
text(ax, 2, y_far + 8, sprintf('%.0f m from the dish', y_far), 'FontName', c.font, 'FontSize', 10, 'Color', c.text);
text(ax, 2, y_near - 8, sprintf('%.0f m', y_near), 'FontName', c.font, 'FontSize', 10, 'Color', c.text, ...
    'VerticalAlignment', 'top');
text(ax, 1000 * rg.width_km / 2 + 4, (y_near + y_far) / 2, sprintf('%.0f m wide\n%.0f m long\nmean chord %.0f m', ...
    1000 * rg.width_km, 1000 * rg.length_km, 1000 * rg.mean_chord_km), 'FontName', c.font, 'FontSize', 10.5, ...
    'FontWeight', 'bold', 'Color', c.text);
xlim(ax, [-40 40]); ylim(ax, [1000 1400]);
xlabel(ax, 'East-west offset from the pointing azimuth (m)'); ylabel(ax, 'Distance north of the dish (m)');
title(ax, 'Zoom: one drone at 400 ft exceeds the short-term criterion only here', 'FontWeight', 'normal', 'FontSize', 11);
set(ax, 'FontName', c.font, 'FontSize', 10, 'XColor', c.text, 'YColor', c.text);

viz_page_rev1(fig, ...
    sprintf("At the NASA station, one drone exceeds the short-term criterion only inside a sliver %.0f m long and %.0f m wide, %.1f km out along the dish's pointing direction", ...
        1000 * rg.length_km, 1000 * rg.width_km, y_near / 1000), ...
    sprintf("Wallops NEN WG1, 11.3 m dish pointed north at 5° (a low pass). One drone at 400 ft, AirTag-measured EIRP, 3 dB polarization loss, P.528 median loss, ITU-R SA.509-3 envelope. Dashed: the region if a 20 dB apportionment applied (%.2f km^2).", rgA.area_km2), ...
    "Source: nicklasorte/7GHz_UWB_NRPM, matlab/viz/viz03_plan_view_rev1.m (device_interference_rev1, region_chord_rev1). Basemap: MATLAB geobasemap. Site location: victim_systems_rev2.", ...
    sprintf("Map around the Wallops NEN WG1 dish with its pointing azimuth to the north and a zoom panel. One drone at 400 feet exceeds the short-term criterion only inside a region %.0f m long and %.0f m wide, from %.0f m to %.0f m north of the dish. A dashed outline shows the larger region under a 20 dB apportionment.", ...
        1000 * rg.length_km, 1000 * rg.width_km, y_near, y_far), ...
    "viz03_plan_view", out_dir);
close(fig);

function plot_contour_geo(gx, C, lat0, lon0, km2lat, km2lon, col, ls, lw)
%PLOT_CONTOUR_GEO Draw each loop of a contour matrix in latitude and longitude.
k = 1;
while k < size(C, 2)
    n = C(2, k);
    xy = C(:, k+1:k+n);
    geoplot(gx, lat0 + xy(2, :) * km2lat, lon0 + xy(1, :) * km2lon, ls, 'Color', col, 'LineWidth', lw);
    k = k + n + 1;
end
end
