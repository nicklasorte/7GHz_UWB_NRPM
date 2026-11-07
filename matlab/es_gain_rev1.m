function [g_dBi, src] = es_gain_rev1(phi_deg, diam_m, f_MHz, eff, pattern)
%ES_GAIN_REV1 Earth station antenna gain, choosing the reference pattern by antenna size.
%   [g_dBi, src] = ES_GAIN_REV1(phi_deg, diam_m, f_MHz, eff, pattern) returns
%   the ITU-R SA.509-3 gain (pattern "single" or "multiple") when
%   D/lambda >= 100, and the ITU-R F.699-5 envelope otherwise (pattern is
%   then ignored; F.699 has one envelope). src names the pattern used.
arguments
    phi_deg double
    diam_m (1,1) double {mustBePositive}
    f_MHz (1,1) double {mustBePositive}
    eff (1,1) double {mustBePositive, mustBeLessThanOrEqual(eff, 1)}
    pattern (1,1) string {mustBeMember(pattern, ["single", "multiple"])} = "multiple"
end
dl = diam_m / (physconst('LightSpeed') / (f_MHz * 1e6));
if dl >= 100
    g_dBi = sa509_gain_rev1(phi_deg, diam_m, f_MHz, eff, pattern);
    src = "ITU-R SA.509-3 (" + pattern + ")";
else
    g_dBi = f699_gain_rev1(phi_deg, diam_m, f_MHz, eff);
    src = "ITU-R F.699-5 (D/lambda <= 100)";
end
end
