function v = victim_systems_rev2()
%VICTIM_SYSTEMS_REV2 Candidate federal space-to-Earth receivers in UWB channel 9, with NEN station data.
%   v = VICTIM_SYSTEMS_REV2() returns one row per victim earth station.
%   rev2 replaces the generic NEN row of VICTIM_SYSTEMS_REV1 with the two
%   NASA-operated U.S. 11.3 m X-band antennas in the NEN Users' Guide,
%   453-NENUG Rev 5 (2020), Table 2-1: AS1 (Fairbanks, Alaska Satellite
%   Facility) and WG1 (Wallops). G/T values there are estimates at 10 deg
%   elevation. The 11.3 m X-band gain (57.5 dBi) and 3 dB beamwidth
%   (0.2 deg typical) are from the same guide, Table 3-3 (Svalbard SG1,
%   11.3 m); the guide doesn't tabulate them for AS1 or WG1, so they are
%   applied by antenna size and marked in the todo column.
%
%   Tsys is derived as G0 - G/T, with G0 = g0_pub_dBi where published,
%   otherwise 10 log10(eff (pi D/lambda)^2) (ITU-R SA.509-3, sec. 1.3).
%
%   Columns: name, site, service, band_MHz, f_MHz, rx_band_MHz, rx_bw_MHz,
%   diam_m, eff, g0_pub_dBi, bw3db_pub_deg, g_over_t_dBK, gt_el_deg, pol,
%   el_min_deg, lat_deg, lon_deg, source, todo, and derived g0_calc_dBi,
%   g0_dBi, bw3db_calc_deg, tsys_K.

nen = "NASA, Near Earth Network (NEN) Users' Guide, 453-NENUG Rev 5 (2020), Tables 2-1 and 3-3";

r(1) = row("JPSS HRD direct-broadcast terminal (3 m)", "Any HRD user site", ...
    "MetSat (space-to-Earth)", [7750 7900], 7812, [NaN NaN], 30, 3, 0.6, NaN, NaN, 22.7, 5, "RHCP", 5, NaN, NaN, ...
    "JPSS-1 HRD-DBS RF ICD Rev A (2015), Tables 4-1 and A; NOAA OSPO HRD page", ...
    "Aperture efficiency (used only to split G/T); U.S. HRD site list and antenna heights");

r(2) = row("NASA NEN AS1, 11.3 m, Fairbanks AK", "Alaska Satellite Facility, Fairbanks", ...
    "EESS (space-to-Earth)", [8025 8400], 8160, [8025 8500], NaN, 11.3, 0.6, 57.5, 0.2, 35.2, 10, "RHC/LHC", 5, 64.8587, -147.8576, ...
    nen, "Gain/beamwidth taken from SG1 (same size); receiver bandwidth; horizon mask; antenna height; measured pattern");

r(3) = row("NASA NEN WG1, 11.3 m, Wallops VA", "Wallops Flight Facility", ...
    "EESS (space-to-Earth)", [8025 8400], 8160, [8000 8500], NaN, 11.3, 0.6, 57.5, 0.2, 34.5, 10, "RHC/LHC", 5, 37.9249, -75.4765, ...
    nen, "Gain/beamwidth taken from SG1 (same size); receiver bandwidth; horizon mask; antenna height; measured pattern");

r(4) = row("Landsat 8/9 X-band at USGS EROS (10 m)", "USGS EROS, Sioux Falls SD", ...
    "EESS (space-to-Earth)", [8025 8400], 8212.5, [NaN NaN], 375, 10, 0.6, NaN, NaN, NaN, NaN, "RHCP", 5, NaN, NaN, ...
    "USGS Landsat ground stations; USGS publication 70193004", ...
    "G/T, Tsys, required Eb/N0, link margin, exact center frequency, polarization, radome loss");

v = struct2table(r);
lambda = physconst('LightSpeed') ./ (v.f_MHz*1e6);
v.g0_calc_dBi = 10*log10(v.eff .* (pi*v.diam_m./lambda).^2);
v.g0_dBi = v.g0_pub_dBi;
v.g0_dBi(isnan(v.g0_dBi)) = v.g0_calc_dBi(isnan(v.g0_dBi));
v.bw3db_calc_deg = 2*20*sqrt(3) ./ (v.diam_m./lambda);   % 2*phi0, ITU-R SA.509-3
v.tsys_K = 10.^((v.g0_dBi - v.g_over_t_dBK)/10);         % NaN where G/T unknown
end

function s = row(name, site, service, band, f, rx_band, rx_bw, d, eff, g0p, bwp, gt, gt_el, pol, el_min, lat, lon, src, todo)
s = struct('name', name, 'site', site, 'service', service, 'band_MHz', band, 'f_MHz', f, ...
    'rx_band_MHz', rx_band, 'rx_bw_MHz', rx_bw, 'diam_m', d, 'eff', eff, 'g0_pub_dBi', g0p, ...
    'bw3db_pub_deg', bwp, 'g_over_t_dBK', gt, 'gt_el_deg', gt_el, 'pol', pol, 'el_min_deg', el_min, ...
    'lat_deg', lat, 'lon_deg', lon, 'source', src, 'todo', todo);
end
