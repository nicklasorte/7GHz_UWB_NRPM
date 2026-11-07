function fp = exceedance_footprint_rev1(p, pop, ps, F, f_mhz, opts)
%EXCEEDANCE_FOOTPRINT_REV1 Area where one device alone exceeds a criterion, and the Poisson check it gives.
%   fp = EXCEEDANCE_FOOTPRINT_REV1(p, pop, ps, F, f_mhz) places n single
%   devices uniformly over the disk of radius pop.r_max_km, with random
%   height, P.528 time percentage, and dish pointing drawn from the tracking
%   samples in ps, exactly as the aggregate Monte Carlo does. It returns:
%     fp.p1_short, fp.p1_long   probability that one random device alone
%                               exceeds the short- or long-term criterion
%     fp.area_short_km2         equivalent exceedance area, pi r_max^2 p1_short:
%                               the area that must be free of drones while
%                               the dish tracks
%     fp.pred_frac_short        1 - exp(-density * area_short), the fraction
%                               of tracking time with at least one device in
%                               the footprint (Poisson)
%     fp.p1_short_ci            95% Clopper-Pearson interval on p1_short
%
%   The short-term criterion is usually broken by one device near the main
%   beam, not by many weak ones, so pred_frac_short should match the
%   aggregate Monte Carlo fraction within its confidence interval. A
%   mismatch flags an aggregation error or a short-term level that is set
%   by many devices. The check uses an analytical step (Poisson thinning)
%   that the aggregate code does not, so it is a partial independent check.
%
%   Name-value options: n (default 2e6), seed, pattern ("multiple").
arguments
    p struct
    pop struct
    ps struct
    F
    f_mhz (1,1) double
    opts.n (1,1) double {mustBeInteger, mustBePositive} = 2e6
    opts.seed (1,1) double = p.mc.seed + 1
    opts.pattern (1,1) string = "multiple"
end
crit = eess_criteria_rev1(f_mhz, p);
eirp_ref_dBm = uwb_power_in_band_rev1(f_mhz, p.crit.ref_bw_MHz, p.uwb);
const_dB = eirp_ref_dBm - pop.eirp_offset_dB - p.uwb.pol_loss_dB - p.es.site_shield_dB - pop.extra_loss_db;
trk = find(ps.tracking);
az_trk = deg2rad(ps.az_deg(trk));
el_trk = deg2rad(ps.el_deg(trk));
ant = struct('diam_m', p.es.diam_m, 'f_mhz', f_mhz, 'eff', p.es.eff, 'pattern', opts.pattern);
geo.ae_km = p.prop.k_factor * p.prop.re_km;
geo.r1_km = geo.ae_km + p.es.h_m / 1000;
f_clut = NaN;
if pop.clutter, f_clut = f_mhz / 1000; end

rs = RandStream('Threefry', 'Seed', opts.seed);
n = opts.n;
dev.r_km = pop.r_max_km * sqrt(rand(rs, n, 1));
dev.az_rad = 2 * pi * rand(rs, n, 1);
dev.h_m = pop.h_min_m + (pop.h_max_m - pop.h_min_m) * rand(rs, n, 1);
dev.p_time = 1 + 98 * rand(rs, n, 1);
dev.p_loc = 100 * rand(rs, n, 1);
pick = randi(rs, numel(trk), n, 1);
pt.el_rad = el_trk(pick);
pt.az_rad = az_trk(pick);
i_dBm = 10 * log10(device_interference_rev1(dev, pt, geo, F, ant, const_dB, f_clut));

k_s = nnz(i_dBm > crit.short_dBm);
k_l = nnz(i_dBm > crit.long_dBm);
fp.n = n;
fp.p1_short = k_s / n;
fp.p1_long = k_l / n;
fp.p1_short_ci = clopper(k_s, n);
fp.area_disk_km2 = pi * pop.r_max_km^2;
fp.area_short_km2 = fp.area_disk_km2 * fp.p1_short;
fp.area_long_km2 = fp.area_disk_km2 * fp.p1_long;
fp.area_short_ci_km2 = fp.area_disk_km2 * fp.p1_short_ci;
fp.pred_frac_short = 1 - exp(-pop.density_per_km2 * fp.area_short_km2);
fp.pred_frac_short_ci = 1 - exp(-pop.density_per_km2 * fp.area_short_ci_km2);
hit = i_dBm > crit.short_dBm;
fp.r_km_of_hits = dev.r_km(hit);                     % where single-device exceedances happen
fp.crit = crit;
end

function ci = clopper(k, n)
ci = [0 1];
if k > 0, ci(1) = betainv(0.025, k, n - k + 1); end
if k < n, ci(2) = betainv(0.975, k + 1, n - k); end
end
