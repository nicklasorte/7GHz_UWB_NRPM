"""Figure 8. How long a drone must stay inside the short-term distance to use up the allowance (Wallops)."""

import statistics

from ntia_style import ACCENT, CONTEXT, TEXT, Page, num, read_csv

hrs = read_csv("hours_to_allowance_wallops.csv")
passes = read_csv("beam_dwell_passes_wallops.csv")
dwell = statistics.median(num(r["max_dwell_s"]) for r in passes)
per_day = len(passes) / 30.0
lbl = {0.05: "0.05%  ECC parking", 0.3: "0.3%  ECC logistics", 1.0: "1%  NPRM; ECC indoor",
       5.0: "5%  ECC maximum", 100.0: "100%  continuous (bound)"}
rows = [(num(r["duty_pct"]), num(r["hours_tracking_basis"])) for r in hrs]
one = next(h for d, h in rows if d == 1.0)
n_one = one * 3600 / dwell

page = Page(
    headline=(f"At a 1% duty cycle, a drone would need {one:.1f} hours a year inside the beam during passes: about "
              f"{n_one:,.0f} perfectly placed passes at the NASA station"),
    subhead=(f"Wallops NEN 11.3 m. Hours a year a drone must spend inside the short-term distance, in the direction "
             f"the dish points while it tracks, to use up the short-term allowance (0.005% of tracking time). Passes "
             f"(derived) = hours / {dwell:.1f} s, the median time the beam stays on a hovering drone at the best spot; "
             f"{per_day:.1f} passes a day."),
    source=("Source: nicklasorte/7GHz_UWB_NRPM, threshold_distance_rev1.m and beam_dwell_rev1.m via "
            "example_bridge_rev1.m, run of November 11, 2026 (docs/bridge_results/hours_to_allowance_wallops.csv, "
            "beam_dwell_passes_wallops.csv)."),
    alt=(f"Horizontal bar chart on a log scale of hours a year needed inside the short-term distance by duty cycle "
         f"at the Wallops NEN station: from {rows[0][1]:.0f} hours at 0.05% to {rows[-1][1] * 60:.1f} minutes at "
         f"continuous transmission. At 1%, {one:.1f} hours, about {float(f'{n_one:.2g}'):,.0f} perfectly placed passes."),
    axes_rect=(0.27, 0.15, 0.62, 0.50),
)
ax = page.ax
rows.sort(key=lambda t: -t[0])
for k, (d, h) in enumerate(rows):
    c = ACCENT if d == 1.0 else CONTEXT
    ax.barh(k, h, color=c, height=0.62)
    n = h * 3600 / dwell
    t = f"{h:.1f} h" if h >= 1 else f"{h * 60:.0f} min"
    ax.annotate(f"{t}   ~{float(f'{n:.2g}'):,.0f} passes", (h, k), xytext=(6, 0), textcoords="offset points", va="center",
                fontsize=10.5, fontweight="bold" if d == 1.0 else "normal", color=TEXT)
ax.set_yticks(range(len(rows)), [lbl.get(d, f"{d:g}%") for d, _ in rows], fontsize=10.5)
ax.set_xscale("log")
ax.set_xlim(0.01, 3000)
ax.set_xticks([0.01, 0.1, 1, 10, 100, 1000], ["0.01", "0.1", "1", "10", "100", "1,000"])
ax.set_xlabel("Hours a year inside the short-term distance, tracking-time basis (log scale)")
ax.spines["left"].set_visible(False)
ax.tick_params(axis="y", length=0)
ax.grid(axis="x", color="#E6E6E6")
ax.set_axisbelow(True)
page.save("viz08_hours_to_allowance", [ACCENT, CONTEXT, TEXT])
