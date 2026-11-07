function out = aggregate_drone_mc_rev3(p, pop, ps, F, f_mhz, opts)
%AGGREGATE_DRONE_MC_REV3 Faster AGGREGATE_DRONE_MC_REV2: same model, cheaper per-device math, optional parfor.
%   out = AGGREGATE_DRONE_MC_REV3(p, pop, ps, F, f_mhz, ...) takes the same
%   inputs and returns the same fields as AGGREGATE_DRONE_MC_REV2. The model
%   is unchanged; rev2 was already vectorized, and profiling showed its time
%   goes to per-device transcendental functions. rev3 cuts that cost:
%     1. Elevation sine and cosine come straight from the 4/3-Earth geometry
%        (no atan2d, sind, cosd round trip).
%     2. Antenna gain uses the exact ITU-R SA.509-3 function. (A 0.001 deg
%        lookup table was tried and rejected: linear interpolation across the
%        pattern's step discontinuities can err by up to 5 dB in a grid cell.)
%     3. P.2108 location variability uses Q^-1(U) = Z, a standard normal
%        draw, which is exactly the distribution of Q^-1(p_loc/100) for
%        uniform p_loc, instead of erfcinv per device.
%     4. dB to mW uses exp(x ln10/10).
%     5. Threefry generator (counter-based), measured about 2x faster than
%        mrg32k3a for randn on R2025b.
%     6. parallel_flag = 1 runs chunks in parfor. Each chunk draws from its
%        own RandStream substream, so serial and parallel results are equal.
%   Profiling (R2025b, indoor population) put rev2's time in per-device
%   math, random draws, and the P.528 interpolation, not in loops: rev2 was
%   already vectorized, so rev3 is about 1.5x faster, not orders faster.
%   Random streams differ from rev2, so results match rev2 statistically,
%   not draw for draw.
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
    opts.parallel_flag (1,1) double {mustBeMember(opts.parallel_flag, [0 1])} = 0
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
    error('aggregate_drone_mc_rev3:noTracking', 'Pass statistics contain no tracking samples.');
end
az_trk = deg2rad(ps.az_deg(trk));
el_trk = deg2rad(ps.el_deg(trk));

ant = [p.es.diam_m, f_mhz, p.es.eff];

% P.2108 terrestrial clutter pieces that don't depend on distance
if pop.clutter
    f_ghz = f_mhz / 1000;
    L_l = -2 * log10(10^(-5 * log10(f_ghz) - 12.5) + 10^(-16.5));
    w_l = 10^(-0.2 * L_l);
end

ae = p.prop.k_factor * p.prop.re_km;
r1 = ae + p.es.h_m / 1000;
k_db = log(10) / 10;

n_chunks = ceil(opts.n_iter / opts.chunk);
chunk_agg = cell(n_chunks, 1);
seed = opts.seed;
chunk = opts.chunk;
n_iter = opts.n_iter;
args = {lambda_dev, r_max_km, pop, az_trk, el_trk, ae, r1, F, ant, const_dB, k_db, edges, n_r};
if pop.clutter
    args = [args, {w_l, f_ghz}];
else
    args = [args, {NaN, NaN}];
end
if opts.parallel_flag == 1
    parfor c = 1:n_chunks
        n_c = min(chunk, n_iter - (c - 1) * chunk);
        chunk_agg{c} = run_chunk(seed, c, n_c, args{:}); %#ok<PFBNS> inputs are read-only, broadcast once
    end
else
    for c = 1:n_chunks
        n_c = min(chunk, n_iter - (c - 1) * chunk);
        chunk_agg{c} = run_chunk(seed, c, n_c, args{:});
    end
end
agg = vertcat(chunk_agg{:});

out.r_ex_km = edges(1:n_r);
out.pct_exceed = opts.pct_exceed;
out.pct_dBm = 10 * log10(prctile(agg, 100 - opts.pct_exceed, 1));
crit_mW = 10.^([crit.long_dBm crit.short_dBm] / 10);
out.frac_exceed_long = mean(agg > crit_mW(1), 1);
out.frac_exceed_short = mean(agg > crit_mW(2), 1);
out.agg_r0_mW = agg(:, 1);                          % kept so EIRP-offset cases can be derived exactly
out.crit = crit;
out.mean_devices = lambda_dev;
out.pop = pop;
out.n_iter = opts.n_iter;
out.seed = opts.seed;
if opts.n_iter * min(opts.pct_exceed) / 100 < 1
    warning('aggregate_drone_mc_rev3:tail', 'n_iter too small to resolve the %.4g%% tail.', min(opts.pct_exceed));
end
end

function agg = run_chunk(seed, c, n_c, lambda_dev, r_max_km, pop, az_trk, el_trk, ae, r1, F, ant, const_dB, k_db, edges, n_r, w_l, f_ghz)
rs = RandStream('Threefry', 'Seed', seed);         % counter-based; faster randn than mrg32k3a, supports substreams
rs.Substream = c;                                    % one substream per chunk: serial == parallel
n_dev = poissinv(rand(rs, n_c, 1), lambda_dev);      % poissrnd has no RandStream input
pick = randi(rs, numel(az_trk), n_c, 1);
agg = zeros(n_c, n_r);
tot = sum(n_dev);
if tot == 0, return, end
it = repelem((1:n_c)', n_dev);
r = r_max_km * sqrt(rand(rs, tot, 1));
az = 2 * pi * rand(rs, tot, 1);
h = pop.h_min_m + (pop.h_max_m - pop.h_min_m) * rand(rs, tot, 1);
p_time = 1 + 98 * rand(rs, tot, 1);

% Elevation from the earth station, 4/3 Earth (same geometry as air_to_ground_geometry_rev1)
theta = r / ae;
r2 = ae + h / 1000;
s2 = sin(theta / 2).^2;
num = (r2 - r1) - 2 * r2 .* s2;
den = r2 .* sin(theta);
hyp = sqrt(num.^2 + den.^2);
sin_el = num ./ hyp;
cos_el = den ./ hyp;

el_p = el_trk(pick); az_p = az_trk(pick);
cos_phi = sin_el .* sin(el_p(it)) + cos_el .* cos(el_p(it)) .* cos(az - az_p(it));
phi = acosd(min(max(cos_phi, -1), 1));

g = sa509_gain_rev1(phi, ant(1), ant(2), ant(3), "multiple");

L = F(log10(max(r, 0.02)), h, p_time);
if pop.clutter
    d_eff = min(max(r, 0.25), 2);
    L_s = 32.98 + 23.9 * log10(d_eff) + 3 * log10(f_ghz);
    w_s = 10.^(-0.2 * L_s);
    sigma_cb = sqrt((16 * w_l + 36 * w_s) ./ (w_l + w_s));   % sigma_l = 4, sigma_s = 6 dB
    z = randn(rs, tot, 1);                                    % Q^-1(p_loc/100), p_loc uniform
    L_ctt = -5 * log10(w_l + w_s) - sigma_cb .* z;
    L_ctt(r < 0.25) = 0;
    L = L + L_ctt;
end
i_mW = exp((const_dB - L + g) * k_db);
bin = discretize(r, edges);
acc = accumarray([it, bin], i_mW, [n_c, n_r]);
agg = fliplr(cumsum(fliplr(acc), 2));
end
