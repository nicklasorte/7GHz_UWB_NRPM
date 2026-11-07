%MAIN_UWB_CH9_EESS_REV1 Drone-borne UWB channel 9 into NASA EESS (and NOAA MetSat) earth stations.
%   Runs the full study and writes figures and a results .mat to ../output.
%     1. Spectrum overlap of UWB ch 9 with EESS/MetSat downlink bands
%     2. UWB EIRP per 10 MHz across 7.7-8.4 GHz (device mask vs. FCC envelope)
%     3. Single-entry separation for one hovering drone (worst-case azimuth)
%     4. Monte Carlo aggregate vs. exclusion radius, swept over active drone density
%     5. EIRP reduction needed with no exclusion zone (compare ECC/DEC/(12)03)
%   Set quick_flag = 1 for a fast smoke run.

clearvars; close all;
quick_flag = 0;

here = fileparts(mfilename('fullpath'));
out_dir = fullfile(here, '..', 'output');
if ~isfolder(out_dir), mkdir(out_dir); end

p = uwb_eess_params_rev1();
f_v = p.es.f_victim_MHz;
crit = eess_criteria_rev1(f_v, p);
if quick_flag %#ok<UNRCH> constant switch for smoke runs
    n_long = 2e3; n_short = 2e4; dens = [1e-2 1e-1];
else
    n_long = 2e4; n_short = p.mc.n_iter; dens = p.mc.density_active_per_km2;
end

%% 1. Spectrum overlap
ch_lo = p.uwb.fc_MHz - p.uwb.bw_MHz/2;
ch_hi = p.uwb.fc_MHz + p.uwb.bw_MHz/2;
t = p.crit.table;
ov_lo = max(t.f_lo_MHz, ch_lo); ov_hi = min(t.f_hi_MHz, ch_hi);
overlap_MHz = max(ov_hi - ov_lo, 0);
fprintf('UWB ch 9: %.1f-%.1f MHz\n', ch_lo, ch_hi);
for k = 1:height(t)
    fprintf('  %4.0f-%4.0f MHz: %.1f MHz in-channel overlap  [%s]\n', t.f_lo_MHz(k), t.f_hi_MHz(k), overlap_MHz(k), t.source(k));
end
fprintf('Criteria at %.0f MHz: long %.1f dBm/%g MHz (%g%%, I/N %.1f dB), short %.1f dBm (%g%%, I/N %.1f dB), Tsys %g K\n', ...
    f_v, crit.long_dBm, crit.ref_bw_MHz, crit.long_pct, crit.long_IN_dB, crit.short_dBm, crit.short_pct, crit.short_IN_dB, p.es.tsys_K);

%% 2. UWB EIRP per reference bandwidth vs. frequency
f_sweep = 7700:2:8400;
uwb_flat = p.uwb; uwb_flat.mask_type = "flat";
e_mask = uwb_power_in_band_rev1(f_sweep, p.crit.ref_bw_MHz, p.uwb);
e_flat = uwb_power_in_band_rev1(f_sweep, p.crit.ref_bw_MHz, uwb_flat);
fig1 = figure('Visible', 'off');
plot(f_sweep, e_mask, 'LineWidth', 1.5); hold on;
plot(f_sweep, e_flat, '--', 'LineWidth', 1.2);
yl = [-55 -25]; ylim(yl);
for k = 1:height(t)
    patch([t.f_lo_MHz(k) t.f_hi_MHz(k) t.f_hi_MHz(k) t.f_lo_MHz(k)], [yl(1) yl(1) yl(2) yl(2)], ...
        [0.5 0.5 0.5], 'FaceAlpha', 0.12, 'EdgeColor', 'none');
end
xline([ch_lo ch_hi], ':', {'ch 9 low', 'ch 9 high'});
grid on; xlabel('Victim center frequency (MHz)'); ylabel(sprintf('UWB EIRP (dBm/%g MHz)', p.crit.ref_bw_MHz));
legend({'IEEE 802.15.4 mask at 15.519 limit', 'FCC 15.519 envelope (flat)', 'MetSat 7750-7900', 'EESS 8025-8400'}, 'Location', 'southwest');
title('UWB channel 9 EIRP in a 10 MHz EESS reference bandwidth');
exportgraphics(fig1, fullfile(out_dir, 'fig1_uwb_eirp_vs_freq.png'), 'Resolution', 200);

%% 3. Single-entry separation
alt_m = [30; 60; p.drone.h_max_m];
el_p = [5 13 30];
se = single_entry_separation_rev1(p, alt_m, el_p, f_v);
se_tbl = array2table([alt_m, se.sep_long_km], 'VariableNames', ...
    ['alt_m', compose("sep_long_km_el%g", el_p)]);
se_tbl_short = array2table([alt_m, se.sep_short_km], 'VariableNames', ...
    ['alt_m', compose("sep_short_km_el%g", el_p)]);
disp('Single hovering drone in ES azimuth, long-term criterion (km):'); disp(se_tbl);
disp('Single drone, short-term criterion (km):'); disp(se_tbl_short);

fig2 = figure('Visible', 'off');
for e = 1:numel(el_p)
    semilogx(se.d_km, squeeze(se.i_dBm(end, e, :)), 'LineWidth', 1.3); hold on;
end
yline(crit.long_dBm, 'k--', 'Long-term (20%)');
yline(crit.short_dBm, 'k:', 'Short-term');
grid on; xlim([0.05 60]); ylim([-200 -80]);
xlabel('Ground distance from earth station (km)'); ylabel(sprintf('I (dBm/%g MHz)', crit.ref_bw_MHz));
legend(compose("ES pointing el %g deg", el_p), 'Location', 'northeast');
title(sprintf('One UWB drone at %.0f m AGL in the ES azimuth, %g MHz', p.drone.h_max_m, f_v));
exportgraphics(fig2, fullfile(out_dir, 'fig2_single_entry.png'), 'Resolution', 200);

%% 4. Aggregate Monte Carlo
n_d = numel(dens);
r_req = NaN(n_d, 3);   % [long, short, governing]
m0 = NaN(n_d, 2);      % margin at zero exclusion [long, short]
fig3 = figure('Visible', 'off'); tiledlayout(1, 2);
ax1 = nexttile; hold(ax1, 'on'); ax2 = nexttile; hold(ax2, 'on');
mc_long = cell(n_d, 1); mc_short = cell(n_d, 1);
for k = 1:n_d
    a_l = aggregate_drone_mc_rev1(p, dens(k), p.es.el_long_deg, f_v, 'n_iter', n_long, 'pct_exceed', crit.long_pct);
    a_s = aggregate_drone_mc_rev1(p, dens(k), p.es.el_short_deg, f_v, 'n_iter', n_short, 'pct_exceed', crit.short_pct);
    [r_req(k,1), mg_l] = required_exclusion_radius_rev1(a_l.r_ex_km, a_l.pct_dBm, crit.long_dBm);
    [r_req(k,2), mg_s] = required_exclusion_radius_rev1(a_s.r_ex_km, a_s.pct_dBm, crit.short_dBm);
    r_req(k,3) = max(r_req(k,1:2));
    m0(k,:) = [mg_l(1) mg_s(1)];
    plot(ax1, a_l.r_ex_km, mg_l, 'LineWidth', 1.3);
    plot(ax2, a_s.r_ex_km, mg_s, 'LineWidth', 1.3);
    mc_long{k} = rmfield(a_l, 'agg_mW'); mc_short{k} = rmfield(a_s, 'agg_mW');
    fprintf('density %.0e /km^2: mean %.1f drones in disk; r_req long %.1f km, short %.1f km; margin at r=0 long %+.1f dB, short %+.1f dB\n', ...
        dens(k), a_l.mean_drones, r_req(k,1), r_req(k,2), m0(k,1), m0(k,2));
end
for ax = [ax1 ax2]
    yline(ax, 0, 'k-'); grid(ax, 'on'); xlim(ax, [0 20]); xlabel(ax, 'Exclusion (geofence) radius (km)');
    ylabel(ax, 'Aggregate minus criterion (dB)');
    legend(ax, compose("%.0e active/km^2", dens), 'Location', 'northeast');
end
title(ax1, sprintf('Long-term, %g%% of time, ES el %g deg', crit.long_pct, p.es.el_long_deg));
title(ax2, sprintf('Short-term, %g%% of time, ES el %g deg', crit.short_pct, p.es.el_short_deg));
exportgraphics(fig3, fullfile(out_dir, 'fig3_aggregate_margin_vs_radius.png'), 'Resolution', 200);

agg_tbl = table(dens(:), r_req(:,1), r_req(:,2), r_req(:,3), m0(:,1), m0(:,2), ...
    'VariableNames', {'active_density_per_km2','r_req_long_km','r_req_short_km','r_req_km','margin_r0_long_dB','margin_r0_short_dB'});
disp(agg_tbl);

%% 5. EIRP needed with no exclusion zone
eirp_needed = p.uwb.eirp_dBm_per_MHz - max(max(m0, [], 2), 0);
fprintf('Max UWB EIRP with no exclusion zone (dBm/MHz) by density: %s\n', mat2str(eirp_needed', 4));
fprintf('Reference: ECC/DEC/(12)03 aircraft UWB, 7.75-7.9 GHz, <=1000 m AGL: -64.3 dBm/MHz.\n');

%% MetSat check (7800 MHz) for the single-entry case
se_met = single_entry_separation_rev1(p, p.drone.h_max_m, el_p, 7800);
fprintf('MetSat 7800 MHz single drone @%.0f m, long-term sep (km) for el %s: %s\n', ...
    p.drone.h_max_m, mat2str(el_p), mat2str(se_met.sep_long_km, 3));

save(fullfile(out_dir, 'results_uwb_ch9_eess_rev1.mat'), 'p', 'crit', 'se', 'se_met', 'agg_tbl', ...
    'mc_long', 'mc_short', 'eirp_needed', 'dens');
fprintf('Done. Outputs in %s\n', out_dir);
