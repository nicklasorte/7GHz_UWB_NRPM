function [i_mW, phi_deg, L_db] = device_interference_rev1(dev, pt, geo, F, ant, const_dB, clutter_f_ghz, short_rule)
%DEVICE_INTERFERENCE_REV1 Interference power from each UWB device at the earth station antenna output.
%   [i_mW, phi_deg, L_db] = DEVICE_INTERFERENCE_REV1(dev, pt, geo, F, ant, const_dB, clutter_f_ghz)
%   evaluates one link per element. Shared by AGGREGATE_DRONE_MC_REV4 and
%   EXCEEDANCE_FOOTPRINT_REV1 so both use identical physics.
%
%   dev  struct of column vectors: r_km (ground distance), az_rad, h_m,
%        p_time (P.528 time percentage, 1-99), p_loc (P.2108 location
%        percentage, 0-100 exclusive; used only when clutter_f_ghz is finite)
%   pt   struct of column vectors: el_rad, az_rad (dish pointing per device)
%   geo  struct: ae_km (effective Earth radius), r1_km (ae + earth station height)
%   F    griddedInterpolant of P.528 loss, F(log10(d_km), h_m, p_time)
%   ant  struct: diam_m, f_mhz, eff, pattern ("single" or "multiple")
%   const_dB  EIRP in the reference bandwidth minus fixed losses (dBm)
%   clutter_f_ghz  frequency for ITU-R P.2108 sec. 3.2 clutter at the
%        device end (NaN = no clutter, for example airborne drones)
%
%   Clutter uses the validated port github.com/nicklasorte/itu_p2108
%   (p2108_terrestrial_rev1, exact inverse CCDF). The Recommendation gives
%   no value for paths shorter than 0.25 km. short_rule sets the assumption:
%     "zero" (default)  no clutter loss below 0.25 km (conservative)
%     "hold"            the 0.25 km loss below 0.25 km
%   The choice moves the long-term ground baseline by up to about 17 dB,
%   because the nearest devices set that level.
%
%   Elevation and off-axis angle use the 4/3-Earth geometry of
%   AIR_TO_GROUND_GEOMETRY_REV1 in a form that avoids atan2d round trips.
arguments
    dev struct
    pt struct
    geo struct
    F
    ant struct
    const_dB (1,1) double
    clutter_f_ghz (1,1) double = NaN
    short_rule (1,1) string {mustBeMember(short_rule, ["zero", "hold"])} = "zero"
end
theta = dev.r_km / geo.ae_km;
r2 = geo.ae_km + dev.h_m / 1000;
s2 = sin(theta / 2).^2;
num = (r2 - geo.r1_km) - 2 * r2 .* s2;
den = r2 .* sin(theta);
hyp = sqrt(num.^2 + den.^2);
sin_el = num ./ hyp;
cos_el = den ./ hyp;
cos_phi = sin_el .* sin(pt.el_rad) + cos_el .* cos(pt.el_rad) .* cos(dev.az_rad - pt.az_rad);
phi_deg = acosd(min(max(cos_phi, -1), 1));
g = es_gain_rev1(phi_deg, ant.diam_m, ant.f_mhz, ant.eff, ant.pattern);
L_db = F(log10(max(dev.r_km, 0.02)), dev.h_m, dev.p_time);
if isfinite(clutter_f_ghz)
    L_ctt = p2108_terrestrial_rev1(clutter_f_ghz, max(dev.r_km, 0.25), dev.p_loc, q_inverse="exact");
    if short_rule == "zero"
        L_ctt(dev.r_km < 0.25) = 0;
    end
    L_db = L_db + L_ctt;
end
i_mW = exp((const_dB - L_db + g) * (log(10) / 10));
end
