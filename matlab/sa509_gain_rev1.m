function g_dBi = sa509_gain_rev1(phi_deg, diam_m, f_MHz, eff, pattern)
%SA509_GAIN_REV1 ITU-R SA.509-3 reference earth station antenna gain.
%   g_dBi = SA509_GAIN_REV1(phi_deg, diam_m, f_MHz, eff, pattern) returns the
%   gain at off-axis angle phi_deg (0-180 deg). pattern is "single" (single
%   entry, worst case from one source) or "multiple" (aggregate from many
%   sources), per ITU-R SA.509-3 sections 1.1 and 1.2. Valid for D/lambda >= 100.
%
%   G0   = 10 log10(eta (pi D/lambda)^2)
%   phi0 = 20 sqrt(3) / (D/lambda)        (half the 3 dB beamwidth, deg)
%   phi2 = 10^((49 - G0)/25)
arguments
    phi_deg double {mustBeGreaterThanOrEqual(phi_deg,0), mustBeLessThanOrEqual(phi_deg,180)}
    diam_m (1,1) double {mustBePositive}
    f_MHz (1,1) double {mustBePositive}
    eff (1,1) double {mustBePositive, mustBeLessThanOrEqual(eff,1)}
    pattern (1,1) string {mustBeMember(pattern,["single","multiple"])} = "multiple"
end

lambda_m = physconst('LightSpeed')/(f_MHz*1e6);
d_over_l = diam_m/lambda_m;
if d_over_l < 100
    error('sa509_gain_rev1:smallAntenna', ...
        'ITU-R SA.509-3 applies only for D/lambda >= 100 (got %.1f).', d_over_l);
end

g0   = 10*log10(eff*(pi*d_over_l)^2);
phi0 = 20*sqrt(3)/d_over_l;
phi2 = 10^((49 - g0)/25);

if pattern == "single"
    drop = 17; c = 32; far = [-10 -5 -10];
else
    drop = 20; c = 29; far = [-13 -8 -13];
end
phi1 = phi0*sqrt(drop/3);
if phi1 > phi2
    error('sa509_gain_rev1:breakpoints', 'phi1 (%.3f) exceeds phi2 (%.3f).', phi1, phi2);
end

g_dBi = zeros(size(phi_deg));
m = phi_deg < phi1;                     g_dBi(m) = g0 - 3*(phi_deg(m)/phi0).^2;
m = phi_deg >= phi1 & phi_deg < phi2;   g_dBi(m) = g0 - drop;
m = phi_deg >= phi2 & phi_deg < 48;     g_dBi(m) = c - 25*log10(phi_deg(m));
m = phi_deg >= 48 & phi_deg < 80;       g_dBi(m) = far(1);
m = phi_deg >= 80 & phi_deg < 120;      g_dBi(m) = far(2);
m = phi_deg >= 120;                     g_dBi(m) = far(3);
end
