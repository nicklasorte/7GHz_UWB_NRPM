function lb = link_budget_walkthrough_rev1(p, F, f_mhz, h_d_m, d_km, el_point_deg, az_off_deg, p_time)
%LINK_BUDGET_WALKTHROUGH_REV1 Step-by-step single-drone link budget that a reviewer can check by hand.
%   lb = LINK_BUDGET_WALKTHROUGH_REV1(p, F, f_mhz, h_d_m, d_km, el_point_deg, az_off_deg, p_time)
%   returns a table with one row per step for one drone at height h_d_m and
%   ground distance d_km, with the dish at elevation el_point_deg and the
%   drone az_off_deg away from the dish azimuth. p_time is the P.528 time
%   percentage. Columns: step, value, unit, source.
%
%   Uses the single-entry antenna pattern (ITU-R SA.509-3 "single" or
%   F.699-5 by antenna size), as single-entry studies do.
arguments
    p struct
    F
    f_mhz (1,1) double
    h_d_m (1,1) double {mustBePositive}
    d_km (1,1) double {mustBePositive}
    el_point_deg (1,1) double
    az_off_deg (1,1) double
    p_time (1,1) double {mustBeInRange(p_time, 1, 99)} = 50
end
crit = eess_criteria_rev1(f_mhz, p);
e10 = uwb_power_in_band_rev1(f_mhz, p.crit.ref_bw_MHz, p.uwb);
[slant_km, el_d] = air_to_ground_geometry_rev1(d_km, p.es.h_m, h_d_m, p.prop.k_factor, p.prop.re_km);
cos_phi = sind(el_d) * sind(el_point_deg) + cosd(el_d) * cosd(el_point_deg) * cosd(az_off_deg);
phi = acosd(min(max(cos_phi, -1), 1));
[g, g_src] = es_gain_rev1(phi, p.es.diam_m, f_mhz, p.es.eff, "single");
g0 = es_gain_rev1(0, p.es.diam_m, f_mhz, p.es.eff, "single");
lambda = physconst('LightSpeed') / (f_mhz * 1e6);
fsl = 20 * log10(4 * pi * slant_km * 1000 / lambda);
L = F(log10(d_km), h_d_m, p_time);
i_dBm = e10 - p.uwb.eirp_offset_dB - p.uwb.pol_loss_dB - p.es.site_shield_dB - L + g;

s = {
    "UWB average EIRP density limit",            p.uwb.eirp_dBm_per_MHz,    "dBm/MHz", "47 CFR 15.519(c)"
    "Reference bandwidth",                       p.crit.ref_bw_MHz,         "MHz",     "ITU-R SA.1026-5 / SA.1027-6"
    "UWB EIRP in the reference bandwidth at f",  e10,                       "dBm",     "IEEE 802.15.4 HRP mask over -41.3 dBm/MHz; 10log10(10) = 10 dB in-band"
    "EIRP reduction toward the station",         p.uwb.eirp_offset_dB,      "dB",      "Assumption (0 = isotropic at the limit)"
    "Polarization mismatch",                     p.uwb.pol_loss_dB,         "dB",      "Linear into circular feed"
    "Drone height AGL",                          h_d_m,                     "m",       "Input"
    "Earth station antenna height",              p.es.h_m,                  "m",       "Input"
    "Ground distance",                           d_km,                      "km",      "Input"
    "Slant range",                               slant_km,                  "km",      "4/3-Earth geometry"
    "Drone elevation seen from the dish",        el_d,                      "deg",     "4/3-Earth geometry"
    "Dish pointing elevation",                   el_point_deg,              "deg",     "Input"
    "Azimuth offset from the dish",              az_off_deg,                "deg",     "Input"
    "Off-axis angle",                            phi,                       "deg",     "Spherical law of cosines"
    "Dish peak gain",                            g0,                        "dBi",     g_src
    "Dish gain toward the drone",                g,                         "dBi",     g_src
    "Free-space loss at the slant range",        fsl,                       "dB",      "20 log10(4 pi d / lambda)"
    "ITU-R P.528-5 basic transmission loss",     L,                         "dB",      sprintf("P.528-5 at %g%% of time (itu_p528)", p_time)
    "Interference at the antenna output",        i_dBm,                     "dBm/10 MHz", "EIRP - losses - P.528 + gain"
    "Long-term criterion",                       crit.long_dBm,             "dBm/10 MHz", crit.source + sprintf(" (%g%% of time)", crit.long_pct)
    "Short-term criterion",                      crit.short_dBm,            "dBm/10 MHz", crit.source + sprintf(" (%g%% of time)", crit.short_pct)
    "Margin to long-term criterion",             i_dBm - crit.long_dBm,     "dB",      "Positive = exceeds"
    "Margin to short-term criterion",            i_dBm - crit.short_dBm,    "dB",      "Positive = exceeds"
    };
lb = cell2table(s, 'VariableNames', {'step', 'value', 'unit', 'source'});
end
