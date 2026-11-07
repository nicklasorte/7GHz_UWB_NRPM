# 7GHz_UWB_NRPM

Analysis of drone-borne IEEE 802.15.4 HRP UWB, channel 9 (7737.6-8236.8 MHz), into federal space-to-Earth receivers: NASA EESS (8025-8400 MHz) and JPSS/MetSat (7750-7900 MHz). Supports review of the FCC UWB modernization NPRM, ET Docket No. 26-245.

DRAFT//PRE-DECISIONAL. Public sources only.

## Start here

- [Working paper (Markdown)](docs/working_paper_uwb_ch9_eess_rev0.md), also as `docs/working_paper_uwb_ch9_eess_rev0.docx`
- [Results](docs/results.md)
- [Problem map](docs/problem_map.md)
- [Sources](docs/sources.md)

## Headline numbers

| Question | Answer |
| --- | --- |
| Free-space distance for one main-beam drone to reach the long-term criterion | 42 km (NASA NEN 11.3 m), 37 km (Landsat 10 m), 6 km (JPSS HRD 3 m) |
| Where a 400 ft drone can actually be on boresight | Within 1.28 km (5° pass) or 0.48 km (13° pass) |
| Excess there | 30 dB (NEN), 29 dB (Landsat), 13 dB (JPSS) at 5° |
| Single hovering drone, real antenna pattern, 121.92 m | 1.7 km separation at 5° pointing |
| Aggregate geofence for the short-term criterion | 0.3 km at 0.1 active drones/km², 1.3 km at 1/km² |

## MATLAB (R2025b)

```matlab
cd matlab
simplified_main_beam_rev1      % bounding LOS main-beam distances + pulse metrics
main_uwb_ch9_eess_rev1         % single-entry and aggregate Monte Carlo (about 5 minutes)
runtests('tests/test_uwb_eess_rev1.m')
```

| File | Purpose |
| --- | --- |
| `uwb_eess_params_rev1.m` | All inputs, each with its source or a TODO |
| `victim_systems_rev1.m` | JPSS HRD, NASA NEN, and Landsat receive parameters |
| `uwb_power_in_band_rev1.m` | UWB EIRP in a victim bandwidth (IEEE mask or FCC envelope) |
| `uwb_pulse_metrics_rev1.m` | Average, in-packet, and peak power; noise-like vs. pulse-resolved |
| `main_beam_distance_rev1.m` | Free-space boresight distance and the height needed to be on boresight |
| `sa509_gain_rev1.m` | ITU-R SA.509-3 single- and multiple-entry patterns |
| `air_to_ground_geometry_rev1.m` | Slant range, elevation, and horizon on a 4/3 Earth |
| `uwb_to_es_interference_rev1.m` | Single-drone link budget |
| `single_entry_separation_rev1.m` | Separation sweep for one drone |
| `aggregate_drone_mc_rev1.m` | Poisson Monte Carlo aggregate vs. geofence radius |
| `required_exclusion_radius_rev1.m` | Smallest passing radius |
| `eess_criteria_rev1.m` | ITU-R SA.1026-5 / SA.1027-6 criteria lookup |
