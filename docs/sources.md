# Sources

Public sources only. Each entry notes what the analysis takes from it.

## Regulatory: UWB

| Source | Used for |
| --- | --- |
| [FCC, *Modernization of Ultra-Wideband Technology Rules*, NPRM, ET Docket No. 26-245 (RM-11844, RM-12014), released October 1, 2026; circulation draft DOC-424842A1](https://docs.fcc.gov/public/attachments/DOC-424842A1.pdf) | The rulemaking this repo tracks. Paragraphs 22 and 28–30 ask about lifting the § 15.521(a) aircraft prohibition, UWB drone navigation and landing, geofencing, altitude limits, and request link budgets and coexistence studies. Paragraphs 37–38 propose duty cycles under 1% per 24 hours for a new device category; paragraph 44 asks about installations up to 20 m for low-altitude drone operations. Footnote 63 gives the channel 9 center (7987.2 MHz). The NPRM doesn't mention EESS or NASA. |
| [Latham & Watkins summary of the NPRM](https://www.lw.com/en/insights/fcc-proposes-uwb-rules-overhaul-that-could-broaden-use-for-drones) | Release date and comment cycle (30/60 days after Federal Register publication). |
| [47 CFR 15.519, handheld UWB devices](https://www.law.cornell.edu/cfr/text/47/15.519) | −41.3 dBm/MHz average EIRP in 3100–10600 MHz; 0 dBm peak in 50 MHz; no outdoor-mounted antennas. |
| 47 CFR 15.521(a) | Current prohibition on UWB aboard aircraft, ships, and satellites (as described in the NPRM, para. 22). |
| [ECC/DEC/(12)03, UWB onboard aircraft](https://docdb.cept.org/download/1522) | European precedent: −41.3 dBm/MHz in 6.6752–8.5 GHz, but 7.75–7.9 GHz (MetSat) is limited to −64.3 dBm/MHz at or below 1000 m AGL, and −44.3 − 20 log10(10/x) dBm/MHz above (x in km). Flying models are excluded from ECC/DEC/(06)04. |
| [ECC Report 175 (March 2012)](https://docdb.cept.org/download/674) | Aircraft-UWB coexistence study behind ECC/DEC/(12)03. Assumes 2 active devices per aircraft, 15 dB fuselage loss downward. Lists EESS 8025–8400 MHz but doesn't study it. Source of the 150 K MetSat earth station noise temperature used here only as a placeholder. |
| [ECC/DEC/(06)04 related documents](https://docdb.cept.org/download/3045) | Generic UWB decision that excludes flying models and aviation. |

## Regulatory: drones

| Source | Used for |
| --- | --- |
| [14 CFR 107.51(b)](https://www.law.cornell.edu/cfr/text/14/107.51) | 400 ft (121.92 m) AGL ceiling for small UAS; sets the drone altitude upper bound. |

## UWB technical

| Source | Used for |
| --- | --- |
| [IEEE 802.15.4 HRP UWB channel plan (overview, arXiv 2202.02190)](https://arxiv.org/pdf/2202.02190) | Channel 9: 7987.2 MHz center, 499.2 MHz bandwidth (7737.6–8236.8 MHz). |
| [Keysight 89600B, HRP UWB transmit mask](https://helpfiles.keysight.com/csg/89600B/Webhelp/Subsystems/hrpuwb/content/trc_transmit_mask.htm) | 0 dBr reference within ±0.65/Tp. The −10 dBr (0.65–0.8/Tp) and −18 dBr (> 0.8/Tp) breakpoints are from IEEE Std 802.15.4 and are marked TODO to verify against the 2020 text. |

## EESS and MetSat protection

| Source | Used for |
| --- | --- |
| [ITU-R SA.1026-5](https://itu.int/dms_pubrec/itu-r/rec/sa/R-REC-SA.1026-5-201707-I!!PDF-E.pdf) | Aggregate criteria at the earth station antenna output, 10 MHz reference: 8025–8400 MHz −147 dBW (20%), −133 dBW (0.0125%); 7750–7900 MHz −144 dBW (20%), −127 dBW (0.0125%). Table 2: 13° elevation for the 20% case and 5° for the short-term case. |
| [ITU-R SA.1027-6](https://www.itu.int/dms_pubrec/itu-r/rec/sa/R-REC-SA.1027-6-201908-I!!PDF-E.pdf) | Sharing criteria, 8025–8400 MHz, 10 MHz reference: terrestrial paths −150 dBW (20%) and −133 dBW (0.005%). Used as the governing EESS criterion because a drone is a terrestrial-path interferer (Note 4). |
| [ITU-R SA.509-3](https://itu.int/dms_pubrec/itu-r/rec/sa/R-REC-SA.509-3-201312-I!!PDF-E.pdf) | Earth station reference antenna pattern: single-entry pattern for one drone, multiple-entry pattern for the aggregate. Valid for D/λ ≥ 100. |
| [ITU-R SM.337-6](https://www.itu.int/rec/R-REC-SM.337/en) | FDR method; here the UWB PSD mask is integrated over a rectangular 10 MHz victim bandwidth. |

## Earth stations and missions

| Source | Used for |
| --- | --- |
| [Near Earth Network (Wikipedia)](https://en.wikipedia.org/wiki/Near_Earth_Network) | NASA S/X-band sites: Alaska Satellite Facility, Fairbanks (11.3 m, 11 m, 9.1 m); Wallops (11 m, 5 m); commercial NEN sites at North Pole, AK and South Point, HI. |
| [NASA Near Space Network complexes](https://www.nasa.gov/technology/space-comms/near-space-network-complexes/) | Network overview. |
| [Earth observation satellite transmission frequencies (Wikipedia)](https://en.wikipedia.org/wiki/Earth_observation_satellites_transmission_frequencies) | Example X-band downlinks inside the ch 9 overlap: Aqua 8160 MHz, Terra and Landsat 8212.5 MHz. |
| [NTIA TM 97-339, EESS in 8025–8400 MHz](https://www.ntia.gov/report/1997/assessment-expansion-earth-exploration-satellite-service-8025-8400-mhz-range) | Background on federal EESS use of the band. |
