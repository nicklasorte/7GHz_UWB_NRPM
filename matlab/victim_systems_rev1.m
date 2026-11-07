function v = victim_systems_rev1()
%VICTIM_SYSTEMS_REV1 Candidate NASA-related space-to-Earth receive systems inside UWB channel 9.
%   v = VICTIM_SYSTEMS_REV1() returns a table, one row per victim earth
%   station. Values are from public documents (see docs/sources.md); NaN
%   marks a parameter no public source gives, and the "todo" column says
%   what is missing. Allocations: NTIA, Spectrum Needs of U.S. Space-based
%   Operations, Appendix "Allocations and Systems" (July 2021).
%
%   Columns
%     name, service, band_MHz (1x2), f_MHz, rx_bw_MHz, diam_m, eff,
%     g_over_t_dBK, tsys_K, pol, el_min_deg, ebno_req_dB, margin_min_dB,
%     users, source, todo
%
%   Antenna gain G0 = 10 log10(eff (pi D / lambda)^2) (ITU-R SA.509-3 1.3).
%   When G/T is published, Tsys is derived as G0 - G/T.

c = physconst('LightSpeed');

% 1. JPSS High Rate Data (HRD) direct-broadcast terminal, MetSat (space-to-Earth)
%    JPSS-1 HRD to DBS RF ICD Rev A (470-REF-00184, 2015-02-09): 7812 MHz, 30 MHz assigned
%    bandwidth, QPSK, RHCP, 15 Mbps, 3 m reference antenna, G/T 22.7 dB/K at 5 deg,
%    Eb/N0 required 4.4 dB, 1 dB minimum margin. NOAA OSPO: 47 HRD users; 25 Mbps from NOAA-21.
r(1).name = "JPSS HRD direct-broadcast terminal (3 m)";
r(1).service = "MetSat (space-to-Earth)";
r(1).band_MHz = [7750 7900];
r(1).f_MHz = 7812;
r(1).rx_bw_MHz = 30;
r(1).diam_m = 3;
r(1).eff = 0.6;          % TODO aperture efficiency not in the ICD; used only to split G/T into G0 and Tsys
r(1).g_over_t_dBK = 22.7;
r(1).tsys_K = NaN;       % derived below from G/T
r(1).pol = "RHCP";
r(1).el_min_deg = 5;
r(1).ebno_req_dB = 4.4;
r(1).margin_min_dB = 1;
r(1).users = "47 registered HRD users (NOAA OSPO); NASA Direct Readout Laboratory";
r(1).source = "JPSS-1 HRD-DBS RF ICD Rev A; NOAA OSPO HRD page";
r(1).todo = "Aperture efficiency; site list and antenna heights of U.S. HRD terminals";

% 2. NASA Near Earth / Near Space Network 11.3 m X-band EESS data-downlink antenna
%    Aqua (8160 MHz) and Terra (8212.5 MHz) science downlinks; NEN 11.3 m at ASF Fairbanks.
r(2).name = "NASA NEN 11.3 m EESS data downlink (Aqua/Terra/Aura)";
r(2).service = "EESS (space-to-Earth)";
r(2).band_MHz = [8025 8400];
r(2).f_MHz = 8160;
r(2).rx_bw_MHz = NaN;    % TODO receiver/IF bandwidth per mission
r(2).diam_m = 11.3;
r(2).eff = 0.6;          % TODO
r(2).g_over_t_dBK = NaN; % TODO NEN X-band G/T
r(2).tsys_K = NaN;
r(2).pol = "RHCP";       % TODO confirm per mission
r(2).el_min_deg = 5;
r(2).ebno_req_dB = NaN;
r(2).margin_min_dB = NaN;
r(2).users = "NEN sites: Fairbanks AK, Wallops VA; commercial NEN: North Pole AK, South Point HI";
r(2).source = "NEN station list; NTIA space-spectrum inventory appendix (2021)";
r(2).todo = "G/T, receiver bandwidth, required Eb/N0, link margin per mission";

% 3. Landsat 8/9 X-band (USGS operations, NASA-built) at USGS EROS, Sioux Falls SD, 10 m
%    USGS: 384 Mbps in the 375 MHz X-band allocation, rate-7/8 LDPC; EROS 10 m antenna.
r(3).name = "Landsat 8/9 X-band at USGS EROS (10 m)";
r(3).service = "EESS (space-to-Earth)";
r(3).band_MHz = [8025 8400];
r(3).f_MHz = 8212.5;     % band center; Landsat 8/9 fills the 375 MHz allocation
r(3).rx_bw_MHz = 375;
r(3).diam_m = 10;
r(3).eff = 0.6;          % TODO
r(3).g_over_t_dBK = NaN; % TODO
r(3).tsys_K = NaN;
r(3).pol = "RHCP";       % TODO confirm
r(3).el_min_deg = 5;
r(3).ebno_req_dB = NaN;
r(3).margin_min_dB = NaN;
r(3).users = "USGS EROS (Sioux Falls SD), Gilmore Creek AK (NOAA), plus international sites";
r(3).source = "USGS Landsat ground stations; USGS pubs 70193004";
r(3).todo = "G/T, Tsys, required Eb/N0, link margin, exact center frequency";

v = struct2table(r);
lambda = c ./ (v.f_MHz*1e6);
v.g0_dBi = 10*log10(v.eff .* (pi*v.diam_m./lambda).^2);
v.d_over_lambda = v.diam_m ./ lambda;
known = ~isnan(v.g_over_t_dBK);
v.tsys_K(known) = 10.^((v.g0_dBi(known) - v.g_over_t_dBK(known))/10);
end
