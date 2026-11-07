%RED_TEAM_SENSITIVITY_REV1 How far the protection distances move under NASA-skeptic assumptions.
%   Victim: NASA NEN WG1 (Wallops), 11.3 m, 8160 MHz, published 57.5 dBi gain and
%   34.5 dB/K G/T (victim_systems_rev2). For each case the script reports:
%     - free-space main-beam distance to the long- and short-term criteria,
%     - single-drone separation (SA.509-3 single-entry pattern, worst azimuth)
%       at 5 and 13 deg pointing,
%     - the farthest distance at which the drone can be on a 5 deg boresight.
%   Each case changes one input from the baseline, except the combined case.
%   Writes fig5 and results_red_team_rev1.mat to ../output.

clearvars; close all;
here = fileparts(mfilename('fullpath'));
out_dir = fullfile(here, '..', 'output');
if ~isfolder(out_dir), mkdir(out_dir); end

p0 = uwb_eess_params_rev1();
v = victim_systems_rev2();
k = find(contains(v.name, "WG1"));
f0 = v.f_MHz(k);
g0 = v.g0_dBi(k);
p0.es.diam_m = v.diam_m(k);
p0.es.tsys_K = v.tsys_K(k);
h_part107 = p0.drone.h_max_m;
h_structure = 2*400*0.3048;          % 14 CFR 107.51(b) exception: 400 ft above a 400 ft structure
boost = 20*log10(1/50) - p0.uwb.eirp_dBm_per_MHz;   % 7.3 dB in-packet cap (uwb_pulse_metrics_rev1)
n10_dBm = 10*log10(physconst('Boltzmann')*p0.es.tsys_K*p0.crit.ref_bw_MHz*1e6) + 30;
in_m20_dBW = n10_dBm - 20 - 30;      % apportioned UWB criterion, I/N = -20 dB in 10 MHz

c = {};
%      name                                        f_MHz  h_m          pol  eirp_offset  crit_long_dBW  mask          short_boost
c(end+1,:) = {"Baseline",                            f0,   h_part107,   3,   0,           NaN,          "ieee802154", 0};
c(end+1,:) = {"No polarization credit (0 dB)",       f0,   h_part107,   0,   0,           NaN,          "ieee802154", 0};
c(end+1,:) = {"Ground reflection, +6 dB",            f0,   h_part107,   3,  -6,           NaN,          "ieee802154", 0};
c(end+1,:) = {"Two UWB radios per drone, +3 dB",     f0,   h_part107,   3,  -3,           NaN,          "ieee802154", 0};
c(end+1,:) = {"Four UWB radios per drone, +6 dB",    f0,   h_part107,   3,  -6,           NaN,          "ieee802154", 0};
c(end+1,:) = {"In-packet power on short term, +7.3 dB", f0, h_part107,  3,   0,           NaN,          "ieee802154", boost};
c(end+1,:) = {"Apportioned criterion, I/N = -20 dB", f0,   h_part107,   3,   0,           in_m20_dBW,   "ieee802154", 0};
c(end+1,:) = {"Structure exception, 243.84 m AGL",   f0,   h_structure, 3,   0,           NaN,          "ieee802154", 0};
c(end+1,:) = {"8350 MHz, IEEE mask (-18 dBr)",       8350, h_part107,   3,   0,           NaN,          "ieee802154", 0};
c(end+1,:) = {"8350 MHz, FCC envelope (flat)",       8350, h_part107,   3,   0,           NaN,          "flat",       0};
c(end+1,:) = {"Combined skeptic case",               f0,   h_structure, 0,  -9,           in_m20_dBW,   "ieee802154", boost};

n_c = size(c, 1);
ae_m = p0.prop.k_factor*p0.prop.re_km*1000;
[d_long, d_short, sep5, sep13, geo5, delta_long_dB] = deal(NaN(n_c, 1));
base_margin = NaN;
for j = 1:n_c
    p = p0;
    p.uwb.pol_loss_dB = c{j,4};
    p.uwb.eirp_offset_dB = c{j,5};
    p.uwb.mask_type = c{j,7};
    if ~isnan(c{j,6})
        e = p.crit.table.f_lo_MHz == 8025;
        p.crit.table.long_dBW(e) = c{j,6};
    end
    f = c{j,2}; h = c{j,3};
    cr = eess_criteria_rev1(f, p);
    e10 = uwb_power_in_band_rev1(f, p.crit.ref_bw_MHz, p.uwb);
    d_long(j)  = main_beam_distance_rev1(e10, g0, p.uwb.pol_loss_dB, cr.long_dBm, f, 5);
    d_short(j) = main_beam_distance_rev1(e10 + c{j,8}, g0, p.uwb.pol_loss_dB, cr.short_dBm, f, 5);
    margin = e10 + g0 - p.uwb.pol_loss_dB - cr.long_dBm;
    if j == 1, base_margin = margin; end
    delta_long_dB(j) = margin - base_margin;
    se = single_entry_separation_rev1(p, h, [5 13], f);
    sep5(j) = se.sep_long_km(1); sep13(j) = se.sep_long_km(2);
    t = tand(5);
    geo5(j) = (-t + sqrt(t^2 + 2*(h - p.es.h_m)/ae_m))*ae_m/1000;
end

rt = table(string(c(:,1)), [c{:,2}]', [c{:,3}]', delta_long_dB, d_long, d_short, sep5, sep13, geo5, ...
    'VariableNames', {'case','f_MHz','drone_h_m','delta_dB','mainbeam_long_km','mainbeam_short_km', ...
    'single_sep_long_el5_km','single_sep_long_el13_km','boresight_limit_el5_km'});
fprintf('\nRed-team sensitivity, %s (G0 %.1f dBi, G/T %.1f dB/K, Tsys %.0f K):\n', v.name(k), g0, v.g_over_t_dBK(k), v.tsys_K(k));
fprintf('Apportioned criterion I/N = -20 dB in 10 MHz: %.1f dBm (vs. SA.1027-6 long-term -120.0 dBm)\n', in_m20_dBW + 30);
disp(rt);

fig5 = figure('Visible', 'off'); theme(fig5, 'light');
tiledlayout(1, 2);
nexttile; barh(categorical(rt.case, rt.case), rt.mainbeam_long_km); set(gca, 'XScale', 'log'); grid on;
xlabel('Free-space main-beam distance, long term (km)'); title('Bound: drone on boresight');
nexttile; barh(categorical(rt.case, rt.case), [rt.single_sep_long_el5_km rt.single_sep_long_el13_km]); grid on;
xlabel('Single-drone separation, long term (km)'); legend({'el 5 deg','el 13 deg'}, 'Location', 'southeast');
title('SA.509-3 pattern, worst azimuth');
exportgraphics(fig5, fullfile(out_dir, 'fig5_red_team_sensitivity.png'), 'Resolution', 200);

save(fullfile(out_dir, 'results_red_team_rev1.mat'), 'rt', 'v', 'k', 'in_m20_dBW');
fprintf('Done. Outputs in %s\n', out_dir);
