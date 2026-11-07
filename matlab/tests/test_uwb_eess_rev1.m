function tests = test_uwb_eess_rev1
%TEST_UWB_EESS_REV1 Unit tests for the UWB ch 9 / EESS model. Run: runtests('test_uwb_eess_rev1')
tests = functiontests(localfunctions);
end

function setupOnce(tc)
addpath(fullfile(fileparts(fileparts(mfilename('fullpath')))));
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

function test_gain_lookup_error(tc)
% The 0.001 deg gain table reproduces sa509_gain_rev1 to within 0.01 dB.
p = tc.TestData.p;
dphi = 1e-3; grid = 0:dphi:180;
g = sa509_gain_rev1(grid, p.es.diam_m, 8160, p.es.eff, "multiple");
phi = [linspace(0, 1, 5000) 180*rand(1, 5000, 'like', 1)];
x = phi / dphi; i0 = min(floor(x), numel(grid) - 2); w = x - i0;
gi = g(i0 + 1) .* (1 - w) + g(i0 + 2) .* w;
ge = sa509_gain_rev1(phi, p.es.diam_m, 8160, p.es.eff, "multiple");
verifyLessThan(tc, max(abs(gi - ge)), 0.01);
end
