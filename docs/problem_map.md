# Problem map: UWB channel 9 drones into NASA EESS earth stations

DRAFT//PRE-DECISIONAL. Public sources only; see [sources.md](sources.md).

## The question

The FCC's UWB modernization NPRM (ET Docket No. 26-245, released October 1, 2026) asks whether to relax the § 15.521(a) ban on UWB aboard aircraft and whether to permit UWB drone navigation and landing systems. NASA is concerned that drones carrying IEEE 802.15.4 HRP UWB radios on channel 9 would interfere with its Earth Exploration-Satellite Service (EESS) X-band receive earth stations.

The NPRM asks commenters who support expanded use to supply propagation modeling, link budgets, and coexistence studies (paras. 29–30). This repo provides that analysis framework from the federal side.

## Why channel 9 matters

```
MHz   7700      7800      7900      8000      8100      8200      8300      8400
       |---------|---------|---------|---------|---------|---------|---------|
UWB ch 9      [7737.6 ======================= 7987.2 ======================= 8236.8]
               mask 0 dBr to ±324.5 MHz; -10 dBr to ±399.4 MHz; -18 dBr beyond
MetSat s-E      [7750 ===== 7900]                                   (NOAA, NGSO)
FSS/MSS E-s                    [7900 ==== 8025]               (satellite receives)
EESS s-E                                 [8025 ===================================== 8400]
In-channel EESS overlap                  [8025 ========== 8236.8]  = 211.8 MHz
```

- **EESS (space-to-Earth), 8025–8400 MHz.** NASA, NOAA, and USGS science downlinks (for example Aqua at 8160 MHz, Terra and Landsat at 8212.5 MHz). 211.8 MHz of the 375 MHz band sits inside channel 9 at the full −41.3 dBm/MHz. The rest of the band sees the mask skirt (−10 to −18 dBr).
- **MetSat (space-to-Earth), 7750–7900 MHz.** Fully inside channel 9. Europe already caps aircraft UWB here at −64.3 dBm/MHz below 1000 m (ECC/DEC/(12)03), 23 dB under the U.S. handheld limit.
- **7900–8025 MHz.** Uplink bands; the victim is a satellite, which is out of scope here.

## What makes drones different from handheld UWB

| Factor | Handheld UWB (today) | UWB on a drone |
| --- | --- | --- |
| Height | ~1.5 m, body and clutter shielded | Up to 121.92 m AGL (14 CFR 107.51) |
| Path to earth station | Usually terrain or clutter blocked | Line of sight out to ~58 km radio horizon |
| Elevation seen by the dish | Near 0°, deep sidelobes | 1°–10° within a few km, same as the dish's low-elevation passes |
| Coupling | Far sidelobe (−10 dBi) | Can fall in the main beam (57 dBi) or near sidelobes |
| Density | Indoor-heavy | Unknown; outdoor, clustered around ports, farms, logistics hubs |

The geometric core of the problem: an X-band EESS dish tracks LEO passes down to 5° elevation. A drone at 120 m is at 5° elevation from the dish at about 1.4 km. Anywhere in that ring, a single drone can sit in or near the main beam.

## Interference chain (what the model computes)

```
I (dBm/10 MHz) = EIRP_10MHz(f)      UWB EIRP in the victim 10 MHz (15.519 limit x PSD mask, SM.337 FDR)
               - FSPL(slant, f)      free space on LOS paths, 4/3 Earth geometry, dropped past the horizon
               + G_ES(phi)           ITU-R SA.509-3 (single-entry for one drone, multiple-entry for aggregate)
               - L_pol               3 dB, linear UWB into circular feed
               - L_shield            site shielding (0 dB default)
```

Aggregate: sum in mW over a Poisson field of active drones (uniform in area out to the horizon, uniform altitude 10–121.92 m) with a random dish azimuth, for every candidate geofence (exclusion) radius at once.

Criteria (10 MHz reference, at the antenna output):

| Band | Long term | Short term | Source |
| --- | --- | --- | --- |
| EESS 8025–8400 MHz | −150 dBW, ≤ 20% of time | −133 dBW, ≤ 0.005% | ITU-R SA.1027-6, terrestrial share |
| MetSat 7750–7900 MHz | −144 dBW, ≤ 20% | −127 dBW, ≤ 0.0125% | ITU-R SA.1026-5, aggregate |

Long-term runs use 13° dish elevation and short-term runs use 5° (SA.1026-5 Table 2).

## Outputs

1. Channel 9 EIRP per 10 MHz across 7.7–8.4 GHz with the protected bands (`fig1`).
2. Single hovering drone: interference vs. distance and required separation by altitude and dish elevation (`fig2`).
3. Aggregate margin vs. geofence radius for each active density (`fig3`), and the required radius table.
4. The EIRP that would protect the earth station with no geofence, compared with the European −64.3 dBm/MHz aircraft limit.

Results are in [results.md](results.md).

## Assumptions to resolve (TODO in `uwb_eess_params_rev1.m`)

| Parameter | Default | Why it matters | Who has the data |
| --- | --- | --- | --- |
| Active UWB drone density (density × duty) | swept 1e-3 to 1 per km² | Scales the long-term aggregate about 1:1 in dB | FAA UAS forecasts, NPRM commenters; NPRM para. 37–38 duty cycle (< 1% per 24 h) would cut this by ≥ 20 dB if adopted for drones |
| Dish aperture efficiency | 0.6 | ±1 dB on main-beam gain | NASA station specs |
| Dish height | 10 m | Horizon and elevation of near drones | NASA station specs |
| Site shielding | 0 dB | Fences and terrain can add 10–20 dB at low elevation | Site surveys |
| Feed polarization | circular (3 dB loss) | 0 dB if linear | NASA |
| UWB antenna pattern toward the horizon | isotropic at limit | NPRM floats downward-directed emissions (para. 29) | Manufacturers |
| Pointing statistics | fixed 13°/5°, random azimuth | Real LEO pass statistics spread elevation; short-term risk rises with time spent at low elevation | Mission pass schedules |
| Propagation beyond LOS | dropped | Optimistic only for drones past the horizon, which contribute little | ITU-R P.528, ITM with terrain |
| IEEE 802.15.4 mask breakpoints | 0.65/0.8 per Tp | Out-of-channel EESS (8236.8–8400 MHz) | IEEE Std 802.15.4-2020 |
| Peak (50 MHz) limit | not modeled | Pulse peak effects on demodulators | Measurement (NTIA ITS 7 GHz UWB testing, NPRM fn. 40) |

## Mitigations to test with the model

- **Geofence radius** around each earth station (the `r_req` output).
- **Channel restriction** (exclude channel 9 near earth stations, or nationwide for airborne use; channel 5 at 6489.6 MHz avoids EESS X-band).
- **Altitude cap** for UWB transmissions (re-run with `p.drone.h_max_m`).
- **EIRP reduction** in 7750–7900 and 8025–8400 MHz, mirroring ECC/DEC/(12)03.
- **Duty-cycle cap** (NPRM paras. 37–38) applied as active density.
- **Downward-directed antennas** (`p.uwb.eirp_offset_dB`).
