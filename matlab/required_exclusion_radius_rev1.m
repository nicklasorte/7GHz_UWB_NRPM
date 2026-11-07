function [r_req_km, margin_dB] = required_exclusion_radius_rev1(r_ex_km, level_dBm, crit_dBm)
%REQUIRED_EXCLUSION_RADIUS_REV1 Smallest exclusion radius that meets a criterion at every larger radius.
%   [r_req_km, margin_dB] = REQUIRED_EXCLUSION_RADIUS_REV1(r_ex_km, level_dBm, crit_dBm)
%   level_dBm is the aggregate percentile on the r_ex_km grid. margin_dB is
%   level - criterion (positive = exceedance). r_req_km is NaN when the
%   criterion fails at the largest radius (not achievable inside the horizon).
%
%   A full grid scan replaces the bisection in the 2.7 GHz working paper:
%   the Monte Carlo already returns every radius, and the scan does not
%   assume monotonicity.
arguments
    r_ex_km (1,:) double
    level_dBm (1,:) double
    crit_dBm (1,1) double
end
margin_dB = level_dBm - crit_dBm;
k = find(margin_dB > 0, 1, 'last');
if isempty(k)
    r_req_km = 0;
elseif k == numel(r_ex_km)
    r_req_km = NaN;
else
    r_req_km = r_ex_km(k + 1);
end
end
