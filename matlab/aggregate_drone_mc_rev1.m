function out = aggregate_drone_mc_rev1(p, density_per_km2, el_point_deg, f_MHz, opts)
%AGGREGATE_DRONE_MC_REV1 Monte Carlo aggregate UWB drone interference vs. exclusion radius.
%   out = AGGREGATE_DRONE_MC_REV1(p, density_per_km2, el_point_deg, f_MHz)
%   For each iteration it draws a Poisson number of active UWB drones,
%   uniform in area out to the radio horizon, uniform in altitude over
%   [p.drone.h_min_m, p.drone.h_max_m], and a uniform ES pointing azimuth at
%   elevation el_point_deg. It sums interference (ITU-R SA.509-3 multiple-entry
%   pattern) for every candidate exclusion radius r: only drones with ground
%   distance >= r contribute.
%
%   density_per_km2 is the ACTIVE density (drone density x UWB activity):
%   Poisson thinning by an activity factor a gives Poisson(a*rho*A).
%
%   out.r_ex_km(1,n_r)        candidate exclusion radii
%   out.agg_mW(n_iter,n_r)    aggregate interference per iteration
%   out.pct_dBm(n_pct,n_r)    aggregate exceeded opts.pct_exceed percent of iterations
%
%   Random draws use one RandStream('mrg32k3a') seeded by opts.seed, so the
%   same seed reproduces the same drones for every density run with the same
%   expected count.
arguments
    p struct
    density_per_km2 (1,1) double {mustBeNonnegative}
    el_point_deg (1,1) double
    f_MHz (1,1) double {mustBePositive}
    opts.n_iter (1,1) double {mustBeInteger, mustBePositive} = p.mc.n_iter
    opts.chunk (1,1) double {mustBeInteger, mustBePositive} = p.mc.chunk
    opts.seed (1,1) double {mustBeInteger, mustBeNonnegative} = p.mc.seed
    opts.pct_exceed (1,:) double = [20 0.005]
    opts.pattern (1,1) string = "multiple"
    opts.r_max_km (1,1) double {mustBePositive} = Inf   % truncate the deployment disk (default: radio horizon)
end

ae = p.prop.k_factor*p.prop.re_km;
r_hor_km = sqrt(2*ae*p.es.h_m/1000) + sqrt(2*ae*p.drone.h_max_m/1000);   % radio horizon to the highest drone
r_max_km = min(opts.r_max_km, r_hor_km);
edges = p.mc.r_edges_km(p.mc.r_edges_km < r_max_km);
edges = [edges, r_max_km];
n_r = numel(edges) - 1;
lambda_drones = density_per_km2*pi*r_max_km^2;

eirp_ref_dBm = uwb_power_in_band_rev1(f_MHz, p.crit.ref_bw_MHz, p.uwb);
lambda_m = physconst('LightSpeed')/(f_MHz*1e6);
const_dB = eirp_ref_dBm - p.uwb.pol_loss_dB - p.es.site_shield_dB;

rs = RandStream('mrg32k3a', 'Seed', opts.seed);
agg = zeros(opts.n_iter, n_r);
n_drones_total = 0;
for c0 = 1:opts.chunk:opts.n_iter
    idx = c0:min(c0 + opts.chunk - 1, opts.n_iter);
    n_c = numel(idx);
    n_dr = poissinv(rand(rs, n_c, 1), lambda_drones);   % poissrnd has no RandStream input
    az_point = 360*rand(rs, n_c, 1);
    tot = sum(n_dr);
    n_drones_total = n_drones_total + tot;
    if tot == 0
        continue
    end
    it = repelem((1:n_c)', n_dr);
    r = r_max_km*sqrt(rand(rs, tot, 1));
    az = 360*rand(rs, tot, 1);
    h = p.drone.h_min_m + (p.drone.h_max_m - p.drone.h_min_m)*rand(rs, tot, 1);

    [slant_km, el_deg, los] = air_to_ground_geometry_rev1(r, p.es.h_m, h, p.prop.k_factor, p.prop.re_km);
    daz = az - az_point(it);
    cos_phi = sind(el_deg)*sind(el_point_deg) + cosd(el_deg)*cosd(el_point_deg).*cosd(daz);
    phi = acosd(min(max(cos_phi, -1), 1));
    g = sa509_gain_rev1(phi, p.es.diam_m, f_MHz, p.es.eff, opts.pattern);
    loss = fspl(max(slant_km*1000, lambda_m), lambda_m);
    i_mW = 10.^((const_dB - loss + g)/10);
    i_mW(~los) = 0;

    bin = discretize(r, edges);
    acc = accumarray([it, bin], i_mW, [n_c, n_r]);
    agg(idx, :) = fliplr(cumsum(fliplr(acc), 2));   % column k: drones with r >= edges(k)
end

out.r_ex_km = edges(1:n_r);
out.r_max_km = r_max_km;
out.r_horizon_km = r_hor_km;
out.agg_mW = agg;
out.pct_exceed = opts.pct_exceed;
out.pct_dBm = 10*log10(prctile(agg, 100 - opts.pct_exceed, 1));
out.mean_drones = lambda_drones;
out.drones_drawn = n_drones_total;
out.density_per_km2 = density_per_km2;
out.el_point_deg = el_point_deg;
out.f_MHz = f_MHz;
out.seed = opts.seed;
tail_n = opts.n_iter*min(opts.pct_exceed)/100;
if tail_n < 1
    warning('aggregate_drone_mc_rev1:tail', ...
        'n_iter = %d resolves only %.2f samples beyond the %.4g%% point; result is the sample maximum.', ...
        opts.n_iter, tail_n, min(opts.pct_exceed));
end
end
