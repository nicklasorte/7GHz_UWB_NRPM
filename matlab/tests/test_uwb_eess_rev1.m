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
