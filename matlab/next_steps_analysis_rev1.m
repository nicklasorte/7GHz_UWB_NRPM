%NEXT_STEPS_ANALYSIS_REV1 P.528 propagation, real pass statistics, handheld baseline, mitigations, and risk.
%   Implements the depth, altitude, and range items of the analysis plan:
%     1. ITU-R P.528-5 loss (github.com/nicklasorte/itu_p528) in place of free space
%     2. Real dish pointing from SGP4 passes of Aqua, Terra, Landsat 8, and Landsat 9
%        at NEN WG1 (Wallops) and AS1 (Fairbanks)
%     3. Aggregate drone Monte Carlo with both, per site and density
%     4. Handheld and indoor UWB baseline (the AirTag-type environment)
%     5. Mitigation menu, quantified
%     6. Risk metric: minutes per year above the criteria while tracking
%   Requires itu_p528 cloned next to this repo (or on the path) and network
%   access to CelesTrak the first time (TLEs are then cached in ../data).
%   Writes figures and results_next_steps_rev1.mat to ../output.

clearvars; close all;
here = fileparts(mfilename('fullpath'));
out_dir = fullfile(here, '..', 'output');
if ~isfolder(out_dir), mkdir(out_dir); end
t_start = tic;

p = uwb_eess_params_rev1();
v = victim_systems_rev2();
f = 8160;                                      % EESS, inside channel 9
min_per_year = 365.25 * 24 * 60;
p.es.diam_m = 11.3;

sites = struct('name', {"WG1 Wallops", "AS1 Fairbanks"}, ...
    'lat_deg', {v.lat_deg(contains(v.name, "WG1")), v.lat_deg(contains(v.name, "AS1"))}, ...
    'lon_deg', {v.lon_deg(contains(v.name, "WG1")), v.lon_deg(contains(v.name, "AS1"))}, ...
    'alt_m', {10, 10});                        % TODO site elevation; only the antenna height matters for geometry

%% 1. P.528 loss table
[F, tbl] = p528_loss_table_rev1(f, p.es.h_m);
fprintf('P.528 table: %d entries, modes LOS/diff/tropo = %d/%d/%d (%.0f s elapsed)\n', numel(tbl.A_db), ...
    nnz(tbl.mode == 1), nnz(tbl.mode == 2), nnz(tbl.mode == 3), toc(t_start));

%% 2. Single drone: P.528 vs free space
h_d = p.drone.h_max_m;
se_fs = single_entry_separation_rev1(p, h_d, [5 13], f);
cmp = table([5; 13], se_fs.sep_long_km', NaN(2,1), NaN(2,1), se_fs.sep_short_km', NaN(2,1), NaN(2,1), ...
    'VariableNames', {'el_deg','long_fs_km','long_p528_p50_km','long_p528_p1_km','short_fs_km','short_p528_p50_km','short_p528_p1_km'});
for e = 1:2
    s50 = single_entry_p528_rev1(p, F, h_d, cmp.el_deg(e), f, 50);
    s1 = single_entry_p528_rev1(p, F, h_d, cmp.el_deg(e), f, 1);
    cmp.long_p528_p50_km(e) = s50.sep_long_km;  cmp.long_p528_p1_km(e) = s1.sep_long_km;
    cmp.short_p528_p50_km(e) = s50.sep_short_km; cmp.short_p528_p1_km(e) = s1.sep_short_km;
end
disp('Single drone at 121.92 m in the dish azimuth: free space vs P.528 (km):'); disp(cmp);

%% 3. Pass statistics
ps = cell(1, numel(sites));
pass_tbl = table('Size', [numel(sites) 4], 'VariableTypes', {'string','double','double','double'}, ...
    'VariableNames', {'site','frac_tracking','frac_trk_below_6deg','tracking_min_per_day'});
for s = 1:numel(sites)
    ps{s} = pass_statistics_rev1(sites(s));
    pass_tbl.site(s) = sites(s).name;
    pass_tbl.frac_tracking(s) = ps{s}.frac_tracking;
    pass_tbl.frac_trk_below_6deg(s) = ps{s}.frac_tracking_below_6deg;
    pass_tbl.tracking_min_per_day(s) = ps{s}.frac_tracking * 24 * 60;
end
disp('Dish tracking statistics (Aqua, Terra, Landsat 8, Landsat 9; 30 days, el >= 5 deg):'); disp(pass_tbl);
fig6 = figure('Visible', 'off'); theme(fig6, 'light');
bar(categorical(compose("%g-%g", ps{1}.el_edges_deg(1:end-1)', ps{1}.el_edges_deg(2:end)')), ...
    100 * [ps{1}.el_hist_frac; ps{2}.el_hist_frac]');
ylabel('Share of tracking time (%)'); xlabel('Dish elevation (deg)'); grid on;
legend([sites.name], 'Location', 'northeast'); title('Where the dish points while tracking');
exportgraphics(fig6, fullfile(out_dir, 'fig6_pass_elevation_histogram.png'), 'Resolution', 200);

%% 4. Aggregate drones with P.528 and real pointing
dens = [0.01 0.1 1];
n_iter_by_dens = [1e5 1e5 2e4];
drone = struct('name', "drones", 'density_per_km2', NaN, 'h_min_m', p.drone.h_min_m, 'h_max_m', p.drone.h_max_m, ...
    'r_max_km', 60, 'eirp_offset_dB', 0, 'extra_loss_db', 0, 'clutter', false);
agg_rows = {};
mc = cell(numel(sites), numel(dens));
for s = 1:numel(sites)
    for k = 1:numel(dens)
        pop = drone; pop.density_per_km2 = dens(k);
        o = aggregate_drone_mc_rev2(p, pop, ps{s}, F, f, 'n_iter', n_iter_by_dens(k));
        [r_l, ~] = required_exclusion_radius_rev1(o.r_ex_km, o.pct_dBm(1, :), o.crit.long_dBm);
        [r_s, ~] = required_exclusion_radius_rev1(o.r_ex_km, o.pct_dBm(2, :), o.crit.short_dBm);
        risk_min = o.frac_exceed_short(1) * ps{s}.frac_tracking * min_per_year;
        agg_rows(end+1, :) = {sites(s).name, dens(k), o.pct_dBm(1,1) - o.crit.long_dBm, o.pct_dBm(2,1) - o.crit.short_dBm, ...
            r_l, r_s, 100 * o.frac_exceed_short(1), risk_min}; %#ok<SAGROW> six rows
        mc{s, k} = rmfield_safe(o);
        fprintf('%s, %.0e /km^2 done (%.0f s)\n', sites(s).name, dens(k), toc(t_start));
    end
end
agg_tbl = cell2table(agg_rows, 'VariableNames', {'site','active_density_per_km2','margin_long_dB','margin_short_dB', ...
    'r_req_long_km','r_req_short_km','pct_trk_time_above_short','minutes_per_year_above_short'});
disp('Aggregate drones, P.528 loss and real pointing:'); disp(agg_tbl);

%% 5. Handheld and indoor UWB baseline at WG1 (the environment that exists today)
% Active densities: ECC Report 327 urban scenario as summarized in the FiRa (2025) report
% (about 7 active outdoor and 500 active indoor devices per km^2). Building entry loss 17 dB
% (ECC Report 327 / CEPT Report 84). Body loss not applied (TODO).
hand = struct('name', "handheld outdoor", 'density_per_km2', 7, 'h_min_m', 1.5, 'h_max_m', 1.5, ...
    'r_max_km', 20, 'eirp_offset_dB', 0, 'extra_loss_db', 0, 'clutter', true);
indoor = struct('name', "indoor", 'density_per_km2', 500, 'h_min_m', 1.5, 'h_max_m', 1.5, ...
    'r_max_km', 5, 'eirp_offset_dB', 0, 'extra_loss_db', 17, 'clutter', true);
base_rows = {};
for pop = [hand indoor]
    o = aggregate_drone_mc_rev2(p, pop, ps{1}, F, f, 'n_iter', 2e4);
    base_rows(end+1, :) = {pop.name, pop.density_per_km2, o.pct_dBm(1,1) - o.crit.long_dBm, o.pct_dBm(2,1) - o.crit.short_dBm, ...
        o.frac_exceed_short(1) * ps{1}.frac_tracking * min_per_year}; %#ok<SAGROW> two rows
    fprintf('%s baseline done (%.0f s)\n', pop.name, toc(t_start));
end
base_tbl = cell2table(base_rows, 'VariableNames', {'population','active_density_per_km2','margin_long_dB','margin_short_dB','minutes_per_year_above_short'});
disp('Ground UWB baseline at WG1 (urban densities, an upper bound for a rural site):'); disp(base_tbl);

%% 6. Mitigation menu at WG1, drones at 0.1 active per km^2
cases = {
    "Baseline",                                   drone,                                         0
    "Altitude cap 30 m",                          setfield(drone, 'h_max_m', 30),                0 %#ok<SFLD>
    "Downward antenna, -5 dB (CEPT -46.3 dBm/MHz)", setfield(drone, 'eirp_offset_dB', 5),         0 %#ok<SFLD>
    "EIRP cap -64.3 dBm/MHz (ECC aircraft MetSat)", setfield(drone, 'eirp_offset_dB', 23),        0 %#ok<SFLD>
    "Duty cycle 1% instead of 5% (density x0.2)", drone,                                         1
    "Altitude cap 30 m + downward antenna",       setfield(setfield(drone, 'h_max_m', 30), 'eirp_offset_dB', 5), 0 %#ok<SFLD>
    };
mit_rows = {};
for j = 1:size(cases, 1)
    pop = cases{j, 2};
    pop.density_per_km2 = 0.1 * (1 - 0.8 * cases{j, 3});
    o = aggregate_drone_mc_rev2(p, pop, ps{1}, F, f, 'n_iter', 1e5);
    [r_l, ~] = required_exclusion_radius_rev1(o.r_ex_km, o.pct_dBm(1, :), o.crit.long_dBm);
    [r_s, ~] = required_exclusion_radius_rev1(o.r_ex_km, o.pct_dBm(2, :), o.crit.short_dBm);
    mit_rows(end+1, :) = {cases{j, 1}, o.pct_dBm(2,1) - o.crit.short_dBm, max(r_l, r_s), ...
        o.frac_exceed_short(1) * ps{1}.frac_tracking * min_per_year}; %#ok<SAGROW> six rows
end
mit_tbl = cell2table(mit_rows, 'VariableNames', {'mitigation','margin_short_r0_dB','geofence_km','minutes_per_year_above_short'});
disp('Mitigation menu at WG1, 0.1 active drones per km^2:'); disp(mit_tbl);
fprintf('Reference allowance: ITU-R SA.1027-6 short-term 0.005%% of time = %.1f minutes per year.\n', 0.005 / 100 * min_per_year);

fig7 = figure('Visible', 'off'); theme(fig7, 'light');
barh(categorical(mit_tbl.mitigation, mit_tbl.mitigation), mit_tbl.geofence_km); grid on;
xlabel('Geofence radius needed (km)'); title('Mitigation menu, WG1, 0.1 active drones per km^2 (P.528, real passes)');
exportgraphics(fig7, fullfile(out_dir, 'fig7_mitigation_menu.png'), 'Resolution', 200);

save(fullfile(out_dir, 'results_next_steps_rev1.mat'), 'cmp', 'pass_tbl', 'agg_tbl', 'base_tbl', 'mit_tbl', 'tbl', 'mc', 'sites');
for s = 1:numel(sites)
    pss = rmfield(ps{s}, {'t', 'az_deg', 'el_deg', 'tracking', 'sat_idx'});
    save(fullfile(out_dir, sprintf('pass_summary_site%d_rev1.mat', s)), 'pss');
end
fprintf('Done in %.0f s. Outputs in %s\n', toc(t_start), out_dir);

function o = rmfield_safe(o)
% keep results small: drop nothing large (rev2 output has no per-iteration array)
end
