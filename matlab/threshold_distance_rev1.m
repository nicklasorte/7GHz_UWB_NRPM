function td = threshold_distance_rev1(p, F, f_mhz, opts)
%THRESHOLD_DISTANCE_REV1 Distance inside which one drone's interference exceeds each criterion, by off-axis angle.
%   td = THRESHOLD_DISTANCE_REV1(p, F, f_mhz) answers "how close does one
%   drone have to be?" for the main beam and the sidelobes. For each
%   off-axis angle phi (the angle between the dish boresight and the line
%   to the drone), it finds the slant distance d at which
%
%     EIRP_10 - L_pol - L_shield + G(phi) - L_b(d) = criterion          (1)
%
%   where L_b is the ITU-R P.528-5 basic transmission loss at opts.p_time
%   percent of time (free-space loss below 20 m, where P.528 isn't
%   tabulated). Inside d, the drone exceeds the criterion level whenever
%   it transmits.
%
%   Distance comes from power, not duty cycle. The duty cycle sets how
%   long a drone must stay inside d to use up the time allowance; see
%   td.hours_to_allowance. Because the long-term criterion allows 20% of
%   the time, a single drone with a duty cycle below 20% can't exceed it
%   at any distance; td.long_reachable_by_one_drone records this.
%
%   Name-value options:
%     phi_deg         off-axis angles (default: boresight, the 3 dB edge,
%                     and 1, 2, 5, 10, 20, 48, 90 degrees)
%     h_drone_m       drone height for the P.528 loss (default 400 ft)
%     p_time          P.528 time percentage (default 50)
%     eirp_offset_dB  reduction from the limit (default 0.54, AirTag worst)
%     crit_offset_dB  apportionment subtracted from both criteria (default 0)
%     pattern         "single" (default, the envelope) or "multiple"
%     duty            duty cycles for the time table (default
%                     [0.0005 0.003 0.01 0.05 1], from ECC Report 327 and FCC 26-66)
%     tracking_frac   share of time the dish receives (default NaN: skip the time table)
%
%   Fields: phi_deg, gain_dBi, d_short_km, d_long_km (NaN if beyond 200 km),
%   region ("main beam" inside the 3 dB half-width, "sidelobe" outside),
%   T_allow_trk_s and T_allow_all_s (short-term allowance per year),
%   hours_to_allowance (table: duty, hours inside d per year to use up the
%   allowance on each basis), long_reachable_by_one_drone (duty >= long_pct).
%
%   Built-ins considered: fzero would solve (1) per angle, but L_b is
%   tabulated, so a monotone interpolation on a fine distance grid is exact
%   to the table and vectorizes.
arguments
    p struct
    F
    f_mhz (1,1) double {mustBePositive}
    opts.phi_deg (1,:) double {mustBeNonnegative} = [NaN 0 1 2 5 10 20 48 90]
    opts.h_drone_m (1,1) double {mustBePositive} = p.drone.h_max_m
    opts.p_time (1,1) double {mustBeInRange(opts.p_time, 1, 99)} = 50
    opts.eirp_offset_dB (1,1) double = 0.54
    opts.crit_offset_dB (1,1) double = 0
    opts.pattern (1,1) string {mustBeMember(opts.pattern, ["single", "multiple"])} = "single"
    opts.duty (1,:) double {mustBePositive, mustBeLessThanOrEqual(opts.duty, 1)} = [0.0005 0.003 0.01 0.05 1]
    opts.tracking_frac (1,1) double = NaN
end
crit = eess_criteria_rev1(f_mhz, p);
e10 = uwb_power_in_band_rev1(f_mhz, p.crit.ref_bw_MHz, p.uwb);
const_dB = e10 - opts.eirp_offset_dB - p.uwb.pol_loss_dB - p.es.site_shield_dB;

% 3 dB half-width from the pattern
phi_tab = logspace(-4, log10(20), 4000);
g_tab = cummin(es_gain_rev1(phi_tab, p.es.diam_m, f_mhz, p.es.eff, opts.pattern));
g0 = g_tab(1);
[g_u, iu] = unique(g_tab, 'stable');
half3 = interp1(g0 - g_u, phi_tab(iu), 3);

phi = opts.phi_deg;
phi(isnan(phi)) = half3;                             % NaN in the list means "the 3 dB edge"
[phi, order] = sort(phi);
gain = es_gain_rev1(phi, p.es.diam_m, f_mhz, p.es.eff, opts.pattern);

% Loss versus distance: free space below 20 m, P.528 from 20 m to 200 km
d = logspace(log10(0.001), log10(200), 8000);
lambda = physconst('LightSpeed') / (f_mhz * 1e6);
L = 20 * log10(4 * pi * d * 1000 / lambda);
m = d >= 0.02;
L(m) = F(log10(d(m)), repmat(opts.h_drone_m, 1, nnz(m)), repmat(opts.p_time, 1, nnz(m)));
L = cummax(L);                                       % monotone in distance, so the inverse is single-valued
[L_u, il] = unique(L, 'stable');
d_u = d(il);
d_of_L = @(Lreq) interp1(L_u, d_u, Lreq, 'linear', NaN);

short_dBm = crit.short_dBm - opts.crit_offset_dB;
long_dBm = crit.long_dBm - opts.crit_offset_dB;
Ls = const_dB + gain - short_dBm;                    % largest loss that still exceeds the criterion
Ll = const_dB + gain - long_dBm;
td.phi_deg = phi(:);
td.gain_dBi = gain(:);
td.d_short_km = d_of_L(Ls(:));
td.d_long_km = d_of_L(Ll(:));
td.d_short_km(Ls(:) < L_u(1)) = 0;                   % even at 1 m the drone stays under
td.d_long_km(Ll(:) < L_u(1)) = 0;
td.region = repmat("sidelobe", numel(phi), 1);
td.region(phi(:) <= half3 + 1e-12) = "main beam";
td.half_beamwidth_deg = half3;
td.order = order;

year_s = 365.25 * 86400;
td.short_pct = crit.short_pct;
td.long_pct = crit.long_pct;
td.long_reachable_by_one_drone = opts.duty(:) >= crit.long_pct / 100;
if isfinite(opts.tracking_frac)
    td.T_allow_trk_s = crit.short_pct / 100 * opts.tracking_frac * year_s;
    td.T_allow_all_s = crit.short_pct / 100 * year_s;
    td.hours_to_allowance = table(100 * opts.duty(:), td.T_allow_trk_s ./ opts.duty(:) / 3600, ...
        td.T_allow_all_s ./ opts.duty(:) / 3600, td.long_reachable_by_one_drone, ...
        'VariableNames', {'duty_pct', 'hours_tracking_basis', 'hours_all_time_basis', 'can_exceed_long_term_alone'});
end
td.settings = opts;
end
