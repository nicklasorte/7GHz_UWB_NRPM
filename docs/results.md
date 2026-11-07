# Results (rev1 code, run on MATLAB R2025b)

DRAFT//PRE-DECISIONAL. Inputs are the defaults in `matlab/uwb_eess_params_rev1.m` and `matlab/victim_systems_rev1.m`. Rerun `simplified_main_beam_rev1.m` and `main_uwb_ch9_eess_rev1.m` to regenerate. Figures are in `docs/figures/` when present, and always in `output/` after a run.

## Simplified main-beam analysis (`simplified_main_beam_rev1.m`)

One drone, LOS, on boresight, free space, -31.3 dBm per 10 MHz, 3 dB polarization loss.

| Victim | G0 (dBi) | Tsys (K) | Long-term (km) | Short-term (km) | Short-term, in-packet +7.3 dB (km) | I/N -6 dB (km) | I/N -10 dB (km) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| JPSS HRD, 3 m, 7812 MHz | 45.59 | 194 | 5.61 | 0.79 | 1.84 | 4.31 | 6.84 |
| NASA NEN, 11.3 m, 8160 MHz | 57.48 | TODO | 42.18 | 5.96 | 13.84 | - | - |
| Landsat EROS, 10 m, 8212.5 MHz | 56.48 | TODO | 37.33 | 5.27 | 12.25 | - | - |

- A 121.92 m drone can be on a 5° boresight only within 1.28 km (0.485 km at 13°).
- Height above the dish needed at the long-term distance (5° / 13°): JPSS 493 m / 1,298 m; NEN 3,795 m / 9,842 m; Landsat 3,348 m / 8,699 m.
- Excess over the long-term criterion at the geometric limit (5° / 13°): JPSS 12.8 / 21.0 dB; NEN 30.3 / 38.6 dB; Landsat 29.3 / 37.5 dB.

UWB emission inside each receiver bandwidth (in-channel):

| Bandwidth (MHz) | Average (dBm) | In-packet, 0.1 ms (dBm) | Peak envelope (dBm) | Allowed PAR (dB) | Regime at BPRF 62.4 MHz | First-order PAR, BPRF / HPRF 249.6 (dB) |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | -41.3 | -34.0 | -34.0 | 7.3 | noise-like | 0 / 0 |
| 10 | -31.3 | -24.0 | -14.0 | 17.3 | noise-like | 0 / 0 |
| 30 | -26.5 | -19.2 | -4.4 | 22.1 | noise-like | 0 / 0 |
| 375 | -15.6 | -8.2 | 17.5 (extrapolated) | 33.1 | pulse-resolved | 7.8 / 1.8 |

## Single drone with the SA.509-3 pattern (`main_uwb_ch9_eess_rev1.m`, NEN 11.3 m, 8100 MHz)

Long-term separation (km), drone in the dish azimuth:

| Altitude | el 5° | el 13° | el 30° |
| --- | --- | --- | --- |
| 30 m | 0.58 | 0.20 | 0.08 |
| 60 m | 0.96 | 0.34 | 0.14 |
| 121.92 m | 1.71 | 0.63 | 0.25 |

Short-term separation (km): 30 m 0.30 / 0.11 / 0.05; 60 m 0.65 / 0.25 / 0.10; 121.92 m 1.35 / 0.52 / 0.21. MetSat 7800 MHz long-term at 121.92 m: 1.53 / 0.57 / 0.23 km.

## Aggregate Monte Carlo (`main_uwb_ch9_eess_rev1.m`)

Long term: 13° pointing, 20,000 iterations. Short term: 5° pointing, 200,000 iterations. Radio horizon 58.55 km.

| Active drones per km² | Required radius (km) | Margin at r = 0, long (dB) | Margin at r = 0, short (dB) | Highest EIRP with no geofence (dBm/MHz) |
| --- | --- | --- | --- | --- |
| 0.001 | 0 | -49.2 | -20.2 | -41.3 |
| 0.01 | 0 | -37.7 | -10.4 | -41.3 |
| 0.1 | 0.3 | -26.6 | +4.0 | -45.3 |
| 1 | 1.3 | -15.3 | +15.0 | -56.3 |

Checks: 11 of 11 unit tests pass; Code Analyzer clean apart from a suppressed constant-switch warning; Python recomputation of the main-beam distances matches to the reported precision.

## Red-team sensitivity (`red_team_sensitivity_rev1.m`, NEN WG1 Wallops: 57.5 dBi, 34.5 dB/K, 200 K, 8160 MHz)

| Case | Margin change (dB) | Main-beam long (km) | Main-beam short (km) | Single sep el 5° (km) | Single sep el 13° (km) | Boresight ring el 5° (km) |
| --- | --- | --- | --- | --- | --- | --- |
| Baseline | 0 | 42.26 | 5.97 | 1.71 | 0.62 | 1.28 |
| No polarization credit | +3 | 59.69 | 8.43 | 1.85 | 0.67 | 1.28 |
| Ground reflection | +6 | 84.32 | 11.91 | 2.05 | 0.73 | 1.28 |
| Two radios per drone | +3 | 59.69 | 8.43 | 1.85 | 0.67 | 1.28 |
| Four radios per drone | +6 | 84.32 | 11.91 | 2.05 | 0.73 | 1.28 |
| In-packet power, short term | +7.3 (short) | 42.26 | 13.87 | 1.71 | 0.62 | 1.28 |
| Apportioned I/N = -20 dB (-125.6 dBm/10 MHz) | +5.6 | 80.52 | 5.97 | 2.02 | 0.72 | 1.28 |
| Structure exception, 243.84 m | 0 | 42.26 | 5.97 | 3.15 | 1.17 | 2.67 |
| 8350 MHz, IEEE mask (-10 dBr) | -10 | 13.06 | 1.84 | 1.44 | 0.54 | 1.28 |
| 8350 MHz, FCC envelope | 0 | 41.30 | 5.83 | 1.70 | 0.62 | 1.28 |
| Combined skeptic case | +17.6 | 320.54 | 55.20 | 5.40 | 1.86 | 2.67 |
