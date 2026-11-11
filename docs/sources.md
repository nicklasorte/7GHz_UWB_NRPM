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

## Added for the working paper

| Source | Used for |
| --- | --- |
| [NTIA, *The Spectrum Needs of U.S. Space-based Operations*, Appendix "Allocations and Systems" (July 2021)](https://www.ntia.gov/sites/default/files/publications/appendix-allocationsandsystems_0.pdf) | Allocations and named federal users in 7250-8400 MHz: NOAA S-NPP and JPSS in 7750-7900 MHz; NASA Aqua, Aura, Terra, and NEN in 8025-8400 MHz; US258 cited. |
| [JPSS-1 HRD to DBS RF ICD Rev A, 470-REF-00184 (2015-02-09)](https://www.nesdis.noaa.gov/s3/2022-03/JPSS-1SCHRDtoDBSRFICDRevA-470-REF-00184February9,2015.pdf) | JPSS HRD: 7812 MHz, 30 MHz assigned bandwidth, QPSK, RHCP, 15 Mbps, 3 m reference antenna, G/T 22.7 dB/K at 5°, Eb/N0 4.4 dB, 1 dB margin. |
| [NOAA OSPO, High Rate Data](https://ospo.noaa.gov/operations/jpss/high-rate-data.html) | 47 HRD users; 25 Mbps from NOAA-21. |
| [USGS, Landsat data from space to Earth](https://www.usgs.gov/landsat-missions/landsat-data-space-earth); [USGS pub 70193004](https://pubs.usgs.gov/publication/70193004) | EROS 10 m antenna; Landsat 8 384 Mbps in the 375 MHz allocation with rate-7/8 LDPC. |
| [47 CFR 15.521 (archived text)](https://ziggy.hallikainen.org/org/FCC/FccRules/2013/15/521) | 15.521(a) aircraft prohibition; 15.521(d) RMS average in 1 MHz over 1 ms or less; 15.521(g) peak limit 20 log (RBW/50) dBm for 1-50 MHz RBW. |
| [MathWorks `lrwpanHRPConfig`](https://www.mathworks.com/help/comm/ref/lrwpanhrpconfig.html) | HRP mean PRF: BPRF 62.4 MHz; HPRF 124.8 and 249.6 MHz; peak PRF 499.2 MHz. |
| [NTIA Report 01-383, *Temporal and Spectral Characteristics of UWB Signals* (2001)](https://www.its.ntia.gov/publications/download/TR-01-383.pdf) | Noise-like vs. pulse-resolved regimes vs. repetition rate and receiver bandwidth; dithering; aggregate tends to Gaussian. |
| [NTIA SP 01-43, *Assessment of Compatibility Between UWB Devices and Selected Federal Systems* (2001)](https://www.ntia.gov/report/2001/assessment-compatibility-between-ultrawideband-devices-and-selected-federal-systems) | Federal average and peak UWB method; FSS earth station analyses at 5° and 20°. |
| [Report ITU-R SM.2057 (2005), contents](https://www.itu.int/dms_pub/itu-r/opb/rep/R-REP-SM.2057-2005-TOC-HTM-E.htm); [ITU-R SM.1757](https://www.itu.int/rec/R-REC-SM.1757/en) | International UWB impact studies; SM.2057 Annex 6 (EESS, space research) and Annex 8 section 6.1 (EESS protection). |
| [ECC Report 64 (2005)](https://docdb.cept.org/document/174) | European generic UWB study; coverage of 8 GHz EESS not verified. |
| [FiRa Consortium, *UWB Simulation Report* (2025)](https://www.firaconsortium.org/sites/default/files/2025-11/FiRa%20Ultra-Wideband%20Simulation%20Report.pdf) | ECC Report 327 Table 18 activity factors (0.25%-5%); industry SEAMCAT study of FSS earth stations and radars. |
| [Ely, Fuller, Shaver, *UWB Electromagnetic Interference to Aircraft Radios* (NASA Langley, about 2002)](https://ntrs.nasa.gov/api/citations/20030007914/downloads/20030007914.pdf) | Field evidence of UWB effects on aviation receivers near -41 dBm EIRP. |

## Added for the site-specific example (CCNY) and Rev 1

| Source | Used for |
| --- | --- |
| [NASA GSFC Direct Readout Laboratory, X-band station list](https://directreadout.sci.gsfc.nasa.gov/x-band.html) | CCNY NOAA-CREST station location, 40.820 N, 73.950 W (entry 154); other U.S. direct-readout sites near large cities. |
| [CUNY CREST, Satellite Receiving Station](https://crest.cuny.edu/hires/research/facilities/satellite-receiving-station) | 2.4 m X-band antenna in a radome; Terra, Aqua, and Suomi NPP reception. |
| [ITU-R F.699-5 (05/2000)](https://www.itu.int/dms_pubrec/itu-r/rec/f/R-REC-F.699-5-200005-S!!PDF-E.pdf) | Reference pattern for D/lambda <= 100 (recommends 2.2), used for the 2.4 m dish. |
| [FAA, *Small Unmanned Aircraft Systems Survey Report 2025*](https://www.faa.gov/data_research/aviation/aerospace_forecasts/Small-Unmanned-Aircraft-Systems-Survey-Report-2025.pdf) | 2025 flights (57,836,452) and flight hours (21,676,799), Table 1; flights by state, Table 6 (New York 1,366,899); flight altitudes of about 190-230 ft AGL, Tables 2-3. |
| [FAA, Drones by the numbers](https://www.faa.gov/node/54496) | Registrations as of November 2025: 453,635 commercial, 371,334 recreational flyers, 481,760 certificated remote pilots. |
| [FAA Aerospace Forecast FY2021-2041, UAS chapter](https://www.faa.gov/sites/faa.gov/files/data_research/aviation/aerospace_forecasts/Unmanned_Aircraft_Systems.pdf) | Recreational ownership maps to population centers; fleet forecast. |
| [Census Bureau QuickFacts, New York](https://www.census.gov/quickfacts/fact/table/NY,US/PST045225) | New York state population, July 1, 2025 (V2025): 20,002,427. |
| [Cornell Program on Applied Demographics, *Vintage 2025 State Highlights*](https://pad.human.cornell.edu/papers/downloads/V2025StateHighlights.pdf); [Census Bureau, Vintage 2025 press release](https://census.gov/newsroom/press-releases/2026/population-growth-slows.html) | U.S. population 341,784,857 and New York State 20,002,427 on July 1, 2025 (Census V2025). |
| [NYC Department of City Planning, *Population Estimates and Trends* (March 2026)](https://s-media.nyc.gov/agencies/dcp/assets/files/pdf/data-tools/population/population-estimates/new-york-city-population-estimates-and-trends-march-2026.pdf) | New York City 8,584,629 and Manhattan 1,664,862 (Census V2025, July 1, 2025). |
| [NYS DOH, Vital Statistics 2020, Table 2](https://healthweb-back.health.ny.gov/statistics/vital_statistics/2020/table02.htm) | Land area: New York City 300.45 sq mi, Manhattan 22.66 sq mi. |
| [ECC Report 327 (2021), PDF](https://docdb.cept.org/download/3511) | Executive-summary separation distances used in the consistency check (single entry 300-3600 m; fixed outdoor 100 m; vehicles 700 m EESS, 400 m MetSat); Table 1 densities. Section 5.5 earth station parameters weren't retrievable. |
| [UL test report 12791034-E2V3 for Apple AirTag, FCC ID BCGA2187 (2020)](https://fcc.report/FCC-ID/BCGA2187/5130980.pdf) | Measured channel 9 average EIRP -41.84 to -43.45 dBm/MHz, peak -0.6 to -4.08 dBm/50 MHz, -10 dB bandwidth 525.5 MHz; transmissions cease within 10 s without a response. |
| [NTIA reference implementation of P.2108 (v1.1)](https://github.com/NTIA/p2108); [MATLAB port](https://github.com/nicklasorte/itu_p2108) | Validated clutter model for the ground UWB baseline. |
