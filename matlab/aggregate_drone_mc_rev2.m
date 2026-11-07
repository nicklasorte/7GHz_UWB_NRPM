function out = aggregate_drone_mc_rev2(p, pop, ps, F, f_mhz, opts)
%AGGREGATE_DRONE_MC_REV2 Monte Carlo aggregate UWB interference with P.528 loss and real dish pointing.
%   out = AGGREGATE_DRONE_MC_REV2(p, pop, ps, F, f_mhz) extends
%   AGGREGATE_DRONE_MC_REV1 in three ways:
%     1. Basic transmission loss from ITU-R P.528-5 (interpolant F from
%        P528_LOSS_TABLE_REV1), with the time percentage drawn uniformly on
%        [1, 99] independently for each device and iteration. Paths beyond
%        the radio horizon are no longer dropped.
%     2. Dish pointing drawn from a pass-statistics time series ps
%        (PASS_STATISTICS_REV1): each iteration takes the azimuth and
%        elevation of a random instant when the dish is tracking.
%     3. A device population struct, so drones and ground UWB (handheld,
%        indoor) run through the same model.
%
%   pop fields:
%     name, density_per_km2 (ACTIVE devices: density x activity), h_min_m,
%     h_max_m, r_max_km, eirp_offset_dB (reduction, e.g. downward antenna
%     or a lower limit), extra_loss_db (fixed, e.g. building entry),
%     clutter (true applies ITU-R P.2108-1 sec. 3.2 at the device end with
%     a random location percentage).
%
%   out fields as AGGREGATE_DRONE_MC_REV1, plus frac_exceed_long and
%   frac_exceed_short (share of tracking time above each criterion, per
%   exclusion radius).
arguments
    p struct
    pop struct
    ps struct
    F
    f_mhz (1,1) double
    opts.n_iter (1,1) double {mustBeInteger, mustBePositive} = 2e4
    opts.chunk (1,1) double {mustBeInteger, mustBePositive} = 2000
    opts.seed (1,1) double {mustBeInteger, mustBeNonnegative} = p.mc.seed
    opts.pct_exceed (1,:) double = [20 0.005]
    opts.r_edges_km (1,:) double = p.mc.r_edges_km
end
crit = eess_criteria_rev1(f_mhz, p);
r_max_km = pop.r_max_km;
edges = opts.r_edges_km(opts.r_edges_km < r_max_km);
edges = [edges, r_max_km];
n_r = numel(edges) - 1;
lambda_dev = pop.density_per_km2 * pi * r_max_km^2;

eirp_ref_dBm = uwb_power_in_band_rev1(f_mhz, p.crit.ref_bw_MHz, p.uwb);
const_dB = eirp_ref_dBm - pop.eirp_offset_dB - p.uwb.pol_loss_dB - p.es.site_shield_dB - pop.extra_loss_db;
trk = find(ps.tracking);
if isempty(trk)
    error('aggregate_drone_mc_rev2:noTracking', 'Pass statistics contain no tracking samples.');
end

rs = RandStream('mrg32k3a', 'Seed', opts.seed);
agg = zeros(opts.n_iter, n_r);
for c0 = 1:opts.chunk:opts.n_iter
    idx = c0:min(c0 + opts.chunk - 1, opts.n_iter);
    n_c = numel(idx);
    n_dev = poissinv(rand(rs, n_c, 1), lambda_dev);
    pick = trk(randi(rs, numel(trk), n_c, 1));
    az_point = ps.az_deg(pick);
    el_point = ps.el_deg(pick);
    tot = sum(n_dev);
    if tot == 0, continue, end
    it = repelem((1:n_c)', n_dev);
    r = r_max_km * sqrt(rand(rs, tot, 1));
    az = 360 * rand(rs, tot, 1);
    h = pop.h_min_m + (pop.h_max_m - pop.h_min_m) * rand(rs, tot, 1);
    p_time = 1 + 98 * rand(rs, tot, 1);
    if pop.clutter
        p_loc = 0.5 + 99 * rand(rs, tot, 1);
    end

    [~, el_deg] = air_to_ground_geometry_rev1(r, p.es.h_m, h, p.prop.k_factor, p.prop.re_km);
    cos_phi = sind(el_deg) .* sind(el_point(it)) + cosd(el_deg) .* cosd(el_point(it)) .* cosd(az - az_point(it));
    phi = acosd(min(max(cos_phi, -1), 1));
    g = sa509_gain_rev1(phi, p.es.diam_m, f_mhz, p.es.eff, "multiple");
    L = F(log10(max(r, 0.02)), h, p_time);
    if pop.clutter
        L = L + p2108_terrestrial_clutter_rev1(f_mhz / 1000, r, p_loc);
    end
    i_mW = 10.^((const_dB - L + g) / 10);

    bin = discretize(r, edges);
    acc = accumarray([it, bin], i_mW, [n_c, n_r]);
    agg(idx, :) = fliplr(cumsum(fliplr(acc), 2));
end

out.r_ex_km = edges(1:n_r);
out.pct_exceed = opts.pct_exceed;
out.pct_dBm = 10 * log10(prctile(agg, 100 - opts.pct_exceed, 1));
crit_mW = 10.^([crit.long_dBm crit.short_dBm] / 10);
out.frac_exceed_long = mean(agg > crit_mW(1), 1);
out.frac_exceed_short = mean(agg > crit_mW(2), 1);
out.crit = crit;
out.mean_devices = lambda_dev;
out.pop = pop;
out.n_iter = opts.n_iter;
out.seed = opts.seed;
if opts.n_iter * min(opts.pct_exceed) / 100 < 1
    warning('aggregate_drone_mc_rev2:tail', 'n_iter too small to resolve the %.4g%% tail.', min(opts.pct_exceed));
end
end
