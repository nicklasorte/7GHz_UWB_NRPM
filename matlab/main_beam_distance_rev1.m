function [d_km, h_req_m] = main_beam_distance_rev1(eirp_dBm, g0_dBi, l_pol_dB, i_th_dBm, f_MHz, el_point_deg, opts)
%MAIN_BEAM_DISTANCE_REV1 Free-space distance at which a main-beam UWB drone reaches a threshold.
%   [d_km, h_req_m] = MAIN_BEAM_DISTANCE_REV1(eirp_dBm, g0_dBi, l_pol_dB, i_th_dBm, f_MHz, el_point_deg)
%   Solves  eirp - FSPL(d) + G0 - L_pol = I_th  for d (line of sight, drone
%   on the earth station boresight):
%       d = lambda/(4 pi) * 10^((eirp + G0 - L_pol - I_th)/20)
%   eirp_dBm and i_th_dBm must be in the same bandwidth. h_req_m is the drone
%   height above the earth station needed to sit on a boresight at
%   el_point_deg at that distance on a 4/3 Earth:
%       h = d tan(el) + d^2 / (2 k Re)
%   Inputs expand implicitly.
arguments
    eirp_dBm double
    g0_dBi double
    l_pol_dB double
    i_th_dBm double
    f_MHz double {mustBePositive}
    el_point_deg double
    opts.k_factor (1,1) double = 4/3
    opts.re_km (1,1) double = 6371
end
lambda_m = physconst('LightSpeed')./(f_MHz*1e6);
d_m = lambda_m./(4*pi) .* 10.^((eirp_dBm + g0_dBi - l_pol_dB - i_th_dBm)/20);
d_km = d_m/1000;
h_req_m = d_m.*tand(el_point_deg) + d_m.^2./(2*opts.k_factor*opts.re_km*1000);
end
