function g_dBi = f699_gain_rev1(phi_deg, diam_m, f_MHz, eff)
%F699_GAIN_REV1 Reference antenna pattern of ITU-R F.699-5 for D/lambda <= 100.
%   g_dBi = F699_GAIN_REV1(phi_deg, diam_m, f_MHz, eff) returns the gain at
%   off-axis angle phi_deg (0-180 deg) for an antenna too small for
%   ITU-R SA.509-3 (which needs D/lambda >= 100), such as a 2.4 m
%   direct-broadcast dish at 8 GHz (D/lambda about 65).
%
%   Recommendation ITU-R F.699-5 (05/2000), recommends 2.2 (D/lambda <= 100):
%     G = Gmax - 2.5e-3 (D/lambda phi)^2          0 < phi < phi_m
%     G = G1 = 2 + 15 log10(D/lambda)            phi_m <= phi < 100 lambda/D
%     G = 52 - 10 log10(D/lambda) - 25 log10 phi 100 lambda/D <= phi < 48 deg
%     G = 10 - 10 log10(D/lambda)                48 deg <= phi <= 180 deg
%     phi_m = 20 lambda/D sqrt(Gmax - G1)
%   Gmax = 10 log10(eta (pi D/lambda)^2), as in ITU-R SA.509-3 sec. 1.3.
%   Source: https://www.itu.int/rec/R-REC-F.699/en
%
%   F.699 is a peak-envelope pattern written for line-of-sight fixed
%   service antennas. Using it for a small earth station is an assumption:
%   it overstates aggregate side-lobe gain compared with an average pattern
%   such as the SA.509-3 "multiple" case, so results are conservative.
arguments
    phi_deg double {mustBeGreaterThanOrEqual(phi_deg, 0), mustBeLessThanOrEqual(phi_deg, 180)}
    diam_m (1,1) double {mustBePositive}
    f_MHz (1,1) double {mustBePositive}
    eff (1,1) double {mustBePositive, mustBeLessThanOrEqual(eff, 1)}
end
lambda_m = physconst('LightSpeed') / (f_MHz * 1e6);
dl = diam_m / lambda_m;
if dl > 100
    error('f699_gain_rev1:largeAntenna', 'Use ITU-R SA.509-3 for D/lambda > 100 (got %.1f).', dl);
end
g_max = 10 * log10(eff * (pi * dl)^2);
g1 = 2 + 15 * log10(dl);
if g_max <= g1
    error('f699_gain_rev1:breakpoints', 'Gmax (%.2f dBi) must exceed G1 (%.2f dBi).', g_max, g1);
end
phi_m = 20 / dl * sqrt(g_max - g1);
phi_r = 100 / dl;
g_dBi = zeros(size(phi_deg));
m = phi_deg < phi_m;                    g_dBi(m) = g_max - 2.5e-3 * (dl * phi_deg(m)).^2;
m = phi_deg >= phi_m & phi_deg < phi_r; g_dBi(m) = g1;
m = phi_deg >= phi_r & phi_deg < 48;    g_dBi(m) = 52 - 10 * log10(dl) - 25 * log10(phi_deg(m));
m = phi_deg >= 48;                      g_dBi(m) = 10 - 10 * log10(dl);
end
