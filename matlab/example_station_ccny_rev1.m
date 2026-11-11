%EXAMPLE_STATION_CCNY_REV1 Site-specific example: UWB drones near an X-band receive station in New York City.
%   The station is the NOAA-CREST Satellite Receiving Station at The City
%   College of New York (CCNY), Manhattan. It is a public, non-NASA
%   direct-readout site, chosen because it is the X-band receiver in the
%   largest U.S. city in NASA's own direct-readout station list. It is an
%   example of a class of receiver, not a NASA protection request.
%     Location 40.820 N, 73.950 W: NASA GSFC Direct Readout Laboratory,
%       X-band station list, entry 154 (directreadout.sci.gsfc.nasa.gov/x-band.html)
%     Antenna: 2.4 m X-band, robot-controlled, in a radome; receives Terra
%       and Aqua (MODIS) and Suomi NPP (VIIRS): CUNY CREST, "Satellite
%       Receiving Station" (crest.cuny.edu/hires/research/facilities/satellite-receiving-station)
%   The script runs two victim links: EESS at 8160 MHz (Aqua, Terra;
%   ITU-R SA.1027-6 criteria) and MetSat at 7812 MHz (Suomi NPP HRD;
%   ITU-R SA.1026-5 criteria). Both are inside UWB channel 9.
%
%   Steps (each writes a table or figure to ../output/ccny):
%     1. Station inputs and pass statistics (SGP4)
%     2. Main-beam geometry: where a drone can be in the beam
%     3. Single-drone link budget, step by step
%     4. Single-drone interference map around the station
%     5. Drone density from FAA flight hours and Census population
%     6. Aggregate Monte Carlo at those densities, with 95% intervals
%     7. Poisson footprint cross-check of the short-term result
%     8. Time basis: exceedance on tracking time and on all time
%     9. Ground UWB baseline (phones, tags) with the validated P.2108 port
%    10. Clutter-model swap at NEN WG1 (rev1 formula vs validated port)
%    11. Consistency with ECC Report 327 and measured AirTag emissions
%
%   Requires github.com/nicklasorte/itu_p528 and itu_p2108 cloned next to
%   this repo, and network access to CelesTrak the first time.

close all;
here = fileparts(mfilename('fullpath'));
addpath(here);
addpath(fullfile(here, '..', '..', 'itu_p528', 'src'));
addpath(fullfile(here, '..', '..', 'itu_p2108', 'src'));
out_dir = fullfile(here, '..', 'output', 'ccny');
if ~isfolder(out_dir), mkdir(out_dir); end
diary(fullfile(out_dir, 'run_log_ccny_rev1.txt')); diary on;
t_start = tic;
min_per_year = 365.25 * 24 * 60;
fprintf('Run started %s\n', string(datetime('now')));

%% 1. Station inputs
p = uwb_eess_params_rev1();
p.es.diam_m = 2.4;                 % CUNY CREST SRS page
p.es.eff = 0.6;                    % TODO aperture efficiency (not published)
p.es.h_m = 20;                     % TODO antenna height above ground (radome, likely rooftop; not published)
site = struct('name', "CCNY NOAA-CREST SRS", 'lat_deg', 40.820, 'lon_deg', -73.950, 'alt_m', 50);   % alt_m TODO; affects pass geometry negligibly
links = struct( ...
    'name', {"EESS 8160 MHz (Aqua, Terra)", "MetSat 7812 MHz (Suomi NPP)"}, ...
    'f_mhz', {8160, 7812}, ...
    'norad', {[27424 25994], 37849}, ...
    'tle', {string(fullfile(here, '..', 'data', 'tle_ccny_eess.txt')), string(fullfile(here, '..', 'data', 'tle_ccny_metsat.txt'))});
station_tbl = table( ...
    ["Location"; "Antenna diameter"; "Aperture efficiency"; "Antenna height AGL"; "Minimum elevation"; ...
     "Victim links"; "Antenna pattern"; "UWB polarization loss"; "Site shielding"], ...
    ["40.820 N, 73.950 W"; "2.4 m"; "0.6"; "20 m"; "5 deg"; "8160 MHz EESS; 7812 MHz MetSat"; ...
     "ITU-R F.699-5 (D/lambda about 63-65 < 100)"; "3 dB"; "0 dB (radome and buildings ignored)"], ...
    ["NASA DRL X-band list, entry 154"; "CUNY CREST SRS page"; "TODO assumption"; "TODO assumption"; ...
     "ITU-R SA.1026-5"; "CUNY CREST SRS page (satellites)"; "Assumption, peak envelope (conservative)"; ...
     "Linear UWB into circular feed"; "Assumption (conservative)"], ...
    'VariableNames', {'item', 'value', 'source'});
disp('Station inputs:'); disp(station_tbl);
writetable(station_tbl, fullfile(out_dir, 'station_inputs.csv'));

ps = cell(1, 2); F = cell(1, 2); pass_rows = {};
for k = 1:2
    ps{k} = pass_statistics_rev1(site, 'norad_ids', links(k).norad, 'tle_file', links(k).tle);
    [F{k}, ~] = p528_loss_table_rev1(links(k).f_mhz, p.es.h_m);
    pass_rows(end+1, :) = {links(k).name, strjoin(ps{k}.sat_names, ", "), 100 * ps{k}.frac_tracking, ...
        ps{k}.frac_tracking * 24 * 60, 100 * ps{k}.frac_tracking_below_6deg, median(ps{k}.el_deg(ps{k}.tracking))}; %#ok<SAGROW> two links
end
pass_tbl = cell2table(pass_rows, 'VariableNames', {'link', 'satellites', 'pct_time_tracking', ...
    'tracking_min_per_day', 'pct_tracking_below_6deg', 'median_el_deg'});
disp('Pass statistics (30 days from 2026-11-01, el >= 5 deg):'); disp(pass_tbl);
writetable(pass_tbl, fullfile(out_dir, 'pass_statistics.csv'));
fprintf('Step 1 done (%.0f s)\n', toc(t_start));

%% 2. Main-beam geometry
lambda8 = physconst('LightSpeed') / 8160e6;
bw3 = 70 * lambda8 / p.es.diam_m;                    % approximate 3 dB beamwidth, deg (70 lambda/D rule)
el_set = [5 10 20 30 45];
h_set = [10 60 121.92];
[E, H] = ndgrid(el_set, h_set);
D = (H - p.es.h_m) ./ tand(E) / 1000;                % flat-Earth distance at which the drone sits on boresight
beam_tbl = array2table([el_set' D], 'VariableNames', ["dish_el_deg", "d_km_h10m", "d_km_h60m", "d_km_h122m"]);
fprintf('Approximate 3 dB beamwidth at 8160 MHz: %.2f deg (main beam spans +/- %.2f deg).\n', bw3, bw3 / 2);
disp('Ground distance at which a drone is on the dish boresight (km):'); disp(beam_tbl);
writetable(beam_tbl, fullfile(out_dir, 'main_beam_geometry.csv'));

%% 3. Single-drone link budget, step by step
d_bore = (121.92 - p.es.h_m) / tand(5) / 1000;
lb_beam = link_budget_walkthrough_rev1(p, F{1}, 8160, 121.92, d_bore, 5, 0, 50);
lb_side = link_budget_walkthrough_rev1(p, F{1}, 8160, 121.92, 5, 20, 30, 50);
disp('Link budget A: drone at 400 ft on boresight of a 5 deg pass (EESS 8160 MHz, P.528 median):'); disp(lb_beam);
disp('Link budget B: drone at 400 ft, 5 km away, 30 deg off the dish azimuth, dish at 20 deg:'); disp(lb_side);
writetable(lb_beam, fullfile(out_dir, 'link_budget_boresight.csv'));
writetable(lb_side, fullfile(out_dir, 'link_budget_sidelobe.csv'));

%% 4. Single-drone interference map (dish at 5 deg elevation, azimuth north)
[X, Y] = meshgrid(-6:0.01:6, -6:0.01:6);
R = hypot(X, Y); AZ = atan2(X, Y);
dev = struct('r_km', R(:), 'az_rad', AZ(:), 'h_m', repmat(121.92, numel(R), 1), 'p_time', repmat(50, numel(R), 1), 'p_loc', []);
pt = struct('el_rad', repmat(deg2rad(5), numel(R), 1), 'az_rad', zeros(numel(R), 1));
geo = struct('ae_km', p.prop.k_factor * p.prop.re_km, 'r1_km', p.prop.k_factor * p.prop.re_km + p.es.h_m / 1000);
ant = struct('diam_m', p.es.diam_m, 'f_mhz', 8160, 'eff', p.es.eff, 'pattern', "single");
e10 = uwb_power_in_band_rev1(8160, p.crit.ref_bw_MHz, p.uwb);
I_map = reshape(10 * log10(device_interference_rev1(dev, pt, geo, F{1}, ant, e10 - p.uwb.pol_loss_dB)), size(R));
crit8 = eess_criteria_rev1(8160, p);
area_short = nnz(I_map > crit8.short_dBm) * 0.01^2;
area_long = nnz(I_map > crit8.long_dBm) * 0.01^2;
fprintf('Single drone at 400 ft, dish at 5 deg: area above short-term criterion %.3f km^2, above long-term %.2f km^2.\n', area_short, area_long);
fig1 = figure('Visible', 'off'); theme(fig1, 'light');
imagesc(-6:0.01:6, -6:0.01:6, I_map - crit8.long_dBm); axis xy equal tight;
clim([-40 40]); cb = colorbar; cb.Label.String = 'Interference minus long-term criterion (dB)';
hold on; contour(X, Y, I_map, [crit8.long_dBm crit8.long_dBm], 'k-', 'LineWidth', 1);
contour(X, Y, I_map, [crit8.short_dBm crit8.short_dBm], 'r-', 'LineWidth', 1.5);
plot(0, 0, 'k^', 'MarkerFaceColor', 'w');
xlabel('East (km)'); ylabel('North (km)');
title({'One drone at 400 ft, CCNY 2.4 m dish at 5 deg elevation toward north', ...
    'Black: long-term criterion; red: short-term criterion (P.528 median loss)'});
exportgraphics(fig1, fullfile(out_dir, 'fig_ccny1_single_drone_map.png'), 'Resolution', 200);

%% 5. Drone density from FAA and Census data
nyc_pop_2025 = 8584629;                % Census V2025 via NYC DCP, March 2026, App. A
nyc_land_km2 = 300.45 * 2.589988;      % 2020 land area, NYS DOH Vital Statistics Table 2
man_pop_2025 = 1664862;
man_land_km2 = 22.66 * 2.589988;
dens_nyc = drone_density_faa_rev1(nyc_pop_2025 / nyc_land_km2);
dens_man = drone_density_faa_rev1(man_pop_2025 / man_land_km2);
u = dens_nyc.Properties.UserData;
fprintf(['Density chain (New York City): %.0f drones airborne in the U.S. on average; %.3g per resident; ' ...
    'New York state flies %.2f times the national rate per resident; %.0f residents/km^2 -> %.4f airborne drones/km^2 on average.\n'], ...
    u.airborne_us_avg, u.airborne_per_person, u.state_ratio, u.pop_density_per_km2, u.airborne_avg_per_km2);
fprintf('Manhattan only: %.0f residents/km^2 -> %.4f airborne drones/km^2 on average.\n', ...
    dens_man.Properties.UserData.pop_density_per_km2, dens_man.Properties.UserData.airborne_avg_per_km2);
disp('Active UWB drone density, New York City (per km^2):'); disp(dens_nyc);
writetable(dens_nyc, fullfile(out_dir, 'density_nyc.csv'));
writetable(dens_man, fullfile(out_dir, 'density_manhattan.csv'));
pick_case = @(t, pk, eq, ac) t.active_uwb_per_km2(t.peak_factor == pk & t.equipped_frac == eq & t.activity == ac);
cases = struct( ...
    'label', {"Low: average hour, 10% equipped, 5% activity", "Mid: peak x3, all equipped, 5% activity", ...
              "High: peak x3, all equipped, continuous", "Bound: Manhattan peak x6, all, continuous"}, ...
    'density', {pick_case(dens_nyc, 1, 0.1, 0.05), pick_case(dens_nyc, 3, 1, 0.05), ...
                pick_case(dens_nyc, 3, 1, 1), pick_case(dens_man, 6, 1, 1)}, ...
    'n_iter', {4e6, 4e6, 1e6, 6e5});
fprintf('Step 5 done (%.0f s)\n', toc(t_start));

%% 6-8. Aggregate Monte Carlo, footprint check, time basis
drone = struct('name', "drones", 'density_per_km2', NaN, 'h_min_m', p.drone.h_min_m, 'h_max_m', p.drone.h_max_m, ...
    'r_max_km', 60, 'eirp_offset_dB', 0, 'extra_loss_db', 0, 'clutter', false);
edges = [0 0.25 0.5 1 1.5 2 3 5 10 20 40];
agg_rows = {}; mc = cell(2, numel(cases)); fp = cell(1, 2);
fig2 = figure('Visible', 'off', 'Position', [100 100 1200 500]); theme(fig2, 'light');
tl = tiledlayout(fig2, 1, 2, 'TileSpacing', 'compact');
for k = 1:2
    crit = eess_criteria_rev1(links(k).f_mhz, p);
    pct = [crit.long_pct crit.short_pct];
    fp{k} = exceedance_footprint_rev1(p, setfield(drone, 'density_per_km2', 1), ps{k}, F{k}, links(k).f_mhz, 'n', 4e6, 'r_sample_km', 3); %#ok<SFLD> exceedances need L - G < 69 dB: within about 1.3 km
    ax = nexttile(tl); hold(ax, 'on'); set(ax, 'YScale', 'log'); grid(ax, 'on');
    for c = 1:numel(cases)
        pop = drone; pop.density_per_km2 = cases(c).density;
        chunk = max(500, min(2e5, round(2e6 / max(pop.density_per_km2 * pi * drone.r_max_km^2, 1))));   % about 2e6 devices per chunk keeps memory near 1 GB
        o = aggregate_drone_mc_rev4(p, pop, ps{k}, F{k}, links(k).f_mhz, 'n_iter', cases(c).n_iter, ...
            'chunk', chunk, 'pct_exceed', pct, 'r_edges_km', edges, 'seed', p.mc.seed + 10 * k + c);
        r_s = required_exclusion_radius_rev1(o.r_ex_km, o.pct_dBm(2, :), crit.short_dBm);
        r_l = required_exclusion_radius_rev1(o.r_ex_km, o.pct_dBm(1, :), crit.long_dBm);
        pred = 1 - exp(-pop.density_per_km2 * fp{k}.area_short_km2);
        app_dB = 20;                                     % ECC Report 327 sec. 5.5 apportionment for UWB (sensitivity)
        r_s_app = required_exclusion_radius_rev1(o.r_ex_km, o.pct_dBm(2, :), crit.short_dBm - app_dB);
        frac_app = mean(o.agg_r0_mW > 10^((crit.short_dBm - app_dB) / 10));
        trk = ps{k}.frac_tracking;
        agg_rows(end+1, :) = {links(k).name, cases(c).label, pop.density_per_km2, o.n_iter, o.ci.n_tail(2), ...
            o.ci.level_db(1) - crit.long_dBm, o.ci.level_db(2) - crit.short_dBm, ...
            o.ci.level_db_lo(2) - crit.short_dBm, o.ci.level_db_hi(2) - crit.short_dBm, ...
            100 * o.ci.frac(2), 100 * o.ci.frac_lo(2), 100 * o.ci.frac_hi(2), 100 * pred, ...
            100 * o.ci.frac(2) * trk, o.ci.frac(2) * trk * min_per_year, crit.short_pct / 100 * min_per_year, r_l, r_s, ...
            o.ci.level_db(2) - (crit.short_dBm - app_dB), 100 * frac_app, r_s_app}; %#ok<SAGROW> eight rows
        mc{k, c} = rmfield(o, 'agg_r0_mW');
        % time-basis CCDF (step 8)
        v = sort(o.agg_r0_mW(o.agg_r0_mW > 0), 'descend');
        if isempty(v), continue, end
        y = (1:numel(v))' / o.n_iter;
        idx = unique(round(logspace(0, log10(numel(v)), 400)));
        plot(ax, 10 * log10(v(idx)), 100 * y(idx) * trk, '-', 'LineWidth', 1.6, 'DisplayName', sprintf('%.2g/km^2, all time', pop.density_per_km2));
        plot(ax, 10 * log10(v(idx)), 100 * y(idx), ':', 'LineWidth', 1.0, 'DisplayName', sprintf('%.2g/km^2, tracking time only', pop.density_per_km2), ...
            'Color', ax.Children(1).Color);
        fprintf('%s, %s done (%.0f s)\n', links(k).name, cases(c).label, toc(t_start));
    end
    plot(ax, crit.long_dBm, crit.long_pct, 'kp', 'MarkerSize', 12, 'MarkerFaceColor', 'k', 'DisplayName', 'Long-term criterion');
    plot(ax, crit.short_dBm, crit.short_pct, 'rp', 'MarkerSize', 12, 'MarkerFaceColor', 'r', 'DisplayName', 'Short-term criterion');
    xlabel(ax, 'Aggregate interference (dBm per 10 MHz)'); ylabel(ax, 'Percent of time exceeded');
    title(ax, links(k).name); ylim(ax, [1e-6 100]); xlim(ax, [-200 -60]);
    if k == 2, legend(ax, 'Location', 'eastoutside', 'FontSize', 7); end
end
title(tl, {'CCNY: aggregate UWB drone interference, percent of all time (solid)', ...
    'Dotted: percent of tracking time only (the dish receives about 6% of the day for EESS, 4% for MetSat)'});
exportgraphics(fig2, fullfile(out_dir, 'fig_ccny2_time_basis_ccdf.png'), 'Resolution', 200);
agg_tbl = cell2table(agg_rows, 'VariableNames', {'link', 'case', 'active_per_km2', 'n_iter', 'tail_samples', ...
    'margin_long_dB', 'margin_short_dB', 'margin_short_lo_dB', 'margin_short_hi_dB', ...
    'pct_trk_above_short', 'pct_trk_above_short_lo', 'pct_trk_above_short_hi', 'poisson_pred_pct', ...
    'pct_all_time_above_short', 'min_per_year_above_short', 'allowed_min_per_year', 'r_req_long_km', 'r_req_short_km', ...
    'margin_short_app20_dB', 'pct_trk_above_short_app20', 'r_req_short_app20_km'});
disp('Aggregate drones at CCNY (no geofence; margins positive = criterion exceeded; 95% intervals):'); disp(agg_tbl);
writetable(agg_tbl, fullfile(out_dir, 'aggregate_drones.csv'));
fp_tbl = table([links.name]', cellfun(@(s) s.p1_short, fp)', cellfun(@(s) s.area_short_km2, fp)', ...
    cellfun(@(s) s.area_short_ci_km2(1), fp)', cellfun(@(s) s.area_short_ci_km2(2), fp)', ...
    cellfun(@(s) s.r_hit_max_km, fp)', 'VariableNames', {'link', 'p1_short', 'area_short_km2', 'area_short_lo_km2', ...
    'area_short_hi_km2', 'r_hit_max_km'});   % long-term footprint omitted: it extends past the 3 km sampling disk
disp('Single-device exceedance footprint (averaged over passes, heights, and P.528 time):'); disp(fp_tbl);
writetable(fp_tbl, fullfile(out_dir, 'footprint.csv'));

%% 9. Ground UWB baseline at CCNY with the validated P.2108 port
hand = struct('name', "handheld outdoor", 'density_per_km2', 7, 'h_min_m', 1.5, 'h_max_m', 1.5, ...
    'r_max_km', 20, 'eirp_offset_dB', 0, 'extra_loss_db', 0, 'clutter', true);
indoor = struct('name', "indoor", 'density_per_km2', 500, 'h_min_m', 1.5, 'h_max_m', 1.5, ...
    'r_max_km', 5, 'eirp_offset_dB', 0, 'extra_loss_db', 17, 'clutter', true);
hand.n_iter = 2e4; indoor.n_iter = 5e3;   % 39,000 indoor devices per iteration: 5e3 iterations resolve the 20% level
base_rows = {};
for k = 1:2
    crit = eess_criteria_rev1(links(k).f_mhz, p);
    for pop = [hand indoor]
        o = aggregate_drone_mc_rev4(p, pop, ps{k}, F{k}, links(k).f_mhz, 'n_iter', pop.n_iter, 'chunk', 50, ...
            'pct_exceed', [crit.long_pct crit.short_pct], 'r_edges_km', edges);
        oh = aggregate_drone_mc_rev4(p, pop, ps{k}, F{k}, links(k).f_mhz, 'n_iter', pop.n_iter, 'chunk', 50, ...
            'pct_exceed', [crit.long_pct crit.short_pct], 'r_edges_km', edges, 'clutter_short', "hold");
        base_rows(end+1, :) = {links(k).name, pop.name, pop.density_per_km2, o.ci.level_db(1) - crit.long_dBm, ...
            o.ci.level_db_lo(1) - crit.long_dBm, o.ci.level_db_hi(1) - crit.long_dBm, ...
            o.ci.level_db(2) - crit.short_dBm, 100 * o.ci.frac(2), o.ci.frac(2) * ps{k}.frac_tracking * min_per_year, ...
            oh.ci.level_db(1) - crit.long_dBm}; %#ok<SAGROW> four rows
        fprintf('Baseline %s, %s done (%.0f s)\n', links(k).name, pop.name, toc(t_start));
    end
end
base_tbl = cell2table(base_rows, 'VariableNames', {'link', 'population', 'active_per_km2', 'margin_long_dB', ...
    'margin_long_lo_dB', 'margin_long_hi_dB', 'margin_short_dB', 'pct_trk_above_short', 'min_per_year_above_short', ...
    'margin_long_hold_dB'});
disp(['Ground UWB baseline at CCNY (ECC Report 327 urban densities via FiRa; validated P.2108; ' ...
    'no clutter below 0.25 km; last column holds the 0.25 km loss below 0.25 km):']); disp(base_tbl);
writetable(base_tbl, fullfile(out_dir, 'ground_baseline.csv'));

%% 10. Clutter-model swap at NEN WG1: what changed
d_grid = logspace(log10(0.25), 2, 300)';
p_grid = [1 10 50 90 99];
L_old = p2108_terrestrial_clutter_rev1(8.16, d_grid, p_grid);
L_new = p2108_terrestrial_rev1(8.16, d_grid, p_grid, q_inverse="exact");
dL = L_old - L_new;
fprintf('Clutter swap: rev1 formula minus validated port, max %.2f dB (d < 2 km), max %.3f dB (d >= 2 km).\n', ...
    max(dL(d_grid < 2, :), [], 'all'), max(abs(dL(d_grid >= 2, :)), [], 'all'));
fig3 = figure('Visible', 'off'); theme(fig3, 'light');
semilogx(d_grid, dL, 'LineWidth', 1.2); grid on;
legend(compose('%g%% of locations', p_grid), 'Location', 'northeast');
xlabel('Distance (km)'); ylabel('Old minus validated clutter loss (dB)');
title('P.2108 sec. 3.2 at 8.16 GHz: effect of the validated port');
exportgraphics(fig3, fullfile(out_dir, 'fig_ccny3_clutter_swap.png'), 'Resolution', 200);

p_wg1 = uwb_eess_params_rev1(); p_wg1.es.diam_m = 11.3;
v = victim_systems_rev2();
wg1 = struct('name', "WG1 Wallops", 'lat_deg', v.lat_deg(contains(v.name, "WG1")), 'lon_deg', v.lon_deg(contains(v.name, "WG1")), 'alt_m', 10);
ps_wg1 = pass_statistics_rev1(wg1);
[F_wg1, ~] = p528_loss_table_rev1(8160, p_wg1.es.h_m);
swap_rows = {};
crit = eess_criteria_rev1(8160, p_wg1);
for pop = [hand indoor]
    o3 = aggregate_drone_mc_rev3(p_wg1, pop, ps_wg1, F_wg1, 8160, 'n_iter', pop.n_iter, 'chunk', 50);
    o4z = aggregate_drone_mc_rev4(p_wg1, pop, ps_wg1, F_wg1, 8160, 'n_iter', pop.n_iter, 'chunk', 50, 'clutter_short', "zero");
    o4h = aggregate_drone_mc_rev4(p_wg1, pop, ps_wg1, F_wg1, 8160, 'n_iter', pop.n_iter, 'chunk', 50, 'clutter_short', "hold");
    swap_rows(end+1, :) = {pop.name, o3.pct_dBm(1, 1) - crit.long_dBm, ...
        o4z.ci.level_db(1) - crit.long_dBm, o4z.ci.level_db_lo(1) - crit.long_dBm, o4z.ci.level_db_hi(1) - crit.long_dBm, ...
        o4h.ci.level_db(1) - crit.long_dBm}; %#ok<SAGROW> two rows
end
swap_tbl = cell2table(swap_rows, 'VariableNames', {'population', 'margin_long_rev3_dB', ...
    'margin_long_rev4_zero_dB', 'rev4_zero_lo_dB', 'rev4_zero_hi_dB', 'margin_long_rev4_hold_dB'});
disp(['WG1 ground baseline, long-term margin: rev3 (old formula, no clutter below 0.25 km), ' ...
    'rev4 zero (validated port, same short-path rule), rev4 hold (0.25 km loss below 0.25 km):']); disp(swap_tbl);
writetable(swap_tbl, fullfile(out_dir, 'wg1_clutter_swap.csv'));
fprintf('Step 10 done (%.0f s)\n', toc(t_start));

%% 11. Consistency with ECC Report 327 and measured device emissions
cc_ccny = ecc327_consistency_rev1(p, F{1}, ps{1}, 8160);
cc_wg1 = ecc327_consistency_rev1(p_wg1, F_wg1, ps_wg1, 8160);
cc_ccny.station = repmat("CCNY 2.4 m", height(cc_ccny), 1);
cc_wg1.station = repmat("WG1 11.3 m", height(cc_wg1), 1);
cc_tbl = [cc_ccny; cc_wg1];
disp('Consistency with ECC Report 327 (this model vs published ECC distances):'); disp(cc_tbl);
writetable(cc_tbl, fullfile(out_dir, 'ecc327_consistency.csv'));
airtag = table(["Channel 9 average EIRP, worst configuration"; "Channel 9 average EIRP, lowest"; ...
    "Channel 9 peak EIRP, worst configuration"; "Channel 9 -10 dB bandwidth"], ...
    [-41.84; -43.45; -0.6; 525.5], [-41.3; -41.3; 0; 500], ["dBm/MHz"; "dBm/MHz"; "dBm/50 MHz"; "MHz (minimum)"], ...
    'VariableNames', {'quantity', 'measured', 'limit_or_model', 'unit'});
airtag.headroom_dB = airtag.limit_or_model - airtag.measured;
airtag.headroom_dB(4) = NaN;
disp('Apple AirTag (FCC ID BCGA2187), UL test report 12791034-E2V3, sec. 8.1-8.2:'); disp(airtag);
writetable(airtag, fullfile(out_dir, 'airtag_measured.csv'));

save(fullfile(out_dir, 'results_ccny_rev1.mat'), 'station_tbl', 'pass_tbl', 'beam_tbl', 'lb_beam', 'lb_side', ...
    'dens_nyc', 'dens_man', 'cases', 'agg_tbl', 'fp_tbl', 'base_tbl', 'swap_tbl', 'cc_tbl', 'airtag', 'mc', ...
    'area_short', 'area_long', 'bw3');
fprintf('Done in %.0f s. Outputs in %s\n', toc(t_start), out_dir);
diary off;
