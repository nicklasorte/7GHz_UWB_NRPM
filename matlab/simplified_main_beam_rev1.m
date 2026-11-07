%SIMPLIFIED_MAIN_BEAM_REV1 Line-of-sight, main-beam UWB drone vs. NASA-related receive systems.
%   Bounding analysis: one UWB channel 9 drone on the earth station boresight,
%   free-space path, full 47 CFR 15.519 EIRP, no clutter, no shielding.
%   For each victim system it reports the distance at which the drone reaches
%     - the ITU-R long-term criterion (20% of time),
%     - the ITU-R short-term criterion,
%     - the short-term criterion with the in-packet (burst) power,
%     - I/N = -6 dB and -10 dB in the receiver bandwidth (where Tsys is known),
%   and the drone height needed to actually be on boresight at that distance.
%   Writes fig4/fig5 and results_simplified_main_beam_rev1.mat to ../output.

clearvars; close all;
here = fileparts(mfilename('fullpath'));
out_dir = fullfile(here, '..', 'output');
if ~isfolder(out_dir), mkdir(out_dir); end

p = uwb_eess_params_rev1();
v = victim_systems_rev1();
ref_bw = p.crit.ref_bw_MHz;
el_set = [p.es.el_min_deg p.es.el_long_deg];
h_drone_rel_m = p.drone.h_max_m - p.es.h_m;   % highest Part 107 drone above the dish center
n_v = height(v);

%% Pulse structure in each receiver bandwidth
bw_list = [1; ref_bw; v.rx_bw_MHz(~isnan(v.rx_bw_MHz))];
pm = uwb_pulse_metrics_rev1(bw_list, p.uwb, p.uwb.t_on_ms);
pulse_tbl = table(pm.rx_bw_MHz, pm.avg_dBm, pm.burst_dBm(:,1), pm.peak_env_dBm, pm.par_reg_dB, ...
    pm.regime(:,1), pm.par_pulse_dB(:,1), pm.par_pulse_dB(:,3), pm.peak_note, ...
    'VariableNames', {'rx_bw_MHz','avg_eirp_dBm','burst_eirp_dBm_ton_min','peak_env_dBm','par_reg_dB', ...
    'regime_BPRF','par_BPRF_dB','par_HPRF249_dB','peak_note'});
fprintf('\nUWB ch 9 emission inside victim bandwidths (in-channel, 15.519 limits; burst at t_on = %g ms):\n', p.uwb.t_on_ms(1));
disp(pulse_tbl);
pm10 = uwb_pulse_metrics_rev1(ref_bw, p.uwb, p.uwb.t_on_ms);
fprintf('In-packet boost in 10 MHz for t_on = %s ms: %s dB (capped at %.1f dB by the 1 MHz peak limit)\n', ...
    mat2str(p.uwb.t_on_ms), mat2str(pm10.burst_boost_dB, 3), 20*log10(1/50) - p.uwb.eirp_dBm_per_MHz);

%% Distances
res = table('Size', [n_v 0]);
res.name = v.name;
res.f_MHz = v.f_MHz;
res.g0_dBi = v.g0_dBi;
res.tsys_K = v.tsys_K;
[d_long, d_short, d_burst, d_in6, d_in10, crit_long, crit_short] = deal(NaN(n_v, 1));
for k = 1:n_v
    c = eess_criteria_rev1(v.f_MHz(k), p);
    crit_long(k) = c.long_dBm; crit_short(k) = c.short_dBm;
    e10 = uwb_power_in_band_rev1(v.f_MHz(k), ref_bw, p.uwb);          % dBm per 10 MHz at this frequency
    d_long(k)  = main_beam_distance_rev1(e10, v.g0_dBi(k), p.uwb.pol_loss_dB, c.long_dBm,  v.f_MHz(k), 5);
    d_short(k) = main_beam_distance_rev1(e10, v.g0_dBi(k), p.uwb.pol_loss_dB, c.short_dBm, v.f_MHz(k), 5);
    d_burst(k) = main_beam_distance_rev1(e10 + pm10.burst_boost_dB(1), v.g0_dBi(k), p.uwb.pol_loss_dB, ...
        c.short_dBm, v.f_MHz(k), 5);
    if ~isnan(v.tsys_K(k)) && ~isnan(v.rx_bw_MHz(k))
        b = v.rx_bw_MHz(k);
        eb = uwb_power_in_band_rev1(v.f_MHz(k), b, p.uwb);
        n_dBm = 10*log10(physconst('Boltzmann')*v.tsys_K(k)*b*1e6) + 30;
        d_in6(k)  = main_beam_distance_rev1(eb, v.g0_dBi(k), p.uwb.pol_loss_dB, n_dBm - 6,  v.f_MHz(k), 5);
        d_in10(k) = main_beam_distance_rev1(eb, v.g0_dBi(k), p.uwb.pol_loss_dB, n_dBm - 10, v.f_MHz(k), 5);
    end
end
res.crit_long_dBm_10MHz = crit_long;
res.crit_short_dBm_10MHz = crit_short;
res.d_long_km = d_long;
res.d_short_km = d_short;
res.d_short_burst_km = d_burst;
res.d_IN_m6_km = d_in6;
res.d_IN_m10_km = d_in10;
fprintf('\nFree-space distance for one main-beam UWB drone to reach each threshold:\n');
disp(res);

%% Geometry: where can a Part 107 drone actually be on boresight?
ae_m = p.prop.k_factor*p.prop.re_km*1000;
d_geo_km = NaN(1, numel(el_set));
for e = 1:numel(el_set)
    % largest d with d tan(el) + d^2/(2 ae) <= h_drone_rel  (positive root)
    t = tand(el_set(e));
    d_geo_km(e) = (-t + sqrt(t^2 + 2*h_drone_rel_m/ae_m)) * ae_m / 1000;
end
h_req = d_long*1000.*tand(el_set) + (d_long*1000).^2/(2*ae_m);   % (n_v x n_el), same formula as main_beam_distance_rev1
fprintf('Highest Part 107 drone (%.2f m AGL) is on a %s deg boresight only within %s km of the dish.\n', ...
    p.drone.h_max_m, mat2str(el_set), mat2str(d_geo_km, 3));
for k = 1:n_v
    fprintf('  %-55s long-term distance %.1f km needs the drone at %s m above the dish for el %s deg\n', ...
        v.name(k), d_long(k), mat2str(round(h_req(k, :))), mat2str(el_set));
end

%% Interference at the geometric main-beam limit
i_at_geo = NaN(n_v, numel(el_set));
for k = 1:n_v
    e10 = uwb_power_in_band_rev1(v.f_MHz(k), ref_bw, p.uwb);
    for e = 1:numel(el_set)
        [s_km, ~] = air_to_ground_geometry_rev1(d_geo_km(e), p.es.h_m, p.drone.h_max_m, p.prop.k_factor, p.prop.re_km);
        lambda_m = physconst('LightSpeed')/(v.f_MHz(k)*1e6);
        i_at_geo(k, e) = e10 - fspl(s_km*1000, lambda_m) + v.g0_dBi(k) - p.uwb.pol_loss_dB;
    end
end
excess_tbl = array2table(i_at_geo - crit_long, 'VariableNames', compose("excess_long_dB_el%g", el_set));
excess_tbl = [table(v.name, 'VariableNames', {'name'}) excess_tbl];
fprintf('\nExcess over the long-term criterion with the drone on boresight at the geometric limit:\n');
disp(excess_tbl);

%% Figure 4: boresight interference vs distance
d = logspace(-1, 2, 400);
fig4 = figure('Visible', 'off'); theme(fig4, 'light');
cols = lines(n_v);
for k = 1:n_v
    e10 = uwb_power_in_band_rev1(v.f_MHz(k), ref_bw, p.uwb);
    lambda_m = physconst('LightSpeed')/(v.f_MHz(k)*1e6);
    semilogx(d, e10 - fspl(d*1000, lambda_m) + v.g0_dBi(k) - p.uwb.pol_loss_dB, 'Color', cols(k,:), 'LineWidth', 1.4); hold on;
end
yline(crit_long(2), 'k--', 'EESS long-term (SA.1027)');
yline(crit_long(1), 'k-.', 'MetSat long-term (SA.1026)');
yline(crit_short(2), 'k:', 'EESS short-term');
xline(d_geo_km, ':', compose("Part 107 boresight limit, el %g deg", el_set));
grid on; ylim([-150 -40]);
xlabel('Distance from earth station (km)'); ylabel('I on boresight (dBm per 10 MHz)');
legend(v.name, 'Location', 'southwest');
title('One UWB ch 9 drone on boresight, free space, 15.519 average EIRP');
exportgraphics(fig4, fullfile(out_dir, 'fig4_main_beam_distance.png'), 'Resolution', 200);

save(fullfile(out_dir, 'results_simplified_main_beam_rev1.mat'), 'p', 'v', 'res', 'pulse_tbl', 'pm10', ...
    'd_geo_km', 'h_req', 'excess_tbl');
fprintf('Done. Outputs in %s\n', out_dir);
