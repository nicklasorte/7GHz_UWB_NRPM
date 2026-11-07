function out = single_entry_p528_rev1(p, F, h_d_m, el_point_deg, f_mhz, p_time, opts)
%SINGLE_ENTRY_P528_REV1 Single-drone separation with ITU-R P.528-5 loss instead of free space.
%   out = SINGLE_ENTRY_P528_REV1(p, F, h_d_m, el_point_deg, f_mhz, p_time)
%   places one drone at h_d_m in the dish azimuth (worst case), sweeps
%   distance, and uses the P.528 loss not exceeded for p_time percent of
%   time (F from P528_LOSS_TABLE_REV1) with the ITU-R SA.509-3 single-entry
%   pattern. Returns out.d_km, out.i_dBm, and the largest distance at which
%   the long- and short-term criteria are exceeded.
arguments
    p struct
    F
    h_d_m (1,1) double
    el_point_deg (1,1) double
    f_mhz (1,1) double
    p_time (1,1) double {mustBeInRange(p_time, 1, 99)}
    opts.d_km (1,:) double = [0.02:0.01:5, 5.05:0.05:20, 20.5:0.5:150]
end
crit = eess_criteria_rev1(f_mhz, p);
d = opts.d_km;
[~, el_deg] = air_to_ground_geometry_rev1(d, p.es.h_m, h_d_m, p.prop.k_factor, p.prop.re_km);
phi = abs(el_deg - el_point_deg);                       % drone in the dish azimuth
g = sa509_gain_rev1(min(phi, 180), p.es.diam_m, f_mhz, p.es.eff, "single");
L = F(log10(d), repmat(h_d_m, size(d)), repmat(p_time, size(d)));
e10 = uwb_power_in_band_rev1(f_mhz, p.crit.ref_bw_MHz, p.uwb);
i_dBm = e10 - p.uwb.eirp_offset_dB - L + g - p.uwb.pol_loss_dB - p.es.site_shield_dB;
out.d_km = d;
out.i_dBm = i_dBm;
out.sep_long_km = last_exceed(d, i_dBm, crit.long_dBm);
out.sep_short_km = last_exceed(d, i_dBm, crit.short_dBm);
out.crit = crit;
end

function s = last_exceed(d, i_row, lim)
k = find(i_row > lim, 1, 'last');
if isempty(k)
    s = 0;
elseif k == numel(d)
    error('single_entry_p528_rev1:grid', 'Exceedance at the end of the distance grid; extend opts.d_km.');
else
    s = d(k + 1);
end
end
