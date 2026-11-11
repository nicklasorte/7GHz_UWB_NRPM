"""Figure 10. Same model, two places: what makes a station closer to the allowance."""

import re

from ntia_style import ACCENT, CONTEXT, RESULTS, TEXT, Page, num, read_csv

summ = {("wallops" if "Wallops" in r["station"] else "ccny"): r for r in read_csv("bridge_summary.csv")}
log = (RESULTS / "run_log_bridge_rev1.txt").read_text(encoding="utf-8")   # tracking shares are printed in the run log
w, c = summ["wallops"], summ["ccny"]

tr = [float(x) for x in re.findall(r"Tracking ([0-9.]+)% of the time", log)]
metrics = [
    ("Airborne drones per km²", num(w["rho_air_per_km2"]), num(c["rho_air_per_km2"]), "{:.2g}"),
    ("Single-drone footprint (m²)", num(w["footprint_meas_m2"]), num(c["footprint_meas_m2"]), "{:.0f}"),
    ("Share of time the dish tracks (%)", tr[0], tr[1], "{:.1f}"),
]
gap = num(c["B_ratio_dB"]) - num(w["B_ratio_dB"])
dens_ratio = metrics[0][2] / metrics[0][1]

page = Page(
    headline=(f"Manhattan sits {gap:.0f} dB closer to the allowance than the NASA station, mostly because it has "
              f"{dens_ratio:.0f} times the drones"),
    subhead=("Normal conditions at the Wallops NEN station (11.3 m) and at CCNY in Manhattan (2.4 m; a university "
             "station, not a NASA facility). Left: the inputs that differ, each scaled to Wallops = 1 (log scale). "
             "Right: the result, dB relative to the short-term allowance."),
    source=("Source: nicklasorte/7GHz_UWB_NRPM, example_bridge_rev1.m, run of November 11, 2026 "
            "(docs/bridge_results/bridge_summary.csv, run_log_bridge_rev1.txt). Density from FAA 2025 survey and "
            "Census data."),
    alt=(f"Two-panel chart comparing Wallops and CCNY. Drone density is {dens_ratio:.0f} times higher at CCNY, the "
         f"single-drone footprint {metrics[1][2] / metrics[1][1]:.1f} times larger, and the dish tracks "
         f"{metrics[2][2] / metrics[2][1]:.2f} times as much of the time. The normal-conditions result is "
         f"{num(w['B_ratio_dB']):.0f} dB at Wallops and {num(c['B_ratio_dB']):.0f} dB at CCNY."),
    axes_rect=(0.30, 0.17, 0.38, 0.48),
)
ax = page.ax
for k, (name, wv, cv, fmt) in enumerate(metrics):
    y = len(metrics) - 1 - k
    r = cv / wv
    ax.plot([1, r], [y, y], color=CONTEXT, lw=2, zorder=1)
    ax.scatter([1], [y], s=110, color=CONTEXT, zorder=2)
    ax.scatter([r], [y], s=150, color=ACCENT, edgecolor=TEXT, zorder=3)
    ax.annotate(f"Wallops {fmt.format(wv)}", (1, y), xytext=(0, -12), textcoords="offset points", ha="center",
                va="top", fontsize=9.5)
    ax.annotate(f"CCNY {fmt.format(cv)}\n(x{r:,.3g})" if r < 10 else f"CCNY {fmt.format(cv)}\n(x{r:,.0f})", (r, y), xytext=(0, 11), textcoords="offset points",
                ha="center", fontsize=9.5, fontweight="bold")
ax.set_yticks(range(len(metrics)), [m[0] for m in metrics][::-1], fontsize=10.5)
ax.set_xscale("log")
ax.set_xlim(0.3, 600)
ax.set_ylim(-0.6, len(metrics) - 0.2)
ax.set_xlabel("Ratio to Wallops (log scale)")
ax.axvline(1, color=TEXT, lw=0.8, ls=":")
ax.spines["left"].set_visible(False)
ax.tick_params(axis="y", length=0)

ax2 = page.fig.add_axes((0.76, 0.17, 0.20, 0.48))
vals = [num(w["B_ratio_dB"]), num(c["B_ratio_dB"])]
ax2.bar([0, 1], vals, color=[CONTEXT, ACCENT], width=0.6)
for i, v in enumerate(vals):
    ax2.annotate(f"{v:.0f} dB", (i, v), xytext=(0, -5), textcoords="offset points", ha="center", va="top",
                 fontsize=10.5, fontweight="bold", color="white")
ax2.axhline(0, color=TEXT, lw=1.4, ls="--")
ax2.annotate("Allowance", (0.5, 0), xytext=(0, 4), textcoords="offset points", ha="center", va="bottom",
             fontsize=10, fontweight="bold")
ax2.set_xticks([0, 1], ["Wallops\n(NASA)", "CCNY"], fontsize=10.5)
ax2.set_ylim(-60, 8)
ax2.set_ylabel("dB relative to the allowance")
page.save("viz10_two_stations", [ACCENT, CONTEXT, TEXT])
