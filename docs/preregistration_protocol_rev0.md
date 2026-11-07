---
title: "Pre-registered Analysis Protocol: UWB Channel 9 Drones and EESS Earth Stations"
subtitle: "Rev 0"
date: "November 7, 2026"
---

```
DRAFT - PRE-DECISIONAL AND DELIBERATIVE
Prepared with AI assistance. Reviewer: [CONFIRM]
```

# Purpose

This protocol fixes the questions, inputs, method, and decision rules before the final runs, the way a clinical trial registers its endpoints before it unblinds. If NTIA and NASA agree to it in advance, both accept the result whichever way it falls, and neither side can tune the method after seeing the numbers.

# Questions

1. With the agreed inputs, what share of dish tracking time does aggregate UWB drone interference exceed the ITU-R SA.1027-6 long-term (20%) and short-term (0.005%) criteria at each NEN site?
2. What geofence radius, altitude cap, EIRP limit, or duty-cycle limit, alone or combined, brings both exceedances within the criteria?
3. How much does drone UWB add to the interference from ground UWB devices already permitted near the site?

# Fixed inputs

The inputs are the frozen version of `docs/joint_assumptions_agreement_rev0.md`. No input changes after the freeze except by a signed amendment that records the reason.

# Method

1. **Propagation:** ITU-R P.528-5 using the validated MATLAB port (`github.com/nicklasorte/itu_p528`, a named commit), with the time percentage drawn uniformly from 1% to 99% for each device in each iteration.
2. **Pointing:** SGP4 passes from CelesTrak elements at a named epoch, over 30 days or more, sampled at 20 s or finer; the dish tracks the highest-priority mission in view above the agreed minimum elevation.
3. **Interference:** EIRP in the 10 MHz reference bandwidth, ITU-R SA.509-3 multiple-entry pattern, agreed polarization and shielding losses, power sum over all devices.
4. **Monte Carlo:** Poisson device counts, at least 100,000 iterations for each short-term result (at least 5 samples beyond the 0.005% point), fixed seeds recorded in the results.
5. **Code:** the commit SHA of `nicklasorte/7GHz_UWB_NRPM` used for the runs is recorded, and the full test suite must pass at that commit.

# Decision rules (set before the runs)

| Outcome at a site | Conclusion |
| --- | --- |
| Both criteria met at the agreed upper-bound density with no geofence | No site-specific condition needed for that site |
| Both criteria met only with a geofence of radius R | Condition: no airborne UWB on channels 9 and 10 within R of the site |
| Criteria met only with an EIRP, altitude, or duty-cycle limit | Condition: the smallest such limit that meets both criteria |
| Criteria not met by any tested condition | Channel 9 (and 10) excluded for airborne UWB |
| Measurement (ITS test plan) shows the demodulator fails at average levels below the ITU-R criteria | Criteria tightened by the measured margin, then rerun |

# Reporting

The report gives every number with its seed, commit, and input version; plots the full distributions, not only percentiles; and reports results that fail the criteria as fully as results that pass.

# Amendments

| Date | Change | Reason | Signed by |
| --- | --- | --- | --- |
| | | | |
