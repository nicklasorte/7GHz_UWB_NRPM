# Research note: drone UWB use, normal drone operations, and Wallops airspace

DRAFT - PRE-DECISIONAL AND DELIBERATIVE. Prepared with AI assistance. Reviewer: [CONFIRM]. Sources checked November 11, 2026.

This note collects the public facts behind three inputs to the barbell analysis (`matlab/example_bridge_rev1.m`): what a "typical UWB device" on a drone is, what "normal conditions" means for drone flight, and whether airspace around the Wallops NEN station already keeps drones away.

## Why drones carry UWB, and how often each use transmits

**Today, drones essentially don't transmit UWB.** 47 CFR 15.521(a) prohibits UWB operation aboard an aircraft. The commercial drone UWB products found work around the rule by making the drone receive-only:

- **Omnisense (with 42 Technology):** a ground-based UWB local positioning system for landing in GNSS-degraded environments. Drones are receive-only, "since airborne UWB transmission is restricted," and range by one-way time of arrival from ground beacons that transmit.[^omni]
- **Bitcraze Loco Positioning System:** in its time-difference-of-arrival mode (TDoA3, used in its 20-drone indoor show), anchors transmit and the drones listen. The show was indoors, in a hall about 7-8 m high.[^bitcraze]
- **Agilica:** UWB local positioning for drone navigation and landing, including on moving targets. The public description doesn't say whether the drone transmits.[^agilica]

**The NPRM is what would put UWB transmitters on drones.** FCC 26-66 (ET Docket 26-245), Federal Register document 2026-22337:[^nprm]

- Keeps the § 15.521(a) text, "Operation onboard an aircraft, a ship or a satellite is prohibited," and asks about "relaxing any or all its prohibitions."
- Asks "whether UWB-based autonomous drone navigation and landing systems should be permitted," and notes systems may "allow the use of mobile devices as UWB landing beacons."
- Lists possible conditions: "altitude limits, power restrictions, and duty cycle limits," and asks how geofencing might be used.
- For a new low-power device category, proposes "duty cycles under one percent in any 24-hour period" and asks about installations "up to 20 meters, to support low altitude drone operations."
- Asks whether expanded drone operations "could alter the coexistence dynamics in shared spectrum environments." It doesn't name EESS or NASA.

Latham and Watkins' summary adds delivery, docking, and landing-station beacons at logistics hubs as cited use cases.[^lw]

**What this means for the analysis:**

| Use case | Who transmits | Likely duty cycle | Where it happens |
| --- | --- | --- | --- |
| Precision landing and docking | Today the ground beacons; under the NPRM, possibly the drone | Short bursts during approach; the NPRM proposes under 1% a day for the new category | Delivery hubs, docks, industrial sites, near the ground |
| Indoor or swarm positioning (light shows, warehouses) | Anchors (TDoA); drones in two-way modes | Continuous during the flight | Mostly indoors; outdoor light shows use GNSS |
| Tag carried as cargo or attached (AirTag-type) | The tag | Low; a tag ranges only when queried | Anywhere the drone flies |

The analysis therefore uses a 1% duty cycle as the base case, from the NPRM's proposed limit, and sweeps 0.25%-5% from ECC Report 327's activity factors. Continuous transmission is the worst-case bookend only.

## How high and fast drones normally fly

- **Rules:** 400 ft (121.92 m) above ground and 100 mph (87 knots) maximum under 14 CFR 107.51, within visual line of sight.
- **Remote ID data:** the FAA's ASSURE A83 project analyzed Remote ID and air traffic data from November 2024 to December 2025. Its public project page says "most UAS activity is low-altitude, low-speed, short in duration."[^assure] A summary of the 2025 annual report gives the telemetry speed split: 49.3% static, 26.9% below 15 mph, 7.8% above 30 mph, and 0.1% above 50 mph. It also says only 5.3% of operations were above 500 ft.[^ua] The annual report itself couldn't be retrieved from this environment, so these figures should be confirmed against it before the paper cites them.

**What this means for the analysis:**

- **Hovering is normal.** About half of the telemetry is stationary, so the hovering drone in Bookend A is a normal flight state, not an exotic one. What makes Bookend A the worst case is placing the drone exactly on the boresight of a low pass while transmitting continuously at the limit, not the hovering.
- **Speeds for the crossing budget:** 5, 15, and 30 mph (2.2, 6.7, and 13.4 m/s), matching the ASSURE bins.
- **Altitude:** the model's uniform 10 m to 400 ft spread has no public distribution behind it. The ASSURE finding that a small share flies above 500 ft says little about the spread below 400 ft. Keep it as a stated assumption, with a sensitivity in the ranking chart.

## Whether airspace around Wallops already limits drone flights

- **Restricted areas R-6604C, D, and E** (FAA final rule, November 7, 2016) are part time, activated "by NOTAM at least 12 hours in advance." Each is expected to be used about 1.5 hours a day on about 120 days a year (40 days a year for E). R-6604C covers the airfield inside the Wallops property from the surface to 3,500 ft MSL. R-6604D starts at 100 ft AGL and R-6604E at 700 ft AGL, so E sits above the drone altitude band.[^r6604]
- **Class D airspace** around the Wallops airfield (surface to 2,500 ft MSL, 4.4-mile radius) requires FAA authorization for Part 107 flights. A 2023 FAA proposal (FAA-2023-2204) would make it effective by NOTAM.[^classd]
- **NASA guidance:** for launches, NASA asks drone operators to stay off Wallops property, the marshes between the island and the mainland, and the ocean east of the island, and says the FAA activates temporary flight restrictions.[^nasa]
- **No permanent drone exclusion was found.** The FAA national security UAS flight restrictions (14 CFR 99.7) found cover DoD, DOE, and DOJ facilities; none for Wallops turned up. To verify on the FAA UAS Facility Maps.

**What this means for the analysis:** airspace near Wallops reduces drone traffic part time and requires authorization close to the airfield, but it doesn't remove it. The Wallops density chain doesn't take any credit for airspace. Local density is low anyway: Accomack County has about 29 residents per km² (33,859 in 2025 over 450 square miles of land),[^accomack] and Virginia flies about 1.1 times the national rate per resident.[^faa]

## Sources

[^omni]: Inside Unmanned Systems, "Omnisense Drone Landing System for GNSS-Degraded Environments," https://insideunmannedsystems.com/omnisense-drone-landing-system-for-gnss-degraded-environments/.
[^bitcraze]: Bitcraze, "The Big Loco Test Show" (December 2022), https://www.bitcraze.io/2022/12/the-big-loco-show/.
[^agilica]: GPS World, "Belgium company Agilica offers UWB-based local positioning for UAVs," https://www.gpsworld.com/belgium-company-agilica-offers-uwb-based-local-positioning-for-uavs/.
[^nprm]: FCC, Notice of Proposed Rulemaking, ET Docket No. 26-245, FCC 26-66, Federal Register public inspection document 2026-22337, https://public-inspection.federalregister.gov/2026-22337.pdf.
[^lw]: Latham and Watkins, "FCC Proposes UWB Rules Overhaul That Could Broaden Use for Drones" (October 5, 2026), https://www.lw.com/en/insights/fcc-proposes-uwb-rules-overhaul-that-could-broaden-use-for-drones.
[^assure]: ASSURE, "Analyze Drone Traffic (A83_A11L.UAS.122)," https://assure.msstate.edu/projects/analyze-drone-traffic-a83_a11l-uas-122/.
[^ua]: Unmanned Airspace, "DJI drones account for more than 96% of US operations: new FAA research" (March 3, 2026), summarizing the ASSURE A83 2025 Annual Report, https://www.unmannedairspace.info/news-first/dji-drones-account-for-more-than-96-of-us-operations-new-faa-research/.
[^r6604]: FAA, "Amendment and Establishment of Restricted Areas; Chincoteague Inlet, VA," 81 FR 78029 (November 7, 2016), https://regulations.justia.com/regulations/fedreg/2016/11/07/2016-26760.html.
[^classd]: FAA, proposed amendment of Class D and E airspace, Wallops Island, VA, Docket FAA-2023-2204, https://downloads.regulations.gov/FAA-2023-2204-0001/content.pdf.
[^nasa]: NASA, "NASA Offers Guidance for Drone Use, Viewing Antares Launch," https://www.nasa.gov/centers-and-facilities/wallops/nasa-offers-guidance-for-drone-use-viewing-antares-launch.
[^accomack]: Census Bureau county population totals 2020-2025 and Gazetteer land area, as cited in "Accomack County, Virginia," Wikipedia, https://en.wikipedia.org/wiki/Accomack_County,_Virginia. Confirm against Census QuickFacts, which couldn't be retrieved from this environment.
[^faa]: FAA, *Small Unmanned Aircraft Systems Survey Report 2025*, Tables 1, 6, and 7 (Virginia 1,646,290 flights), https://www.faa.gov/data_research/aviation/aerospace_forecasts/Small-Unmanned-Aircraft-Systems-Survey-Report-2025.pdf; Virginia population 8.88 million on July 1, 2025, Weldon Cooper Center, as reported by Virginia Realtors, https://virginiarealtors.org/2026/05/27/3-key-takeaways-from-virginias-new-population-estimates/.
