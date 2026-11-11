# Data visualization plan: when does a UWB drone interfere with a NASA receiver?

DRAFT - PRE-DECISIONAL AND DELIBERATIVE. Prepared with AI assistance. Reviewer: [CONFIRM]. Plan date: November 11, 2026.

This plan lists 10 figures for the working paper and briefings. Each figure answers one question in the research question's chain, from "can a drone interfere at all?" to "how often does it happen?" Headlines are drafts. Each number in a headline is read from the run outputs at build time, not typed, so the figure and the paper can't disagree.

## How the figures are built

- **MATLAB** draws the figures that come straight from the model's geometry and orbits, where the plotting code calls the same functions the analysis uses. Scripts go in `matlab/viz/` as `viz<NN>_<name>_rev1.m`.
- **Python** draws the presentation one-pagers from the published CSV files, with the `onepager` toolkit and its NTIA theme (gray plus one accent, direct labels, DRAFT//PRE-DECISIONAL marking, alt text). Scripts go in `python/viz/` as `viz<NN>_<name>.py`, with a `requirements.txt`.
- **Outputs** go in `docs/figures/viz/` as PNG (300 dpi), PDF, and SVG, each with an `.alt.txt` file.
- **Inputs** are the CSV files in `docs/bridge_results/` and `docs/ccny_results/` from the November 10-11, 2026 runs. Figures 3, 5, and 8 need small new exports, noted below.

## The 10 figures

Each line under a figure: the question it answers, its audience, the chart form, the data, the tool, and the check it must pass.

### 1. The barbell: worst case against normal conditions

- **Draft headline:** "At the NASA station, a drone on boresight is 43 dB over the allowance; under normal conditions drones are 50 dB under."
- **Question:** How far apart are the two ends of the problem?
- **Audience:** Leadership and NASA program managers; the paper's lead figure.
- **Form:** Dumbbell chart. One row per station (Wallops, CCNY), a red dot for the worst case and a dark dot for normal conditions, joined by a line, with the allowance as a vertical line at 0 dB. The two decisions (time basis, apportionment) are small orange ticks on each row.
- **Data:** `bridge_wallops.csv`, `bridge_ccny.csv` (rows A, B, D1, D2).
- **Tool:** Python, `viz01_barbell.py`.
- **Check:** Values match the bridge tables exactly; the allowance line is labeled; readable in grayscale.

### 2. The bridge, annotated

- **Draft headline:** "Most of the 93 dB gap is one step: from a drone placed perfectly in the beam to real traffic (55 dB). The moving beam adds 18 dB and duty cycle 20 dB."
- **Question:** Which assumption moves the result how much, one step at a time?
- **Audience:** NASA engineers, who can stop the walk at any step they reject.
- **Form:** Waterfall, rebuilt from the existing MATLAB version with a one-line note under each bar saying what changed, and the allowance band shaded.
- **Data:** `bridge_wallops.csv`.
- **Tool:** Python, `viz02_bridge.py`. It replaces `fig_bridge_wallops.png` in the paper; the MATLAB chart stays for engineers.
- **Check:** Each step's change equals the difference of adjacent rows; decision bars are measured from normal conditions, as the code does.

### 3. Where a drone has to be: plan view at Wallops

- **Draft headline:** "One drone exceeds the short-term criterion only inside a sliver 115 m long and 15 m wide, 1.2 km out along the dish's pointing direction."
- **Question:** Where on the ground, around the NASA dish, can one drone cause interference?
- **Audience:** Everyone; the most intuitive answer to "at what point."
- **Form:** Map around the WG1 location with the exceedance sliver for a 5° pass, the off-axis rings (300 m at 1°, 40 m at 5°), and a 1 km scale bar, on a muted basemap.
- **Data:** New. A 5 m grid of the single-drone interference at 400 ft, exported from the step 3 map in `example_bridge_rev1.m`.
- **Tool:** MATLAB, `viz03_plan_view_rev1.m` (geoaxes; the basemap needs internet access on the Mac).
- **Check:** Sliver dimensions match `region_chord_rev1` output; site coordinates match `victim_systems_rev2`.

### 4. Why the main beam is out of reach beyond 1.2 km: side view

- **Draft headline:** "Past 1.16 km, the beam of a 5° pass is above the 400 ft ceiling, so no legal drone can reach it."
- **Question:** Why doesn't the 5.6 km main-beam distance matter?
- **Audience:** Everyone, especially non-engineers.
- **Form:** Vertical cross-section: the dish at 10 m, the beam cone at 5° and at 10°, the 400 ft Part 107 ceiling as a band, and the crossing point marked. A second, lighter line shows how far the short-term distance would extend if the beam stayed low.
- **Data:** Computed from `air_to_ground_geometry_rev1` and the pattern beamwidth; no new run.
- **Tool:** MATLAB, `viz04_side_view_rev1.m`.
- **Check:** The crossing distance equals the 1.16 km in the threshold-distance log; vertical exaggeration is stated on the figure.

### 5. How long the beam stays on a hovering drone

- **Draft headline:** "A hovering drone at the worst spot stays in the beam's exceedance cone for about 8 seconds per pass."
- **Question:** What does the moving beam do to the worst case?
- **Audience:** NASA engineers.
- **Form:** Two panels. Left: one real Wallops pass, with the off-axis angle of a drone hovering at the best spot over time and the exceedance window shaded. Right: distribution of the per-pass maximum dwell over 556 passes in 30 days, median marked.
- **Data:** `beam_dwell_passes_wallops.csv`, plus a new per-sample export (off-axis angle against time for one pass) from `beam_dwell_rev1`.
- **Tool:** MATLAB, `viz05_beam_dwell_rev1.m`.
- **Check:** The median matches the 8.2 s from the pass table; the time axis is in seconds from the start of the pass.

### 6. How close a drone has to be, by angle

- **Draft headline:** "Off the main beam, the distance collapses: 300 m at 1°, 40 m at 5°, under 10 m beyond 20°."
- **Question:** How close, in the main beam and the sidelobes?
- **Audience:** NASA engineers; the paper's distance figure.
- **Form:** Log-log line chart of threshold distance against off-axis angle for the short-term criterion, with the long-term and apportioned cases in gray, the main-beam region shaded, and the 1.16 km reach drawn as a ceiling. Direct labels at 1°, 5°, and 20°.
- **Data:** `threshold_distance_wallops.csv`.
- **Tool:** Python, `viz06_threshold_distance.py`. It replaces Figure 9 in the paper.
- **Check:** Labeled values match the CSV; the long-term line is marked as unreachable by one drone below 20% duty.

### 7. The duty cycle every study assumes, against what it would take

- **Draft headline:** "Every study in this band assumes 5% or less; reaching the allowance takes 7.3% in Manhattan and isn't possible at Wallops."
- **Question:** Is the break-even duty cycle plausible?
- **Audience:** Leadership and the regulatory audience; the paper's assumption figure.
- **Form:** Dot strip on a log axis from 0.001% to 100%: one dot per cited activity factor (ECC Report 327 applications, CEPT Report 9, ECC Report 94, the FiRa report, the NPRM), labeled by source. Vertical lines for the CCNY break-even (7.3%; 1.2% at sustained peak) and a "no break-even below 100%" marker for Wallops.
- **Data:** New. `docs/duty_cycle_citations.csv`, one row per cited value with its source and table, plus `duty_break_even_*.csv`.
- **Tool:** Python, `viz07_duty_evidence.py`.
- **Check:** Every dot traces to a footnoted source in the paper; the 6% FiRa appendix value is shown, not dropped.

### 8. How long a drone must stay close to use up the allowance

- **Draft headline:** "At a 1% duty cycle, a drone would need 4.9 hours in the beam during passes, about 2,100 perfectly placed passes a year."
- **Question:** What does the duty cycle mean in time?
- **Audience:** Leadership.
- **Form:** Horizontal bars on a log scale, one per duty cycle (0.05%, 0.3%, 1%, 5%, 100%), showing hours a year inside the short-term distance on the tracking-time basis, with the equivalent number of perfectly placed passes printed at the end of each bar.
- **Data:** `hours_to_allowance_wallops.csv`, `beam_dwell_passes_wallops.csv`.
- **Tool:** Python, `viz08_hours_to_allowance.py`.
- **Check:** The pass count is computed in the script (hours ÷ median dwell) and marked "derived" on the figure.

### 9. What could move the normal-conditions result

- **Draft headline:** "No single assumption brings the NASA station within 30 dB of the allowance."
- **Question:** Which assumption matters most, and can any of them flip the answer?
- **Audience:** NASA engineers and the red team.
- **Form:** Tornado chart, rebuilt from the MATLAB version: gray bars, the allowance drawn at 0 dB on the same axis so the gap is visible, and each bar's end labeled with its input value.
- **Data:** `tornado_wallops.csv`.
- **Tool:** Python, `viz09_tornado.py`.
- **Check:** The headline's 30 dB is computed from the highest bar end; the axis extends to 0 dB.

### 10. Same model, two places

- **Draft headline:** "Manhattan sits 25 dB closer to the allowance than Wallops, mostly because it has 140 times the drones."
- **Question:** What makes a station vulnerable: the dish or the location?
- **Audience:** Leadership; sets up the station-by-station runs NASA would need.
- **Form:** Paired slope chart for Wallops and CCNY across four normalized quantities: drone density, single-drone footprint, share of time the dish tracks, and the normal-conditions result. Each line is labeled with both values and their ratio.
- **Data:** `bridge_summary.csv`, `footprints_*.csv`.
- **Tool:** Python, `viz10_two_stations.py`.
- **Check:** The ratios come from the CSV; the figure says plainly that CCNY isn't a NASA facility.

## Order of the figures in the paper

| Paper section | Figures |
| --- | --- |
| Executive summary | 1 |
| Bookend A: boresight worst case | 4, 5 |
| Bookend B: normal conditions | 3, 6 |
| Key assumptions: duty cycle | 7, 8 |
| The bridge and what drives the answer | 2, 9 |
| Context: other stations | 10 |

## Checks for every figure

1. **Numbers from data:** every number in a headline or label is read from a CSV at build time.
2. **Toolkit review:** each Python figure passes `review.py` (text overlap, minimum 8 pt text, contrast, color-blind separation, alt text). MATLAB figures get the same visual check from a rendered contact sheet.
3. **Marking:** DRAFT//PRE-DECISIONAL on every figure, and the source line names the run date and CSV.
4. **Rebuild:** one command per language rebuilds all figures (`matlab -batch run_all_viz_rev1` and `python python/viz/run_all.py`), so a rerun of the analysis refreshes them.
5. **Independent read:** before the figures go to NASA, someone who didn't build them checks each headline against its CSV.

## New work the plan needs

| Item | Size |
| --- | --- |
| Export the single-drone grid (figure 3) and one pass's off-axis angle against time (figure 5) | Small change to `example_bridge_rev1.m` |
| `docs/duty_cycle_citations.csv` (figure 7) | Small; from the cited sources already in the paper |
| 3 MATLAB scripts and 7 Python scripts, plus the two run-all scripts | Main work |
| Python environment: matplotlib, numpy, Pillow (the toolkit's requirements) | Present in the workspace |
