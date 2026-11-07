# 7GHz_UWB_NRPM

Analysis of drone-borne IEEE 802.15.4 HRP UWB, channel 9 (7737.6-8236.8 MHz), into federal space-to-Earth receivers: NASA EESS (8025-8400 MHz) and JPSS/MetSat (7750-7900 MHz). Supports review of the FCC UWB modernization NPRM, ET Docket No. 26-245.

DRAFT//PRE-DECISIONAL. Public sources only.

## Start here

- [Working paper (Markdown)](docs/working_paper_uwb_ch9_eess_rev0.md), also as `docs/working_paper_uwb_ch9_eess_rev0.docx`
- [Assumptions register and NASA red-team review](docs/assumptions_and_red_team_rev0.md), also as `.docx`
- [Results](docs/results.md), including the next-steps analysis (P.528, real passes, ground UWB baseline, mitigations, risk)
- Agreement path with NASA: [joint assumptions agreement](docs/joint_assumptions_agreement_rev0.md), [pre-registration protocol](docs/preregistration_protocol_rev0.md), [NTIA ITS test plan](docs/its_test_plan_rev0.md)
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
| Combined NASA-skeptic case, single drone at 243.84 m | 5.4 km separation at 5° pointing |

## MATLAB (R2025b)

```matlab
cd matlab
simplified_main_beam_rev1      % bounding LOS main-beam distances + pulse metrics
main_uwb_ch9_eess_rev1         % single-entry and aggregate Monte Carlo (about 5 minutes)
red_team_sensitivity_rev1      % NASA-skeptic sensitivity cases for NEN WG1 (Wallops)
next_steps_analysis_rev1       % P.528 loss, SGP4 pass statistics, ground UWB baseline, mitigation menu, risk (about 15 minutes)
runtests('tests/test_uwb_eess_rev1.m')
```

| File | Purpose |
| --- | --- |
| `uwb_eess_params_rev1.m` | All inputs, each with its source or a TODO |
| `victim_systems_rev1.m` | JPSS HRD, generic NASA NEN, and Landsat receive parameters |
| `victim_systems_rev2.m` | Adds NEN AS1 (Fairbanks) and WG1 (Wallops) from the NEN Users' Guide |
| `red_team_sensitivity_rev1.m` | One-at-a-time and combined skeptic cases |
| `p528_loss_table_rev1.m` | Cached ITU-R P.528-5 loss table and interpolant (needs [itu_p528](https://github.com/nicklasorte/itu_p528) cloned next to this repo) |
| `pass_statistics_rev1.m` | Dish pointing time series from SGP4 passes (Aqua, Terra, Landsat 8/9) |
| `aggregate_drone_mc_rev2.m` | Monte Carlo with P.528 loss, random time percentage per device, real pointing, and device populations |
| `single_entry_p528_rev1.m` | Single-drone separation with P.528 loss |
| `p2108_terrestrial_clutter_rev1.m` | ITU-R P.2108-1 sec. 3.2 clutter for ground UWB devices |
| `next_steps_analysis_rev1.m` | Runs the next-steps analysis |
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
