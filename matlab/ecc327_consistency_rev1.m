function cc = ecc327_consistency_rev1(p, F, ps, f_mhz, opts)
%ECC327_CONSISTENCY_REV1 Check this model against the published conclusions of ECC Report 327.
%   cc = ECC327_CONSISTENCY_REV1(p, F, ps, f_mhz) reruns two ECC Report 327
%   (October 2021) scenarios with this model's earth station and returns a
%   table that sets each result next to ECC's published value:
%     1. Single entry: one ground UWB device at 100% duty cycle on a
%        line-of-sight path. ECC executive summary (sec. 0.5.1): mitigation
%        distances "between 300 m and 3600 m". This model: free-space loss,
%        device in the dish azimuth, single-entry pattern, dish at the
%        long-term (13 deg) and short-term (5 deg) elevations of
%        ITU-R SA.1026-5.
%     2. Aggregate fixed outdoor UWB on flat terrain without clutter. ECC:
%        100 m around EESS and MetSat earth stations. Densities from ECC
%        Report 327 Table 1 (urban 400, suburban 50, rural 10 devices per
%        km^2) times a 5% activity factor (ECC Report 327 Table 18, fixed
%        vehicle installations, as summarized by FiRa; the fixed-outdoor
%        activity factor itself wasn't available, TODO).
%   ECC's earth station parameters (sec. 5.5) could not be retrieved, so
%   this is a consistency check, not a calibration: agreement in order of
%   magnitude is the test.
%
%   The single-entry rows run twice: with the earth station at its own
%   height (the device sits below the dish, so it is always well off-axis)
%   and with the dish at the device height (horizon-level path, the likely
%   worst case in ECC's single-entry geometry). The gap between the two
%   shows how much the result depends on antenna height.
%
%   Name-value options: h_dev_m (device height, default 1.5), n_iter (2e3).
arguments
    p struct
    F
    ps struct
    f_mhz (1,1) double
    opts.h_dev_m (1,1) double = 1.5
    opts.n_iter (1,1) double = 2e3
end
crit = eess_criteria_rev1(f_mhz, p);
e10 = uwb_power_in_band_rev1(f_mhz, p.crit.ref_bw_MHz, p.uwb);
lambda = physconst('LightSpeed') / (f_mhz * 1e6);
d = [0.01:0.005:2, 2.01:0.01:20];
rows = {};
for h_es = [p.es.h_m opts.h_dev_m]
    [slant, el_d] = air_to_ground_geometry_rev1(d, h_es, opts.h_dev_m, p.prop.k_factor, p.prop.re_km);
    fsl = 20 * log10(4 * pi * slant * 1000 / lambda);
    for el_pt = [p.es.el_long_deg p.es.el_short_deg]
        g = es_gain_rev1(abs(el_d - el_pt), p.es.diam_m, f_mhz, p.es.eff, "single");
        i_dBm = e10 - p.uwb.pol_loss_dB - fsl + g;
        for c = ["long" "short"]
            lim = crit.(c + "_dBm");
            k = find(i_dBm > lim, 1, 'last');
            if isempty(k), sep = 0; else, sep = d(min(k + 1, numel(d))); end
            rows(end+1, :) = {sprintf("Single entry, 100%% duty, LOS, dish %g m high at %g deg, %s-term", h_es, el_pt, c), ...
                1000 * sep, "300-3600", "ECC Report 327 sec. 0.5.1"}; %#ok<AGROW> eight rows
        end
    end
end

dens = [400 50 10] * 0.05;
lbl = ["urban" "suburban" "rural"];
for k = 1:3
    pop = struct('name', "fixed outdoor", 'density_per_km2', dens(k), 'h_min_m', opts.h_dev_m, ...
        'h_max_m', opts.h_dev_m, 'r_max_km', 20, 'eirp_offset_dB', 0, 'extra_loss_db', 0, 'clutter', false);
    o = aggregate_drone_mc_rev4(p, pop, ps, F, f_mhz, 'n_iter', opts.n_iter, 'chunk', 500, ...
        'pct_exceed', [crit.long_pct 50], 'r_edges_km', [0:0.01:2, 2.1:0.1:19.9]);
    r_req = required_exclusion_radius_rev1(o.r_ex_km, o.pct_dBm(1, :), crit.long_dBm);
    rows(end+1, :) = {sprintf("Aggregate fixed outdoor, %s (%g active/km^2), long-term, flat, no clutter", lbl(k), dens(k)), ...
        1000 * r_req, "100", "ECC Report 327 sec. 0.5.1"}; %#ok<AGROW> three rows
end
cc = cell2table(rows, 'VariableNames', {'scenario', 'this_model_m', 'ecc327_m', 'ecc_source'});
end
