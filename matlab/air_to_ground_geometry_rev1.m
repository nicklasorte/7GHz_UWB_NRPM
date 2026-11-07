function [slant_km, el_deg, los] = air_to_ground_geometry_rev1(d_km, h_es_m, h_d_m, k_factor, re_km)
%AIR_TO_GROUND_GEOMETRY_REV1 Slant range, elevation, and LOS flag on a smooth effective Earth.
%   [slant_km, el_deg, los] = AIR_TO_GROUND_GEOMETRY_REV1(d_km, h_es_m, h_d_m, k_factor, re_km)
%   d_km is great-circle ground distance from the earth station to the drone;
%   h_es_m and h_d_m are heights above a common ground level. el_deg is the
%   elevation of the drone seen from the earth station (refraction through k).
%   los is true when the drone is inside the smooth-Earth radio horizon.
%
%   Built-ins considered: elevation/geodetic2aer (Mapping Toolbox) work on the
%   true ellipsoid and do not take an effective-Earth k factor, so the 4/3
%   Earth geometry is written out here in a cancellation-free form.
arguments
    d_km double {mustBeNonnegative}
    h_es_m double
    h_d_m double
    k_factor (1,1) double {mustBePositive} = 4/3
    re_km (1,1) double {mustBePositive} = 6371
end
ae = k_factor*re_km;
theta = d_km./ae;
r1 = ae + h_es_m/1000;
r2 = ae + h_d_m/1000;
s2 = sin(theta/2).^2;
slant_km = sqrt((r2 - r1).^2 + 4.*r1.*r2.*s2);
el_deg = atan2d((r2 - r1) - 2.*r2.*s2, r2.*sin(theta));
d_hor_km = sqrt(2*ae*max(h_es_m,0)/1000) + sqrt(2*ae*max(h_d_m,0)/1000);
los = d_km <= d_hor_km;
end
