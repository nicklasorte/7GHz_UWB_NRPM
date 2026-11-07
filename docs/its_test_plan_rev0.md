---
title: "Test Plan: 802.15.4z Channel 9 Emissions into X-band EESS Demodulators"
subtitle: "Draft for NTIA ITS and NASA, Rev 0"
date: "November 7, 2026"
---

```
DRAFT - PRE-DECISIONAL AND DELIBERATIVE
Prepared with AI assistance. Reviewer: [CONFIRM]
```

# Objective

Measure the bit error rate (BER) of representative X-band EESS demodulators as a function of UWB channel 9 interference power, for the pulse structures the FCC rules allow. The result shows whether the ITU-R SA.1027-6 average-power criteria protect these receivers from pulsed UWB, or whether a tighter level is needed.

# Basis

- NTIA Report TR-05-419 (2005) defines a method for UWB susceptibility testing of a satellite digital receiver (C-band DVB, QPSK) with dithered pulses and gated noise ([its.ntia.gov](https://its.ntia.gov/publications/download/TR-05-419.pdf)). This plan reuses its structure.
- NTIA Report 01-383 (2001) explains why receivers narrower than the pulse repetition frequency see noise-like UWB while wider receivers resolve pulses.
- The NPRM, ET Docket No. 26-245, footnote 40, notes ITS plans to test UWB against federal systems in the 7 GHz band.

# Devices under test

| Receiver | Bandwidth | Modulation and coding | Why |
| --- | --- | --- | --- |
| NEN X-band demodulator (as used at AS1 or WG1) | Per mission, up to 320 Mbps | QPSK family; Viterbi, Reed-Solomon, rate-7/8 LDPC | NASA's primary concern |
| Landsat-class wideband receiver | 375 MHz | Rate-7/8 LDPC | Resolves individual UWB pulses |
| JPSS HRD terminal receiver | 30 MHz | QPSK; RS(255,223) + rate-1/2 convolutional | Narrower than every UWB PRF; noise-like case |

NASA, USGS, and NOAA identify loanable units or test-bed equivalents. [CONFIRM]

# Interference signals

1. 802.15.4z HRP channel 9, BPRF (mean PRF 62.4 MHz), generated with MATLAB `lrwpanHRPConfig` and `lrwpanWaveformGenerator` and played through a wideband vector signal generator.
2. Same, HPRF at 124.8 MHz and 249.6 MHz mean PRF.
3. Packet gating: on-times of 0.1 ms, 0.25 ms, and 1 ms in a 1 ms frame, and duty cycles of 1%, 5%, and 100%, so the in-packet power ranges up to the 7.3 dB above average that 47 CFR 15.521 allows.
4. Additive white Gaussian noise of equal average power, as the reference.

# Procedure

1. Set the wanted signal to the mission's required Eb/N0 plus its link margin, then to the margin only.
2. For each interference signal, step the average interference power in 1 dB steps from 20 dB below to 10 dB above the ITU-R long-term level referred to the receiver input.
3. Record pre- and post-decoder BER, frame loss, and lock loss for at least 10⁹ bits or 100 errors per point.
4. Record the interference power at which BER reaches the ITU-R SA.1159-4 objective (10⁻³, 10⁻⁵, or 10⁻⁶ by link), for each signal.

# Pass and fail metric (set before testing)

For each receiver and signal, compute the difference between the UWB level that reaches the BER objective and the Gaussian-noise level that does. If the UWB level is within 1 dB of the noise level, the average-power criteria hold. If it's lower by more than 1 dB, the criteria are tightened by that difference in the analysis.

# Deliverables

A data set of BER versus interference power for every signal and receiver, the measured offsets from Gaussian noise, and a short report. Both NTIA and NASA review the setup before testing starts.
