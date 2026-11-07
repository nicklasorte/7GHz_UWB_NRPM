---
title: "Joint Assumptions Agreement: UWB Channel 9 Drones and Federal Space-to-Earth Receivers"
subtitle: "Markup form for NASA, NOAA, and USGS, Rev 0"
date: "November 7, 2026"
---

```
DRAFT - PRE-DECISIONAL AND DELIBERATIVE
Prepared with AI assistance. Reviewer: [CONFIRM]
Public and cleared sources only.
```

# How to use this form

This form lists the inputs that decide the analysis results. For each row, mark **Accept**, **Reject**, or **Replace**, and give a value and source when you replace one. Once both sides sign the frozen version, the analysis reruns on the agreed inputs, and both sides accept the outcome under the rules in the pre-registration protocol (`docs/preregistration_protocol_rev0.md`).

The full register, with links and sensitivities, is in `docs/assumptions_and_red_team_rev0.md`. IDs below match that register.

# Inputs that drive the result

| ID | Input | Proposed value | Source | Response (Accept / Reject / Replace) | Replacement value and source | Comment |
| --- | --- | --- | --- | --- | --- | --- |
| C1 | EESS long-term criterion | -150 dBW per 10 MHz, 20% of time | ITU-R SA.1027-6 Table 1 (terrestrial share) | | | |
| C2 | EESS short-term criterion | -133 dBW per 10 MHz, 0.005% of time | ITU-R SA.1027-6 Table 1 | | | |
| C5 | Share of the terrestrial budget available to UWB | Full share | Assumption | | | NASA may propose an apportionment (for example I/N = -20 dB) |
| C6 | Whether average-power criteria cover pulsed UWB | Yes, pending measurement | Assumption | | | See `docs/its_test_plan_rev0.md` |
| T1 | Percent of time basis | Share of dish tracking time | Assumption | | | Alternative: share of all time |
| V2 | NEN AS1 and WG1 G/T | 35.2 and 34.5 dB/K at 10° | NEN Users' Guide Rev 5, Table 2-1 | | | |
| V3 | 11.3 m gain and beamwidth | 57.5 dBi, 0.2° | NEN Users' Guide Rev 5, Table 3-3 (SG1) | | | |
| V7 | Off-axis pattern | ITU-R SA.509-3 envelopes | ITU-R SA.509-3 | | | Measured patterns, if available |
| V8 | Dish center height | 10 m | Assumption | | | |
| V9 | Minimum tracking elevation | 5° | ITU-R SA.1026-5 | | | Site horizon masks |
| V10 | Site shielding | 0 dB | Assumption | | | |
| PS1 | Missions tracked | Aqua, Terra, Landsat 8, Landsat 9 (priority in that order) | CelesTrak TLEs | | | Add or remove missions per site |
| PS2 | Dish pointing model | Tracks the highest-priority satellite in view; idle otherwise | Assumption | | | |
| P1 | Propagation model | ITU-R P.528-5 (NTIA reference, MATLAB port) | ITU-R P.528-5 | | | |
| P2 | Time variability | P.528 time percentage drawn uniformly from 1% to 99% per device | Assumption, mirrors ITM reliability randomization | | | |
| R3 | Highest drone altitude | 121.92 m (400 ft) | 14 CFR 107.51(b) | | | Test ranges near sites |
| R5 | Active drone density near the site | Swept 0.01-1 per km² | Open | | | |
| U1 | UWB EIRP | -41.3 dBm/MHz average | 47 CFR 15.519(c) | | | |
| U9 | Activity factor | Folded into active density | ECC Report 327 Table 18 | | | |
| U11 | UWB radios per drone | One | Assumption | | | |
| U12 | Polarization loss | 3 dB | Linear into circular | | | |
| B1 | Ground UWB baseline densities | 7 outdoor and 500 indoor active per km² (urban) | ECC Report 327 via FiRa (2025) | | | |
| B2 | Building entry loss for indoor UWB | 17 dB | ECC Report 327 / CEPT Report 84 | | | |

# Signatures

| Party | Name | Date | Signature |
| --- | --- | --- | --- |
| NTIA | | | |
| NASA | | | |
| NOAA (JPSS items) | | | |
| USGS (Landsat items) | | | |
