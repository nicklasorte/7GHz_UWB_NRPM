function p = uwb_eess_params_rev1()
%UWB_EESS_PARAMS_REV1 Baseline inputs for drone-borne UWB channel 9 into EESS/MetSat earth stations.
%   p = UWB_EESS_PARAMS_REV1() returns a struct of every input used by the
%   analysis. Each value cites its public source. Values with no
%   authoritative source are marked TODO and are swept in the main script.
%
%   Sources are listed in full in docs/sources.md.

p = struct();

%% UWB transmitter (IEEE 802.15.4 HRP channel 9)
p.uwb.fc_MHz            = 7987.2;   % IEEE 802.15.4 HRP ch 9 center; also FCC ET Docket 26-245 NPRM fn 63
p.uwb.bw_MHz            = 499.2;    % IEEE 802.15.4 HRP ch 9 bandwidth (7737.6-8236.8 MHz)
p.uwb.chip_rate_MHz     = 499.2;    % 1/Tp for ch 9, used by the transmit PSD mask
p.uwb.eirp_dBm_per_MHz  = -41.3;    % 47 CFR 15.519(c), 3100-10600 MHz, average EIRP in 1 MHz
p.uwb.peak_dBm_50MHz    = 0;        % 47 CFR 15.519(e), peak EIRP in 50 MHz (not used by the average-power model)
p.uwb.mask_type         = "ieee802154"; % "ieee802154" (device mask) or "flat" (FCC envelope, worst case)
% IEEE 802.15.4 HRP transmit PSD mask: -10 dBr for 0.65/Tp < |f-fc| < 0.8/Tp, -18 dBr beyond 0.8/Tp.
% TODO verify breakpoints against IEEE Std 802.15.4-2020, HRP UWB PHY transmit PSD mask clause.
p.uwb.mask_offset_x_chip = [0.65 0.80];
p.uwb.mask_level_dBr     = [-10 -18];
p.uwb.eirp_offset_dB     = 0;       % TODO extra reduction toward the ES (e.g., downward-directed antenna, ET 26-245 NPRM para 29). 0 = isotropic at the limit
p.uwb.mean_prf_MHz       = [62.4 124.8 249.6]; % IEEE 802.15.4z HRP: BPRF 62.4 MHz, HPRF 124.8/249.6 MHz (MathWorks lrwpanHRPConfig doc, IEEE 802.15.4-2020)
p.uwb.peak_prf_MHz       = 499.2;   % chip rate inside a burst
p.uwb.t_on_ms            = [0.1 0.25 1]; % TODO packet (burst-on) duration within a 1 ms window; no public drone-UWB value, swept
p.uwb.activity_pct       = [0.25 1 5];   % ECC Report 327 Table 18 activity factors (parking 0.25%, indoor/outdoor 1%, vehicle fixed 5%), via FiRa 2025 report
p.uwb.pol_loss_dB        = 3;      % linear UWB antenna into circularly polarized ES feed: cos^2(45 deg) = 3 dB. TODO confirm ES feed polarization per station

%% Drone
p.drone.h_min_m = 10;               % TODO lowest operating altitude AGL of interest
p.drone.h_max_m = 400*0.3048;       % 14 CFR 107.51(b): 400 ft AGL = 121.92 m

%% EESS / MetSat earth station
p.es.diam_m          = 11.3;        % NASA NEN 11.3 m S/X-band antenna (Alaska Satellite Facility, Fairbanks)
p.es.eff             = 0.6;         % TODO aperture efficiency (ITU-R SA.509-3 leaves eta unspecified)
p.es.h_m             = 10;          % TODO antenna center height above local ground
p.es.el_min_deg      = 5;           % ITU-R SA.1026-5 / SA.1027-6: 5 deg minimum operational elevation
p.es.el_long_deg     = 13;          % ITU-R SA.1026-5 Table 2: elevation for the 20% (long-term) case, 8025-8400 MHz
p.es.el_short_deg    = 5;           % ITU-R SA.1026-5 Table 2: elevation for the short-term case
p.es.site_shield_dB  = 0;           % TODO terrain or fence shielding at the site (0 = none)
p.es.tsys_K          = 150;         % TODO placeholder; ECC Report 175 Table 17 MetSat ES value, used only to express criteria as I/N
p.es.f_victim_MHz    = 8100;        % EESS downlink inside ch 9 overlap (8025-8236.8 MHz), e.g., Aqua 8160 MHz, Landsat/Terra 8212.5 MHz

%% Protection criteria (per reference bandwidth, at the ES antenna output)
p.crit.ref_bw_MHz = 10;
p.crit.table = table( ...
    [7750; 8025], [7900; 8400], ...
    [-144; -150], [20; 20], ...
    [-127; -133], [0.0125; 0.005], ...
    ["ITU-R SA.1026-5 Table 1, MetSat 7750-7900 MHz (aggregate, all sources)"; ...
     "ITU-R SA.1027-6 Table 1, EESS 8025-8400 MHz (terrestrial-path share)"], ...
    'VariableNames', {'f_lo_MHz','f_hi_MHz','long_dBW','long_pct','short_dBW','short_pct','source'});

%% Propagation
p.prop.k_factor = 4/3;              % median effective Earth radius factor (ITU-R P.452 / P.453 standard atmosphere)
p.prop.re_km    = 6371;             % mean Earth radius
% Free-space loss on line-of-sight paths; paths beyond the smooth-Earth radio horizon are dropped.
% TODO replace with ITU-R P.528 (air-to-ground) and add terrain via ITM for site-specific runs.

%% Monte Carlo
p.mc.n_iter = 2e5;                  % >= 2e4 needed so prctile resolves the 0.005% tail (n*p/100 >= 1); 2e5 gives ~10 tail samples
p.mc.chunk  = 5000;
p.mc.seed   = 20261107;
p.mc.r_edges_km = [0:0.1:5, 5.5:0.5:20, 21:1:60];   % exclusion-radius grid
p.mc.density_active_per_km2 = [1e-3 1e-2 1e-1 1];  % TODO active UWB drones per km^2 (density x activity); no public forecast, swept
end
