function out = aggregate_drone_mc_rev4(p, pop, ps, F, f_mhz, opts)
%AGGREGATE_DRONE_MC_REV4 Aggregate UWB interference Monte Carlo with validated clutter and tail confidence intervals.
%   out = AGGREGATE_DRONE_MC_REV4(p, pop, ps, F, f_mhz, ...) keeps the model
%   of AGGREGATE_DRONE_MC_REV3 and changes four things:
%     1. Clutter (ground populations only, pop.clutter = true) comes from
%        the validated ITU-R P.2108 port, github.com/nicklasorte/itu_p2108.
%        rev3's own formula capped the distance at 2 km; the Recommendation
%        and the NTIA reference take min(L(2 km), L(d)), which differs by up
%        to about 1 dB at high location percentages. Airborne drones get no
%        clutter loss: at 10-122 m they fly above most clutter.
%     2. The earth station pattern follows antenna size (ES_GAIN_REV1):
%        ITU-R SA.509-3 for D/lambda >= 100, ITU-R F.699-5 below that.
%     3. 95% confidence intervals on the percentile levels and on the
%        fractions of time above each criterion (MC_TAIL_CI_REV1), at zero
%        exclusion radius.
%     4. The per-device physics lives in DEVICE_INTERFERENCE_REV1, shared
%        with EXCEEDANCE_FOOTPRINT_REV1 (the Poisson cross-check).
%
%   Inputs:
%     p      UWB_EESS_PARAMS_REV1 struct; p.es.diam_m, p.es.eff, p.es.h_m used
%     pop    struct: name, density_per_km2 (active devices), h_min_m, h_max_m,
%            r_max_km, eirp_offset_dB, extra_loss_db, clutter (logical)
%     ps     pass statistics (PASS_STATISTICS_REV1): tracking, az_deg, el_deg
%     F      P.528 loss interpolant (P528_LOSS_TABLE_REV1) for this station height
%     f_mhz  victim frequency (sets criteria and in-band UWB power)
%
%   Name-value options: n_iter, chunk, seed, pct_exceed, r_edges_km,
%   parallel_flag (as rev3), pattern ("multiple" default), ci_level (0.95),
%   p2108_src (path to itu_p2108/src; default sibling clone).
%
%   Fields added to the rev3 output: ci (MC_TAIL_CI_REV1 at r = 0),
%   pattern_src, and agg_r0_mW (kept for time-basis CCDFs).
arguments
    p struct
    pop struct
    ps struct
    F
    f_mhz (1,1) double
    opts.n_iter (1,1) double {mustBeInteger, mustBePositive} = 2e4
    opts.chunk (1,1) double {mustBeInteger, mustBePositive} = 5000
    opts.seed (1,1) double {mustBeInteger, mustBeNonnegative} = p.mc.seed
    opts.pct_exceed (1,:) double = [20 0.005]
    opts.r_edges_km (1,:) double = p.mc.r_edges_km
    opts.parallel_flag (1,1) double {mustBeMember(opts.parallel_flag, [0 1])} = 0
    opts.pattern (1,1) string {mustBeMember(opts.pattern, ["single", "multiple"])} = "multiple"
    opts.ci_level (1,1) double = 0.95
    opts.p2108_src (1,1) string = string(fullfile(fileparts(mfilename('fullpath')), '..', '..', 'itu_p2108', 'src'))
end
if pop.clutter && isempty(which('p2108_terrestrial_rev1'))
    if ~isfolder(opts.p2108_src)
        error('aggregate_drone_mc_rev4:noP2108', ...
            'p2108_terrestrial_rev1 not on the path and %s not found. Clone github.com/nicklasorte/itu_p2108 next to this repo.', opts.p2108_src);
    end
    addpath(opts.p2108_src);
end
crit = eess_criteria_rev1(f_mhz, p);
if numel(opts.pct_exceed) ~= 2
    error('aggregate_drone_mc_rev4:pct', 'pct_exceed must be [long_pct short_pct].');
end
r_max_km = pop.r_max_km;
edges = opts.r_edges_km(opts.r_edges_km < r_max_km);
edges = [edges, r_max_km];
n_r = numel(edges) - 1;
lambda_dev = pop.density_per_km2 * pi * r_max_km^2;

eirp_ref_dBm = uwb_power_in_band_rev1(f_mhz, p.crit.ref_bw_MHz, p.uwb);
const_dB = eirp_ref_dBm - pop.eirp_offset_dB - p.uwb.pol_loss_dB - p.es.site_shield_dB - pop.extra_loss_db;
trk = find(ps.tracking);
if isempty(trk)
    error('aggregate_drone_mc_rev4:noTracking', 'Pass statistics contain no tracking samples.');
end
az_trk = deg2rad(ps.az_deg(trk));
el_trk = deg2rad(ps.el_deg(trk));

ant = struct('diam_m', p.es.diam_m, 'f_mhz', f_mhz, 'eff', p.es.eff, 'pattern', opts.pattern);
[~, pattern_src] = es_gain_rev1(0, ant.diam_m, ant.f_mhz, ant.eff, ant.pattern);
geo.ae_km = p.prop.k_factor * p.prop.re_km;
geo.r1_km = geo.ae_km + p.es.h_m / 1000;
f_clut = NaN;
if pop.clutter, f_clut = f_mhz / 1000; end

n_chunks = ceil(opts.n_iter / opts.chunk);
chunk_agg = cell(n_chunks, 1);
seed = opts.seed; chunk = opts.chunk; n_iter = opts.n_iter;
args = {lambda_dev, r_max_km, pop, az_trk, el_trk, geo, F, ant, const_dB, f_clut, edges, n_r};
if opts.parallel_flag == 1
    parfor c = 1:n_chunks
        n_c = min(chunk, n_iter - (c - 1) * chunk);
        chunk_agg{c} = run_chunk(seed, c, n_c, args{:}); %#ok<PFBNS> read-only inputs, broadcast once
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
out.agg_r0_mW = agg(:, 1);
out.ci = mc_tail_ci_rev1(agg(:, 1), opts.pct_exceed, crit_mW, opts.ci_level);
out.crit = crit;
out.mean_devices = lambda_dev;
out.pop = pop;
out.n_iter = opts.n_iter;
out.seed = opts.seed;
out.pattern_src = pattern_src;
out.f_mhz = f_mhz;
if opts.n_iter * min(opts.pct_exceed) / 100 < 1
    warning('aggregate_drone_mc_rev4:tail', 'n_iter too small to resolve the %.4g%% tail.', min(opts.pct_exceed));
end
end

function agg = run_chunk(seed, c, n_c, lambda_dev, r_max_km, pop, az_trk, el_trk, geo, F, ant, const_dB, f_clut, edges, n_r)
rs = RandStream('Threefry', 'Seed', seed);          % counter-based; one substream per chunk, so serial == parallel
rs.Substream = c;
n_dev = poissinv(rand(rs, n_c, 1), lambda_dev);
pick = randi(rs, numel(az_trk), n_c, 1);
agg = zeros(n_c, n_r);
tot = sum(n_dev);
if tot == 0, return, end
it = repelem((1:n_c)', n_dev);
dev.r_km = r_max_km * sqrt(rand(rs, tot, 1));        % uniform over the disk
dev.az_rad = 2 * pi * rand(rs, tot, 1);
dev.h_m = pop.h_min_m + (pop.h_max_m - pop.h_min_m) * rand(rs, tot, 1);
dev.p_time = 1 + 98 * rand(rs, tot, 1);
if isfinite(f_clut)
    dev.p_loc = 100 * rand(rs, tot, 1);              % open interval (0, 100): rand never returns 0 or 1
else
    dev.p_loc = [];
end
pt.el_rad = el_trk(pick(it));
pt.az_rad = az_trk(pick(it));
i_mW = device_interference_rev1(dev, pt, geo, F, ant, const_dB, f_clut);
bin = discretize(dev.r_km, edges);
acc = accumarray([it, bin], i_mW, [n_c, n_r]);
agg = fliplr(cumsum(fliplr(acc), 2));               % column k: devices outside edges(k)
end
