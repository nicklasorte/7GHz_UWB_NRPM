function tests = test_uwb_eess_rev1
%TEST_UWB_EESS_REV1 Unit tests for the UWB ch 9 / EESS model. Run: runtests('test_uwb_eess_rev1')
tests = functiontests(localfunctions);
end

function setupOnce(tc)
addpath(fullfile(fileparts(fileparts(mfilename('fullpath')))));
sib = fullfile(fileparts(fileparts(fileparts(fileparts(mfilename('fullpath'))))));
if isfolder(fullfile(sib, 'itu_p2108', 'src')), addpath(fullfile(sib, 'itu_p2108', 'src')); end
if isfolder(fullfile(sib, 'itu_p528', 'src')), addpath(fullfile(sib, 'itu_p528', 'src')); end
tc.TestData.p = uwb_eess_params_rev1();
end

function test_sa509_continuity(tc)
% Pattern segments must join at phi1, phi2 (both patterns) per ITU-R SA.509-3.
p = tc.TestData.p;
lambda = physconst('LightSpeed')/(8100e6);
dl = p.es.diam_m/lambda;
g0 = 10*log10(p.es.eff*(pi*dl)^2);
phi2 = 10^((49 - g0)/25);
for pat = ["single","multiple"]
    g = sa509_gain_rev1([phi2*(1-1e-9) phi2*(1+1e-9)], p.es.diam_m, 8100, p.es.eff, pat);
    verifyEqual(tc, g(1), g(2), 'AbsTol', 1e-6);
end
verifyEqual(tc, sa509_gain_rev1(0, p.es.diam_m, 8100, p.es.eff, "single"), g0, 'AbsTol', 1e-12);
verifyEqual(tc, sa509_gain_rev1(10, p.es.diam_m, 8100, p.es.eff, "single"), 32 - 25, 'AbsTol', 1e-12);
verifyEqual(tc, sa509_gain_rev1(100, p.es.diam_m, 8100, p.es.eff, "multiple"), -8, 'AbsTol', 1e-12);
end

function test_sa509_small_antenna_errors(tc)
verifyError(tc, @() sa509_gain_rev1(1, 0.5, 8100, 0.6), 'sa509_gain_rev1:smallAntenna');
end

function test_geometry_flat_limit(tc)
% At short range the 4/3 Earth geometry matches flat-Earth trigonometry.
[s, el, los] = air_to_ground_geometry_rev1(1, 10, 110);
verifyEqual(tc, s, hypot(1, 0.1), 'RelTol', 1e-4);
verifyEqual(tc, el, atand(0.1/1), 'AbsTol', 0.01);
verifyTrue(tc, los);
[~, el0] = air_to_ground_geometry_rev1(0, 10, 110);
verifyEqual(tc, el0, 90, 'AbsTol', 1e-9);
[~, ~, los_far] = air_to_ground_geometry_rev1(100, 10, 120);
verifyFalse(tc, los_far);
end

function test_fspl_matches_formula(tc)
lambda = physconst('LightSpeed')/8100e6;
verifyEqual(tc, fspl(1000, lambda), 20*log10(4*pi*1000/lambda), 'AbsTol', 1e-9);
end

function test_inband_power(tc)
% In-channel, a 10 MHz victim band collects EIRP/MHz + 10 dB.
p = tc.TestData.p;
verifyEqual(tc, uwb_power_in_band_rev1(8000, 10, p.uwb), -31.3, 'AbsTol', 1e-6);
% Fully inside the -18 dBr region.
f18 = p.uwb.fc_MHz + 0.8*p.uwb.chip_rate_MHz + 20;
verifyEqual(tc, uwb_power_in_band_rev1(f18, 10, p.uwb), -31.3 - 18, 'AbsTol', 1e-6);
end

function test_criteria(tc)
p = tc.TestData.p;
c = eess_criteria_rev1(8100, p);
verifyEqual(tc, c.long_dBm, -120, 'AbsTol', 1e-12);
verifyEqual(tc, c.short_dBm, -103, 'AbsTol', 1e-12);
verifyError(tc, @() eess_criteria_rev1(7950, p), 'eess_criteria_rev1:noBand');
end

function test_link_budget_hand_calc(tc)
% One drone at 1 km, 121.92 m, in azimuth; compare with a hand link budget.
p = tc.TestData.p;
i = uwb_to_es_interference_rev1(p, 1, p.drone.h_max_m, 0, 13, 8100, "single");
[s, el] = air_to_ground_geometry_rev1(1, p.es.h_m, p.drone.h_max_m);
g = sa509_gain_rev1(abs(13 - el), p.es.diam_m, 8100, p.es.eff, "single");
lambda = physconst('LightSpeed')/8100e6;
hand = -31.3 - 20*log10(4*pi*s*1000/lambda) + g - 3;
verifyEqual(tc, i, hand, 'AbsTol', 1e-6);
end

function test_mc_reproducible(tc)
p = tc.TestData.p;
a = aggregate_drone_mc_rev1(p, 0.05, 13, 8100, 'n_iter', 500, 'chunk', 200, 'pct_exceed', 20, 'seed', 7);
b = aggregate_drone_mc_rev1(p, 0.05, 13, 8100, 'n_iter', 500, 'chunk', 200, 'pct_exceed', 20, 'seed', 7);
verifyEqual(tc, a.agg_mW, b.agg_mW);
verifyTrue(tc, all(diff(a.agg_mW, 1, 2) <= 0, 'all'));   % larger exclusion never adds interference
verifyEqual(tc, a.drones_drawn/500, a.mean_drones, 'RelTol', 0.05);
end

function test_main_beam_distance_inverse(tc)
% Distance from main_beam_distance_rev1 must give exactly the threshold back.
f = 8160; e = -31.3; g = 57.5; lp = 3; ith = -120;
d = main_beam_distance_rev1(e, g, lp, ith, f, 5);
lambda = physconst('LightSpeed')/(f*1e6);
verifyEqual(tc, e - fspl(d*1000, lambda) + g - lp, ith, 'AbsTol', 1e-9);
[~, h] = main_beam_distance_rev1(e, g, lp, ith, f, 0);
verifyEqual(tc, h, (d*1000)^2/(2*(4/3)*6371e3), 'RelTol', 1e-12);
end

function test_pulse_metrics(tc)
p = tc.TestData.p;
m = uwb_pulse_metrics_rev1([1; 30; 375], p.uwb, [0.1 1]);
verifyEqual(tc, m.avg_dBm(1), -41.3, 'AbsTol', 1e-12);
verifyEqual(tc, m.burst_boost_dB, [20*log10(1/50)+41.3, 0], 'AbsTol', 1e-12);   % 10 dB request capped at 7.3 dB
verifyEqual(tc, m.peak_env_dBm(1), 20*log10(1/50), 'AbsTol', 1e-12);
verifyEqual(tc, m.regime(:,1), ["noise-like"; "noise-like"; "pulse-resolved"]);
verifyEqual(tc, m.par_pulse_dB(3,1), 10*log10(375/62.4), 'AbsTol', 1e-12);
end

function test_victim_tsys_from_gt(tc)
v = victim_systems_rev1();
k = find(contains(v.name, "JPSS"));
verifyEqual(tc, 10*log10(v.tsys_K(k)), v.g0_dBi(k) - 22.7, 'AbsTol', 1e-9);
end

function test_victim_rev2_nen(tc)
% NEN Users' Guide values: G/T 35.2 (AS1) and 34.5 (WG1) dB/K with 57.5 dBi.
v = victim_systems_rev2();
as1 = contains(v.name, "AS1"); wg1 = contains(v.name, "WG1");
verifyEqual(tc, 10*log10(v.tsys_K(as1)), 57.5 - 35.2, 'AbsTol', 1e-9);
verifyEqual(tc, 10*log10(v.tsys_K(wg1)), 57.5 - 34.5, 'AbsTol', 1e-9);
% SA.509-3 G0 and beamwidth for 11.3 m agree with the published 57.5 dBi and 0.2-0.23 deg.
verifyEqual(tc, v.g0_calc_dBi(as1), 57.5, 'AbsTol', 0.2);
verifyGreaterThan(tc, v.bw3db_calc_deg(as1), 0.19);
verifyLessThan(tc, v.bw3db_calc_deg(as1), 0.24);
end

function test_p2108_clutter(tc)
% Median (50% of locations) at 2 km equals Eqn 3a with Q^-1(0.5) = 0, and the 2 km cap holds.
f = 8.16;
L_l = -2*log10(10^(-5*log10(f) - 12.5) + 10^(-16.5));
L_s = 32.98 + 23.9*log10(2) + 3*log10(f);
expect = -5*log10(10^(-0.2*L_l) + 10^(-0.2*L_s));
verifyEqual(tc, p2108_terrestrial_clutter_rev1(f, 2, 50), expect, 'AbsTol', 1e-10);
verifyEqual(tc, p2108_terrestrial_clutter_rev1(f, 10, 50), expect, 'AbsTol', 1e-10);
verifyEqual(tc, p2108_terrestrial_clutter_rev1(f, 0.1, 50), 0);
verifyLessThan(tc, p2108_terrestrial_clutter_rev1(f, 2, 10), expect);   % lower loss at 10% of locations
end

function test_p528_table_matches_direct(tc)
% Interpolant reproduces direct P.528 calls at grid nodes.
tc.assumeNotEmpty(which('p528_rev1'), 'itu_p528 not on the path; filtered.');
[F, tbl] = p528_loss_table_rev1(8160, 10, 'd_km', [0.5 1 5 20], 'h_m', [30 121.92], 'p_pct', [1 50 99], ...
    'cache_dir', string(tempname));
A = p528_rev1(5, 10, 121.92, 8160, 1, 50);
verifyEqual(tc, F(log10(5), 121.92, 50), A, 'AbsTol', 1e-9);
verifyEqual(tc, size(tbl.A_db), [4 2 3]);
end

function test_mc_rev2_reproducible(tc)
% Same seed, same result; larger exclusion never adds interference. Uses a
% free-space interpolant so the test runs without itu_p528.
p = tc.TestData.p;
d = [0.02 0.1 1 10 100]; h = [1 50 300]; pp = [1 50 99];
[D, H, ~] = ndgrid(d, h, pp);
lambda = physconst('LightSpeed') / 8160e6;
L = 20*log10(4*pi*sqrt((D*1000).^2 + (H - 10).^2)/lambda);
F = griddedInterpolant({log10(d), h, pp}, L, 'linear', 'nearest');
ps.tracking = true(10, 1); ps.az_deg = (0:36:324)'; ps.el_deg = 5 + (0:9)';
pop = struct('name', "t", 'density_per_km2', 0.05, 'h_min_m', 10, 'h_max_m', 120, 'r_max_km', 30, ...
    'eirp_offset_dB', 0, 'extra_loss_db', 0, 'clutter', false);
a = aggregate_drone_mc_rev2(p, pop, ps, F, 8100, 'n_iter', 400, 'chunk', 100, 'seed', 3, 'pct_exceed', 20);
b = aggregate_drone_mc_rev2(p, pop, ps, F, 8100, 'n_iter', 400, 'chunk', 100, 'seed', 3, 'pct_exceed', 20);
verifyEqual(tc, a.pct_dBm, b.pct_dBm);
verifyTrue(tc, all(diff(a.frac_exceed_long) <= 0));
end

function test_mc_rev3_matches_rev2_statistically(tc)
% rev3 uses cheaper math and different random streams; its percentiles must
% agree with rev2 within Monte Carlo noise, and serial must equal parallel.
p = tc.TestData.p;
d = [0.02 0.1 1 10 100]; h = [1 50 300]; pp = [1 50 99];
[D, H, P] = ndgrid(d, h, pp);
lambda = physconst('LightSpeed') / 8160e6;
L = 20*log10(4*pi*sqrt((D*1000).^2 + (H - 10).^2)/lambda) + 0.05*(P - 50);
F = griddedInterpolant({log10(d), h, pp}, L, 'linear', 'nearest');
ps.tracking = true(50, 1); ps.az_deg = linspace(0, 350, 50)'; ps.el_deg = linspace(5, 40, 50)';
for clutter = [false true]
    pop = struct('name', "t", 'density_per_km2', 0.2, 'h_min_m', 10, 'h_max_m', 120, 'r_max_km', 30, ...
        'eirp_offset_dB', 0, 'extra_loss_db', 0, 'clutter', clutter);
    a = aggregate_drone_mc_rev2(p, pop, ps, F, 8100, 'n_iter', 20000, 'pct_exceed', [20 50]);
    b = aggregate_drone_mc_rev3(p, pop, ps, F, 8100, 'n_iter', 20000, 'pct_exceed', [20 50]);
    verifyEqual(tc, b.pct_dBm(:, 1), a.pct_dBm(:, 1), 'AbsTol', 0.3);
end
pool = gcp('nocreate');
if ~isempty(pool)
    s = aggregate_drone_mc_rev3(p, pop, ps, F, 8100, 'n_iter', 6000, 'chunk', 1000, 'pct_exceed', 20);
    q = aggregate_drone_mc_rev3(p, pop, ps, F, 8100, 'n_iter', 6000, 'chunk', 1000, 'pct_exceed', 20, 'parallel_flag', 1);
    verifyEqual(tc, q.pct_dBm, s.pct_dBm);
end
end

%% rev4 additions: small-antenna pattern, tail intervals, validated clutter, footprint, density

function F = fs_interp()
% Free-space interpolant so these tests run without itu_p528.
d = [0.02 0.1 1 10 100]; h = [1 50 300]; pp = [1 50 99];
[D, H, P] = ndgrid(d, h, pp);
lambda = physconst('LightSpeed') / 8160e6;
L = 20*log10(4*pi*sqrt((D*1000).^2 + (H - 10).^2)/lambda) + 0.05*(P - 50);
F = griddedInterpolant({log10(d), h, pp}, L, 'linear', 'nearest');
end

function test_f699_continuity(tc)
% ITU-R F.699-5 segments join at phi_m, 100 lambda/D, and 48 deg for a 2.4 m dish at 8160 MHz.
lambda = physconst('LightSpeed') / 8160e6; dl = 2.4 / lambda;
gmax = 10*log10(0.6*(pi*dl)^2); g1 = 2 + 15*log10(dl);
phi_m = 20/dl*sqrt(gmax - g1);
for b = [phi_m, 100/dl]
    verifyEqual(tc, f699_gain_rev1(b - 1e-9, 2.4, 8160, 0.6), f699_gain_rev1(b + 1e-9, 2.4, 8160, 0.6), 'AbsTol', 1e-3);
end
% At 48 deg the Recommendation's rounded constants leave a 0.03 dB step (52 - 25 log10 48 = 9.97 vs 10).
verifyEqual(tc, f699_gain_rev1(48 - 1e-9, 2.4, 8160, 0.6), f699_gain_rev1(48 + 1e-9, 2.4, 8160, 0.6), 'AbsTol', 0.05);
verifyEqual(tc, f699_gain_rev1(0, 2.4, 8160, 0.6), gmax, 'AbsTol', 1e-12);
verifyError(tc, @() f699_gain_rev1(1, 11.3, 8160, 0.6), 'f699_gain_rev1:largeAntenna');
end

function test_es_gain_dispatch(tc)
[g, src] = es_gain_rev1(1, 11.3, 8160, 0.6, "single");
verifyEqual(tc, g, sa509_gain_rev1(1, 11.3, 8160, 0.6, "single"));
verifySubstring(tc, src, "SA.509");
[g, src] = es_gain_rev1(1, 2.4, 8160, 0.6);
verifyEqual(tc, g, f699_gain_rev1(1, 2.4, 8160, 0.6));
verifySubstring(tc, src, "F.699");
end

function test_tail_ci_coverage(tc)
% On exponential samples the 95% order-statistic interval covers the true
% 99.9th percentile in about 95% of repeats, and Clopper-Pearson covers p.
rs = RandStream('Threefry', 'Seed', 7);
truth_db = 10*log10(-log(1e-3));
hit = 0; hitf = 0; nrep = 400;
for k = 1:nrep
    x = -log(rand(rs, 2e4, 1));
    ci = mc_tail_ci_rev1(x, 0.1, -log(1e-3), 0.95);
    hit = hit + (ci.level_db_lo <= truth_db && truth_db <= ci.level_db_hi);
    hitf = hitf + (ci.frac_lo <= 1e-3 && 1e-3 <= ci.frac_hi);
end
verifyGreaterThan(tc, hit/nrep, 0.92);
verifyGreaterThan(tc, hitf/nrep, 0.92);
end

function test_rev4_reproducible_and_clutter_port(tc)
tc.assumeNotEmpty(which('p2108_terrestrial_rev1'), 'itu_p2108 not on the path; filtered.');
p = tc.TestData.p; F = fs_interp();
ps.tracking = true(20, 1); ps.az_deg = linspace(0, 340, 20)'; ps.el_deg = linspace(5, 40, 20)';
pop = struct('name', "t", 'density_per_km2', 2, 'h_min_m', 1.5, 'h_max_m', 1.5, 'r_max_km', 5, ...
    'eirp_offset_dB', 0, 'extra_loss_db', 0, 'clutter', true);
a = aggregate_drone_mc_rev4(p, pop, ps, F, 8160, 'n_iter', 2000, 'chunk', 500, 'pct_exceed', [20 50]);
b = aggregate_drone_mc_rev4(p, pop, ps, F, 8160, 'n_iter', 2000, 'chunk', 500, 'pct_exceed', [20 50]);
verifyEqual(tc, a.pct_dBm, b.pct_dBm);
verifyTrue(tc, all(diff(a.frac_exceed_long) <= 0));
verifyLessThanOrEqual(tc, a.ci.level_db_lo(1), a.ci.level_db(1));
verifyGreaterThanOrEqual(tc, a.ci.level_db_hi(1), a.ci.level_db(1));
% device physics: clutter adds exactly the validated P.2108 loss
dev = struct('r_km', [0.1; 1; 3], 'az_rad', [0; 1; 2], 'h_m', [1.5; 1.5; 1.5], 'p_time', [50; 50; 50], 'p_loc', [10; 50; 90]);
pt = struct('el_rad', deg2rad([5; 5; 5]), 'az_rad', [0; 0; 0]);
geo = struct('ae_km', 8494.67, 'r1_km', 8494.67 + 0.01);
ant = struct('diam_m', 11.3, 'f_mhz', 8160, 'eff', 0.6, 'pattern', "multiple");
i0 = device_interference_rev1(dev, pt, geo, F, ant, -30);
i1 = device_interference_rev1(dev, pt, geo, F, ant, -30, 8.16);
expect = p2108_terrestrial_rev1(8.16, max(dev.r_km, 0.25), dev.p_loc, q_inverse="exact");
expect(dev.r_km < 0.25) = 0;                         % default short-path rule: no clutter below 0.25 km
verifyEqual(tc, 10*log10(i0 ./ i1), expect, 'AbsTol', 1e-9);
end

function test_footprint_matches_mc(tc)
% With sparse drones the short-term exceedance comes from single devices,
% so the Poisson footprint prediction matches the aggregate Monte Carlo.
p = tc.TestData.p; F = fs_interp();
ps.tracking = true(50, 1); ps.az_deg = linspace(0, 350, 50)'; ps.el_deg = linspace(5, 40, 50)';
% EIRP raised 40 dB (negative offset) so single-device exceedances are common enough to count.
pop = struct('name', "t", 'density_per_km2', 0.005, 'h_min_m', 10, 'h_max_m', 120, 'r_max_km', 20, ...
    'eirp_offset_dB', -40, 'extra_loss_db', 0, 'clutter', false);
o = aggregate_drone_mc_rev4(p, pop, ps, F, 8160, 'n_iter', 2e5, 'chunk', 2e4, 'r_edges_km', [0 1 5]);
fp = exceedance_footprint_rev1(p, pop, ps, F, 8160, 'n', 1e6);
verifyGreaterThan(tc, o.ci.frac(2), 0);
verifyEqual(tc, fp.pred_frac_short, o.ci.frac(2), 'RelTol', 0.25);
end

function test_density_chain(tc)
% Each step of the FAA/Census chain reproduces its hand calculation.
d = drone_density_faa_rev1(10000, 'peak_factor', 1, 'equipped_frac', 1, 'activity', 1);
u = d.Properties.UserData;
verifyEqual(tc, u.airborne_us_avg, 21676799/8760, 'RelTol', 1e-12);
verifyEqual(tc, u.state_ratio, (1366899/20002427)/(57836452/341784857), 'RelTol', 1e-12);
verifyEqual(tc, d.active_uwb_per_km2, 21676799/8760/341784857*u.state_ratio*10000, 'RelTol', 1e-12);
end

function test_link_budget_sums(tc)
% The interference row equals EIRP minus losses plus gain from the other rows.
p = tc.TestData.p; F = fs_interp();
lb = link_budget_walkthrough_rev1(p, F, 8160, 121.92, 1.2, 5, 0, 50);
val = @(s) lb.value(strcmp(string(lb.step), s));
i_calc = val("UWB EIRP in the reference bandwidth at f") - val("EIRP reduction toward the station") ...
    - val("Polarization mismatch") - val("ITU-R P.528-5 basic transmission loss") + val("Dish gain toward the drone");
verifyEqual(tc, val("Interference at the antenna output"), i_calc, 'AbsTol', 1e-9);
end

function test_clutter_short_path_rule(tc)
% Below 0.25 km, "zero" adds no clutter loss; "hold" adds the 0.25 km loss. Beyond 0.25 km both agree.
F = @(x, h, pt) 100 + 0 * x;                         % flat 100 dB basic loss stands in for P.528
dev = struct('r_km', [0.1; 0.2; 0.5], 'az_rad', [0; 0; 0], 'h_m', [1.5; 1.5; 1.5], ...
    'p_time', [50; 50; 50], 'p_loc', [50; 50; 50]);
pt = struct('el_rad', deg2rad([5; 5; 5]), 'az_rad', [0; 0; 0]);
geo = struct('ae_km', 8500, 'r1_km', 8500.02);
ant = struct('diam_m', 2.4, 'f_mhz', 8160, 'eff', 0.6, 'pattern', "single");
[~, ~, Lz] = device_interference_rev1(dev, pt, geo, F, ant, -30, 8.16, "zero");
[~, ~, Lh] = device_interference_rev1(dev, pt, geo, F, ant, -30, 8.16, "hold");
L25 = p2108_terrestrial_rev1(8.16, 0.25, 50, q_inverse="exact");
verifyEqual(tc, Lz(1:2), [100; 100]);
verifyEqual(tc, Lh(1:2), 100 + [L25; L25], 'AbsTol', 1e-12);
verifyEqual(tc, Lz(3), Lh(3));
verifyGreaterThan(tc, L25, 10);
end

function test_region_chord_disk(tc)
% A disk of radius 1 km: area pi, perimeter 2 pi, mean chord pi/2 (Cauchy-Crofton).
x = -1.5:0.002:1.5;
[X, Y] = meshgrid(x, x);
rg = region_chord_rev1(x, x, -hypot(X, Y), -1);
verifyEqual(tc, rg.area_km2, pi, 'RelTol', 2e-3);
verifyEqual(tc, rg.perimeter_km, 2 * pi, 'RelTol', 5e-3);
verifyEqual(tc, rg.mean_chord_km, pi / 2, 'RelTol', 5e-3);
verifyEqual(tc, rg.n_regions, 1);
end

function test_crossing_budget_hand(tc)
% 0.001 km^2 footprint, 50 m chord, dish tracks 5% of the time, 0.005% allowance, 1% duty.
cb = crossing_budget_rev1(1e-3, 0.05, 0.05, 0.005, 'duty', 0.01, 'speeds_mps', 10, 'density_per_km2', 0.1);
yr = 365.25 * 86400;
T_track = 0.05 * yr; T_allow = 5e-5 * T_track;
verifyEqual(tc, cb.T_allow_s, T_allow, 'RelTol', 1e-12);
verifyEqual(tc, cb.rho_allow_per_km2, T_allow / (0.01 * 1e-3 * T_track), 'RelTol', 1e-12);   % = 5 per km^2
verifyEqual(tc, cb.rho_allow_per_km2, 5, 'RelTol', 1e-12);
verifyEqual(tc, cb.table.dwell_s, 5, 'RelTol', 1e-12);
verifyEqual(tc, cb.ratio_to_allowance, 0.1 / 5, 'RelTol', 1e-12);
cbA = crossing_budget_rev1(1e-3, 0.05, 0.05, 0.005, 'basis', "all", 'duty', 0.01);
verifyEqual(tc, cbA.rho_allow_per_km2, 5 / 0.05, 'RelTol', 1e-12);                          % all-time basis is 1/tracking_frac looser
end

function test_bridge_steps_hand(tc)
ing = struct('margin_bore_dB', 12, 'hover_frac_trk', 1e-3, 'rho_per_km2', 0.01, 'uwb_share', 1, ...
    'area_limit_km2', 2e-3, 'area_meas_km2', 1.8e-3, 'area_app_km2', 0.2, 'duty', 0.01, ...
    'tracking_frac', 0.05, 'allowance_pct', 0.005);
br = bridge_steps_rev1(ing);
verifyEqual(tc, br.frac_above(1), 1);
verifyEqual(tc, br.frac_above(2), 1e-3);
verifyEqual(tc, br.frac_above(3), 1 - exp(-0.01 * 2e-3), 'RelTol', 1e-12);
verifyEqual(tc, br.frac_above(5), 0.01 * (1 - exp(-0.01 * 1.8e-3)), 'RelTol', 1e-12);
verifyEqual(tc, br.frac_above(7), br.frac_above(6) * 0.05, 'RelTol', 1e-12);
verifyEqual(tc, br.frac_above(8), 0.01 * (1 - exp(-0.01 * 0.2)), 'RelTol', 1e-12);      % measured from B, not from D1
verifyEqual(tc, br.ratio_dB(1), 10 * log10(1 / 5e-5), 'AbsTol', 1e-9);
verifyError(tc, @() bridge_steps_rev1(rmfield(ing, 'duty')), 'bridge_steps_rev1:missing');
end

function test_beam_dwell_synthetic(tc)
% One pass at constant angular rate 0.05 deg/s in elevation; a flat loss set so the
% boresight margin is exactly 3 dB. The exceedance cone is then the 3 dB beam, and
% the dwell must equal beamwidth / rate.
p = uwb_eess_params_rev1();
p.es.diam_m = 11.3; p.es.h_m = 10;
f = 8160;
crit = eess_criteria_rev1(f, p);
e10 = uwb_power_in_band_rev1(f, p.crit.ref_bw_MHz, p.uwb);
g0 = es_gain_rev1(0, p.es.diam_m, f, p.es.eff, "single");
L = e10 - p.uwb.pol_loss_dB + g0 - crit.short_dBm - 3;
F = @(x, h, pt) L + 0 * x;
n = 61; dt = 20;
t0 = datetime(2026, 11, 1, 'TimeZone', 'UTC');
ps = struct('t', t0 + seconds((0:n-1)' * dt), 'tracking', true(n, 1), 'az_deg', zeros(n, 1), ...
    'el_deg', 5 + 0.05 * dt * (0:n-1)', 'sat_idx', ones(n, 1));
bd = beam_dwell_rev1(p, ps, F, f);
verifyEqual(tc, bd.margin_dB(10), 3, 'AbsTol', 1e-9);
verifyEqual(tc, bd.omega_deg_s(10), 0.05, 'RelTol', 1e-6);
verifyEqual(tc, bd.dwell_s(10), bd.beamwidth_deg / 0.05, 'RelTol', 1e-3);
verifyEqual(tc, height(bd.pass), 1);
verifyEqual(tc, bd.hover_frac_trk, max(bd.dwell_s) / (n * dt), 'RelTol', 1e-12);
% 70 lambda / D rule of thumb for the 3 dB beamwidth, within 15%
verifyEqual(tc, bd.beamwidth_deg, 70 * (physconst('LightSpeed') / (f * 1e6)) / 11.3, 'RelTol', 0.15);
verifyError(tc, @() beam_dwell_rev1(p, ps, F, f, 'h_drone_m', 5), 'beam_dwell_rev1:belowDish');
end

function test_bridge_and_tornado_charts(tc)
ing = struct('margin_bore_dB', 12, 'hover_frac_trk', 1e-3, 'rho_per_km2', 0.01, 'uwb_share', 1, ...
    'area_limit_km2', 2e-3, 'area_meas_km2', 1.8e-3, 'area_app_km2', 0.2, 'duty', 0.01, ...
    'tracking_frac', 0.05, 'allowance_pct', 0.005);
fig = bridge_chart_rev1(bridge_steps_rev1(ing), "test");
verifyClass(tc, fig, 'matlab.ui.Figure'); close(fig);
[fig, tbl] = tornado_chart_rev1(["a"; "b"; "c"], [-5; -1; -20], [5; 1; 0], 0);
verifyEqual(tc, tbl.input, ["c"; "a"; "b"]);          % widest span first
close(fig);
end

function test_threshold_distance_hand(tc)
% With a free-space loss function, the boresight short-term distance must satisfy
% EIRP10 - offset - pol + G0 - FSL(d) = criterion exactly.
p = uwb_eess_params_rev1(); p.es.diam_m = 11.3; p.es.h_m = 10;
f = 8160; lam = physconst('LightSpeed') / (f * 1e6);
F = @(x, h, pt) 20 * log10(4 * pi * (10.^x) * 1000 / lam);
td = threshold_distance_rev1(p, F, f, 'phi_deg', [0 10], 'eirp_offset_dB', 0.54, 'tracking_frac', 0.1);
crit = eess_criteria_rev1(f, p);
g0 = es_gain_rev1(0, 11.3, f, p.es.eff, "single");
Lreq = uwb_power_in_band_rev1(f, p.crit.ref_bw_MHz, p.uwb) - 0.54 - p.uwb.pol_loss_dB + g0 - crit.short_dBm;
d_exp = 10^(Lreq / 20) * lam / (4 * pi) / 1000;
verifyEqual(tc, td.d_short_km(1), d_exp, 'RelTol', 2e-3);
verifyEqual(tc, td.d_long_km(1) / td.d_short_km(1), 10^(17 / 20), 'RelTol', 2e-3);   % criteria 17 dB apart
verifyEqual(tc, td.region(1), "main beam"); verifyEqual(tc, td.region(2), "sidelobe");
verifyEqual(tc, td.hours_to_allowance.hours_tracking_basis(3), 5e-5 * 0.1 * 365.25 * 86400 / 0.01 / 3600, 'RelTol', 1e-12);
verifyEqual(tc, td.long_reachable_by_one_drone', [false false false false true]);   % 20% criterion: only continuous
td2 = threshold_distance_rev1(p, F, f, 'phi_deg', [NaN 0]);                      % NaN = the 3 dB edge
verifyEqual(tc, td2.phi_deg(2), td2.half_beamwidth_deg);
verifyEqual(tc, td2.gain_dBi(1) - td2.gain_dBi(2), 3, 'AbsTol', 0.05);
verifyError(tc, @() threshold_distance_rev1(p, F, f, 'phi_deg', -1), 'threshold_distance_rev1:phi');
end
