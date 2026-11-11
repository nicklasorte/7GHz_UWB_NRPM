%EXAMPLE_BRIDGE_REV1 Boresight worst case, normal conditions, and the bridge between them.
%   Answers the research question "at what point does a drone, operating
%   under normal conditions with a typical UWB device, cause interference
%   to a NASA receiver?" with a barbell:
%
%     Bookend A  one drone on the dish boresight, at the limit, continuous
%     Bookend B  a typical device on drones flying normally, local traffic
%     Bridge     the change from A to B one assumption at a time
%
%   Runs the NASA NEN station at Wallops (WG1, 11.3 m) as the primary case
%   and CCNY (2.4 m, Manhattan) for comparison, on the EESS 8160 MHz link
%   against the ITU-R SA.1027-6 short-term criterion.
%
%   Steps per station:
%     1. Pass statistics (SGP4) and the P.528 loss table
%     2. Beam dwell on a hovering drone placed on boresight (Bookend A)
%     3. Shape of the single-drone exceedance region at 5 deg (mean chord)
%     4. Single-drone footprints at the limit, at measured EIRP, at the
%        lowest measured EIRP, and with a 20 dB apportionment
%     5. Local drone density from FAA and Census data
%     6. Bookend B and the crossing budget
%     7. Bridge table and waterfall chart
%     8. Ranking (tornado) chart around Bookend B
%     9. Duty-cycle sweep, from 0.1% to continuous transmission, and the
%        duty cycle at which each case reaches the allowance
%
%   Assumption: drones are allowed to transmit UWB. 47 CFR 15.521(a)
%   prohibits it today; the analysis takes the NPRM question (FCC 26-66)
%   as answered yes, with no duty-cycle limit, so it sweeps the duty cycle
%   all the way to continuous transmission while airborne. The 1% base
%   case is the NPRM's proposed limit for its new device category, which
%   may not apply to drones.
%
%   Outputs go to ../output/bridge/. Requires itu_p528 cloned next to
%   this repo, and network access to CelesTrak if a TLE file is missing.

close all;
here = fileparts(mfilename('fullpath'));
addpath(here);
addpath(fullfile(here, '..', '..', 'itu_p528', 'src'));
out_dir = fullfile(here, '..', 'output', 'bridge');
if ~isfolder(out_dir), mkdir(out_dir); end
diary(fullfile(out_dir, 'run_log_bridge_rev1.txt')); diary on;
t_start = tic;
fprintf('Run started %s\n', string(datetime('now')));
f_mhz = 8160;

%% Inputs shared by both stations
eirp_meas_dB = 41.84 - 41.3;       % AirTag channel 9 worst average EIRP below the limit (UL 12791034-E2V3 sec. 8.1)
eirp_low_dB = 43.45 - 41.3;        % AirTag lowest average EIRP below the limit (same report)
app_dB = 20;                       % ECC Report 327 sec. 5.5 apportionment for UWB (decision, not physics)
duty_base = 0.01;                  % FCC 26-66 (ET Docket 26-245) proposed new-category duty cycle: under 1% in any 24 hours
duty_range = [0.0025 0.05];        % ECC Report 327 Table 18 activity factors 0.25%-5% (via FiRa)
duty_sweep = logspace(-3, 0, 61);  % 0.1% to continuous transmission while airborne
share_base = 1;                    % share of drones carrying channel 9 UWB: no public data; 100% bounds it
share_range = [0.1 1];
peak_range = [1 6];                % annual average to a sustained peak-hour bound
speeds = [2.2 6.7 13.4];           % m/s: 5, 15, and 30 mph, the ASSURE A83 telemetry speed bins
n_per_call = 4e6; n_calls = 10;    % footprint samples: 4e7 per case, for hundreds of hits in a sliver-shaped region
v = victim_systems_rev2();
stations = struct( ...
    'name', {"NEN WG1 Wallops (NASA, 11.3 m)", "CCNY Manhattan (2.4 m)"}, ...
    'tag', {"wallops", "ccny"}, ...
    'diam_m', {11.3, 2.4}, 'h_m', {10, 20}, ...
    'site', {struct('name', "WG1 Wallops", 'lat_deg', v.lat_deg(contains(v.name, "WG1")), 'lon_deg', v.lon_deg(contains(v.name, "WG1")), 'alt_m', 10), ...
             struct('name', "CCNY NOAA-CREST SRS", 'lat_deg', 40.820, 'lon_deg', -73.950, 'alt_m', 50)}, ...
    'tle', {string(fullfile(here, '..', 'data', 'tle_eess.txt')), string(fullfile(here, '..', 'data', 'tle_ccny_eess.txt'))}, ...
    'norad', {[27424 25994 39084 49260], [27424 25994]}, ...
    'pop_per_km2', {33859 / (450 * 2.589988), 8584629 / 778.2}, ...  % Accomack County 2025 / 450 sq mi; NYC (see density_nyc.csv)
    'state_flights', {1646290, 1366899}, 'state_pop', {8.88e6, 20002427}, ...
    'r_sample_km', {2, 1.5}, 'r_sample_app_km', {5, 8});   % just past the farthest hits, so samples land in the sliver
% Wallops: FAA survey Table 6 (Virginia 1,646,290 flights); Virginia 8.88 million (Weldon Cooper Center, July 1, 2025);
% Accomack County 33,859 (Census, 2025 county totals) over 450 sq mi of land.

summary = {};
for s = 1:numel(stations)
    st = stations(s);
    fprintf('\n===== %s =====\n', st.name);
    p = uwb_eess_params_rev1();
    p.es.diam_m = st.diam_m; p.es.h_m = st.h_m;
    crit = eess_criteria_rev1(f_mhz, p);

    %% 1. Passes and propagation
    ps = pass_statistics_rev1(st.site, 'norad_ids', st.norad, 'tle_file', st.tle);
    F = p528_loss_table_rev1(f_mhz, p.es.h_m);
    fprintf('Tracking %.2f%% of the time (%s).\n', 100 * ps.frac_tracking, strjoin(ps.sat_names, ', '));

    %% 2. Bookend A: beam dwell on a hovering drone on boresight
    bdA = beam_dwell_rev1(p, ps, F, f_mhz);
    bdM = beam_dwell_rev1(p, ps, F, f_mhz, 'eirp_offset_dB', eirp_meas_dB);
    low = bdA.el_deg < 10 & isfinite(bdA.dwell_s);
    fprintf(['Bookend A: beamwidth %.3f deg; boresight margin %.1f dB at 5-10 deg (max %.1f dB); ' ...
        'dish rate median %.3f deg/s below 10 deg; dwell median %.2f s, max %.2f s below 10 deg.\n'], ...
        bdA.beamwidth_deg, median(bdA.margin_dB(low)), max(bdA.margin_dB, [], 'omitnan'), ...
        median(bdA.omega_deg_s(low), 'omitnan'), median(bdA.dwell_s(low), 'omitnan'), max(bdA.dwell_s(low)));
    fprintf('Hovering at the ideal spot before every pass: %.4f%% of tracking time above the short-term criterion.\n', 100 * bdA.hover_frac_trk);
    writetable(bdA.pass, fullfile(out_dir, "beam_dwell_passes_" + st.tag + ".csv"));

    %% 3. Shape of the exceedance region, dish at 5 deg, drone at 400 ft, measured EIRP
    xg = -2:0.005:2; yg = -1:0.005:12;                % strip along the pointing azimuth (north)
    [X, Y] = meshgrid(xg, yg);
    dev = struct('r_km', hypot(X(:), Y(:)), 'az_rad', atan2(X(:), Y(:)), 'h_m', repmat(p.drone.h_max_m, numel(X), 1), ...
        'p_time', repmat(50, numel(X), 1), 'p_loc', []);
    pt = struct('el_rad', repmat(deg2rad(5), numel(X), 1), 'az_rad', zeros(numel(X), 1));
    geo = struct('ae_km', p.prop.k_factor * p.prop.re_km, 'r1_km', p.prop.k_factor * p.prop.re_km + p.es.h_m / 1000);
    ant = struct('diam_m', p.es.diam_m, 'f_mhz', f_mhz, 'eff', p.es.eff, 'pattern', "single");
    e10 = uwb_power_in_band_rev1(f_mhz, p.crit.ref_bw_MHz, p.uwb);
    I = reshape(10 * log10(device_interference_rev1(dev, pt, geo, F, ant, e10 - eirp_meas_dB - p.uwb.pol_loss_dB)), size(X));
    rg = region_chord_rev1(xg, yg, I, crit.short_dBm);
    if any(I(:, [1 end]) > crit.short_dBm, 'all') || any(I([1 end], :) > crit.short_dBm, 'all')
        warning('example_bridge_rev1:grid', 'Exceedance region touches the map edge; enlarge the strip.');
    end
    fprintf('Exceedance region at 5 deg: %.4f km^2, %.0f m long, %.0f m wide, mean chord %.0f m.\n', ...
        rg.area_km2, 1000 * rg.length_km, 1000 * rg.width_km, 1000 * rg.mean_chord_km);

    %% 4. Footprints averaged over real pointing
    drone = struct('name', "drones", 'density_per_km2', 1, 'h_min_m', p.drone.h_min_m, 'h_max_m', p.drone.h_max_m, ...
        'r_max_km', 60, 'eirp_offset_dB', 0, 'extra_loss_db', 0, 'clutter', false);
    offs = [0, eirp_meas_dB, eirp_low_dB, eirp_meas_dB - app_dB];
    rs = [st.r_sample_km, st.r_sample_km, st.r_sample_km, st.r_sample_app_km];
    A = zeros(1, 4); A_lo = A; A_hi = A; hit = A; nh = A;
    for k = 1:4
        pop = drone; pop.eirp_offset_dB = offs(k);
        [A(k), A_lo(k), A_hi(k), nh(k), hit(k)] = footprint_reps(p, pop, ps, F, f_mhz, rs(k), n_per_call, n_calls);
        if hit(k) > 0.8 * rs(k)
            warning('example_bridge_rev1:sample', 'Footprint %d: farthest hit %.2f km is near the %.2f km sample radius.', k, hit(k), rs(k));
        end
    end
    fp_tbl = table(["At the limit"; "Measured (AirTag worst)"; "Measured (AirTag lowest)"; "Measured, 20 dB apportionment"], ...
        -offs(:), A(:) * 1e6, A_lo(:) * 1e6, A_hi(:) * 1e6, nh(:), hit(:), ...
        'VariableNames', {'device', 'eirp_vs_limit_dB', 'footprint_m2', 'footprint_lo_m2', 'footprint_hi_m2', 'hits', 'farthest_hit_km'});
    disp(fp_tbl); writetable(fp_tbl, fullfile(out_dir, "footprints_" + st.tag + ".csv"));

    %% 5. Local density
    dd = drone_density_faa_rev1(st.pop_per_km2, 'state_flights', st.state_flights, 'state_pop', st.state_pop, ...
        'peak_factor', 1, 'equipped_frac', 1, 'activity', 1);
    rho = dd.Properties.UserData.airborne_avg_per_km2;
    fprintf('Density: %.1f residents/km^2, state ratio %.2f -> %.2e airborne drones/km^2 on average.\n', ...
        st.pop_per_km2, dd.Properties.UserData.state_ratio, rho);

    %% 6. Bookend B and the crossing budget
    cbT = crossing_budget_rev1(A(2), rg.mean_chord_km, ps.frac_tracking, crit.short_pct, 'basis', "tracking", ...
        'duty', duty_base, 'speeds_mps', speeds, 'density_per_km2', rho * share_base);
    cbA = crossing_budget_rev1(A(2), rg.mean_chord_km, ps.frac_tracking, crit.short_pct, 'basis', "all", ...
        'duty', duty_base, 'speeds_mps', speeds, 'density_per_km2', rho * share_base);
    fprintf(['Crossing budget (measured EIRP, %.0f%% duty): allowed density %.3g/km^2 (tracking basis), %.3g/km^2 (all time); ' ...
        'local %.2e/km^2 -> %.2g and %.2g of the allowance.\n'], 100 * duty_base, cbT.rho_allow_per_km2, cbA.rho_allow_per_km2, ...
        rho * share_base, cbT.ratio_to_allowance, cbA.ratio_to_allowance);
    cb_tbl = cbT.table; cb_tbl.crossings_allowed_all_time = cbA.table.crossings_allowed;
    disp(cb_tbl); writetable(cb_tbl, fullfile(out_dir, "crossing_budget_" + st.tag + ".csv"));

    %% 7. Bridge
    ing = struct('margin_bore_dB', max(bdA.margin_dB(bdA.el_deg < 10), [], 'omitnan'), 'hover_frac_trk', bdA.hover_frac_trk, ...
        'rho_per_km2', rho, 'uwb_share', share_base, 'area_limit_km2', A(1), 'area_meas_km2', A(2), ...
        'area_app_km2', A(4), 'duty', duty_base, 'tracking_frac', ps.frac_tracking, 'allowance_pct', crit.short_pct);
    br = bridge_steps_rev1(ing);
    disp(br(:, {'step', 'label', 'frac_above', 'ratio_dB'}));
    writetable(br, fullfile(out_dir, "bridge_" + st.tag + ".csv"));
    bridge_chart_rev1(br, "Bridge from boresight worst case to normal conditions: " + st.name, ...
        'file', fullfile(out_dir, "fig_bridge_" + st.tag + ".png"));

    %% 8. Ranking around Bookend B (tracking basis, full criterion)
    rdb = @(duty, share, peak, area, basis) 10 * log10(max(duty * (1 - exp(-rho * peak * share * area)) * basis / (crit.short_pct / 100), realmin));
    base = rdb(duty_base, share_base, 1, A(2), 1);
    names = ["UWB duty cycle"; "Share of drones carrying UWB"; "Drone density"; "Device EIRP"; "Time basis"; "Apportionment"];
    lo = [rdb(duty_range(1), share_base, 1, A(2), 1); rdb(duty_base, share_range(1), 1, A(2), 1); ...
          rdb(duty_base, share_base, peak_range(1), A(2), 1); rdb(duty_base, share_base, 1, A(3), 1); ...
          rdb(duty_base, share_base, 1, A(2), ps.frac_tracking); base];
    hi = [rdb(duty_range(2), share_base, 1, A(2), 1); rdb(duty_base, share_range(2), 1, A(2), 1); ...
          rdb(duty_base, share_base, peak_range(2), A(2), 1); rdb(duty_base, share_base, 1, A(1), 1); ...
          base; rdb(duty_base, share_base, 1, A(4), 1)];
    lo_l = ["0.25%"; "10%"; "Average"; "Lowest measured"; "All time"; "None"];
    hi_l = ["5%"; "100%"; "Peak x6"; "At the limit"; "Tracking time"; "20 dB"];
    [~, tor] = tornado_chart_rev1(names, lo, hi, base, 'low_labels', lo_l, 'high_labels', hi_l, ...
        'title_str', "What moves the normal-conditions result: " + st.name, ...
        'file', fullfile(out_dir, "fig_tornado_" + st.tag + ".png"));
    disp(tor); writetable(tor, fullfile(out_dir, "tornado_" + st.tag + ".csv"));

    %% 9. Duty-cycle sweep and break-even duty cycle
    ratio = @(duty, area, basis, pk) 10 * log10(max(duty * (1 - exp(-rho * pk * share_base * area)) * basis / (crit.short_pct / 100), realmin));
    curves = [ratio(duty_sweep, A(2), 1, 1); ratio(duty_sweep, A(2), ps.frac_tracking, 1); ratio(duty_sweep, A(4), 1, 1)];
    names_c = ["Tracking-time basis, full criterion"; "All-time basis, full criterion"; "Tracking-time basis, 20 dB apportionment"];
    % ratio is linear in duty, so the break-even duty is base / ratio; above 1 means continuous transmission stays under.
    % Rows 4-6 repeat rows 1-3 at a sustained peak-hour density (peak_range(2) times the annual average).
    areas = [A(2); A(2); A(4)]; bases = [1; ps.frac_tracking; 1];
    pk = [ones(3, 1); repmat(peak_range(2), 3, 1)];
    areas = [areas; areas]; bases = [bases; bases];
    be = zeros(6, 1); cont = zeros(6, 1);
    for c = 1:6
        be(c) = duty_base * 10^(-ratio(duty_base, areas(c), bases(c), pk(c)) / 10);
        cont(c) = ratio(1, areas(c), bases(c), pk(c));
    end
    be_pct = 100 * be; be_pct(be >= 1) = NaN;          % NaN: no break-even; continuous transmission stays under
    dens_lbl = [repmat("Annual average", 3, 1); repmat(sprintf("Sustained peak (x%g)", peak_range(2)), 3, 1)];
    be_tbl = table(dens_lbl, [names_c; names_c], cont, be_pct, be >= 1, 'VariableNames', ...
        {'density', 'case', 'continuous_ratio_dB', 'break_even_duty_pct', 'continuous_stays_under'});
    fprintf('Duty-cycle break-even (share of drones carrying UWB %.0f%%, average density):\n', 100 * share_base); disp(be_tbl);
    writetable(be_tbl, fullfile(out_dir, "duty_break_even_" + st.tag + ".csv"));
    figd = figure('Visible', 'off', 'Position', [100 100 900 520]); theme(figd, 'light');
    axd = axes(figd); %#ok<LAXES> one new figure per station
    hold(axd, 'on'); grid(axd, 'on'); set(axd, 'XScale', 'log');
    sty = ["-", ":", "--"];
    for c = 1:3
        plot(axd, 100 * duty_sweep, curves(c, :), sty(c), 'LineWidth', 1.6, 'DisplayName', names_c(c));
    end
    yline(axd, 0, 'r-', 'Allowance', 'LineWidth', 1.2, 'HandleVisibility', 'off');
    xline(axd, 100 * duty_base, 'k-.', 'NPRM 1%', 'HandleVisibility', 'off', 'LabelOrientation', 'horizontal', 'LabelVerticalAlignment', 'bottom');
    xline(axd, 100 * duty_range(2), 'k:', 'ECC 5%', 'HandleVisibility', 'off', 'LabelOrientation', 'horizontal', 'LabelVerticalAlignment', 'bottom');
    xline(axd, 100, 'k-', 'Continuous', 'HandleVisibility', 'off', 'LabelOrientation', 'horizontal', 'LabelVerticalAlignment', 'bottom', ...
        'LabelHorizontalAlignment', 'left');
    xlabel(axd, 'UWB duty cycle while airborne (%)'); ylabel(axd, 'Time above short-term criterion vs allowance (dB)');
    title(axd, "If drones can transmit: duty cycle up to continuous, " + st.name);
    subtitle(axd, sprintf('Measured device EIRP, every drone carrying UWB, average local density (%.2g per km^2)', rho));
    xlim(axd, [0.1 100]);
    legend(axd, 'Location', 'northwest');
    exportgraphics(figd, fullfile(out_dir, "fig_duty_sweep_" + st.tag + ".png"), 'Resolution', 200);

    summary(end+1, :) = {st.name, bdA.beamwidth_deg, ing.margin_bore_dB, median(bdA.dwell_s(low), 'omitnan'), ...
        max(bdA.dwell_s(low)), 100 * bdA.hover_frac_trk, 1000 * rg.mean_chord_km, A(2) * 1e6, rho, ...
        cbT.rho_allow_per_km2, br.ratio_dB(br.step == "B"), br.ratio_dB(br.step == "D1"), br.ratio_dB(br.step == "D2"), ...
        median(bdM.dwell_s(low), 'omitnan'), cont(1), cont(3), be_pct(3), be_pct(6)}; %#ok<SAGROW> two stations
end

sum_tbl = cell2table(summary, 'VariableNames', {'station', 'beamwidth_deg', 'margin_bore_max_dB', 'dwell_median_s', ...
    'dwell_max_s', 'hover_pct_trk', 'mean_chord_m', 'footprint_meas_m2', 'rho_air_per_km2', 'rho_allow_per_km2', ...
    'B_ratio_dB', 'B_all_time_ratio_dB', 'B_app20_ratio_dB', 'dwell_median_meas_s', ...
    'continuous_ratio_dB', 'continuous_app20_ratio_dB', 'break_even_duty_app20_pct', 'break_even_duty_app20_peak_pct'});
disp('Summary:'); disp(sum_tbl);
writetable(sum_tbl, fullfile(out_dir, 'bridge_summary.csv'));
fprintf('Done in %.0f s. Outputs in %s\n', toc(t_start), out_dir);
diary off;

function [A, A_lo, A_hi, k_tot, r_far] = footprint_reps(p, pop, ps, F, f_mhz, r_s, n, n_calls)
%FOOTPRINT_REPS Single-drone short-term footprint from repeated independent calls, with a 95% interval.
k_tot = 0; r_far = 0; area_disk = pi * r_s^2;
for c = 1:n_calls
    fp = exceedance_footprint_rev1(p, pop, ps, F, f_mhz, 'n', n, 'r_sample_km', r_s, 'seed', p.mc.seed + 100 + c);
    k_tot = k_tot + round(fp.p1_short * fp.n);
    r_far = max(r_far, fp.r_hit_max_km);
end
N = n * n_calls;
A = area_disk * k_tot / N;
if k_tot == 0
    A_lo = 0; A_hi = area_disk * (1 - 0.025^(1 / N));
else
    A_lo = area_disk * betainv(0.025, k_tot, N - k_tot + 1);
    A_hi = area_disk * betainv(0.975, k_tot + 1, N - k_tot);
end
end
