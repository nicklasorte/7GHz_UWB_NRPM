function [i_dBm, g_dBi, phi_deg, el_deg, loss_dB] = uwb_to_es_interference_rev1(p, d_km, h_d_m, daz_deg, el_point_deg, f_MHz, pattern)
%UWB_TO_ES_INTERFERENCE_REV1 Interference from one UWB drone at the ES antenna output.
%   i_dBm = UWB_TO_ES_INTERFERENCE_REV1(p, d_km, h_d_m, daz_deg, el_point_deg, f_MHz, pattern)
%   returns interference power (dBm per p.crit.ref_bw_MHz). d_km, h_d_m and
%   daz_deg (drone azimuth minus ES pointing azimuth) are same-size arrays;
%   el_point_deg is a scalar or same size. Drones beyond the radio horizon
%   return -Inf.
%
%   I = EIRP_ref(f) - FSPL(slant, f) + G_es(phi) - L_pol - L_shield      (dB)
arguments
    p struct
    d_km double {mustBeNonnegative}
    h_d_m double
    daz_deg double
    el_point_deg double
    f_MHz (1,1) double {mustBePositive}
    pattern (1,1) string = "single"
end
[slant_km, el_deg, los] = air_to_ground_geometry_rev1(d_km, p.es.h_m, h_d_m, p.prop.k_factor, p.prop.re_km);

cos_phi = sind(el_deg).*sind(el_point_deg) + cosd(el_deg).*cosd(el_point_deg).*cosd(daz_deg);
phi_deg = acosd(min(max(cos_phi, -1), 1));
g_dBi = sa509_gain_rev1(phi_deg, p.es.diam_m, f_MHz, p.es.eff, pattern);

lambda_m = physconst('LightSpeed')/(f_MHz*1e6);
loss_dB = fspl(max(slant_km*1000, lambda_m), lambda_m);   % fspl clamps R < lambda to 0 dB; floor keeps it physical

eirp_ref_dBm = uwb_power_in_band_rev1(f_MHz, p.crit.ref_bw_MHz, p.uwb);
i_dBm = eirp_ref_dBm - loss_dB + g_dBi - p.uwb.pol_loss_dB - p.es.site_shield_dB;
i_dBm(~los) = -Inf;
end
