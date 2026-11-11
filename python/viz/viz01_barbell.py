"""Figure 1. The barbell: boresight worst case against normal conditions, by station."""

from ntia_style import ACCENT, ALERT, CONTEXT, TEXT, Page, num, read_csv

rows = []
for tag, name in [("wallops", "NASA NEN, Wallops (11.3 m)"), ("ccny", "CCNY, Manhattan (2.4 m)\nnot a NASA facility")]:
    b = {r["step"]: num(r["ratio_dB"]) for r in read_csv(f"bridge_{tag}.csv")}
    rows.append((name, b))
wal = rows[0][1]

page = Page(
    headline=(f"At the NASA station, a drone that stays on the moving beam would be {wal['A']:.0f} dB over the allowance; "
              f"drones under normal conditions are {-wal['B']:.0f} dB under it"),
    subhead=("Time above the ITU-R SA.1027-6 short-term criterion (0.005% of time), relative to the allowance, dB. "
             "Worst case: one drone that follows the beam, at the limit, transmitting continuously. "
             "Normal: AirTag-measured EIRP, 1% duty cycle, local FAA-based drone density, every drone carrying UWB."),
    source=("Source: nicklasorte/7GHz_UWB_NRPM, example_bridge_rev1.m, run of November 11, 2026 "
            "(docs/bridge_results/bridge_*.csv). EESS 8160 MHz, tracking-time basis unless marked."),
    alt=("Dumbbell chart with one row per station. For the NASA Wallops station, the worst case sits at "
         f"+{wal['A']:.0f} dB and normal conditions at {wal['B']:.0f} dB relative to the allowance; for CCNY, "
         f"+{rows[1][1]['A']:.0f} dB and {rows[1][1]['B']:.0f} dB. Small markers show the all-time basis and the "
         "20 dB apportionment cases. Only the worst case is above the allowance line at 0 dB."),
    axes_rect=(0.27, 0.17, 0.68, 0.50),
)
ax = page.ax
ys = [1, 0]
for (name, b), y in zip(rows, ys):
    ax.plot([b["B"], b["A"]], [y, y], color=CONTEXT, lw=3, solid_capstyle="round", zorder=1)
    ax.scatter([b["A"]], [y], s=220, color=ALERT, zorder=3)
    ax.scatter([b["B"]], [y], s=260, color=ACCENT, zorder=3, edgecolor=TEXT, linewidth=1.2)
    ax.scatter([b["D1"], b["D2"]], [y, y], s=90, facecolor="white", edgecolor=TEXT, linewidth=1.2, zorder=3)
    ax.annotate(f"Worst case\n+{b['A']:.0f} dB", (b["A"], y), xytext=(0, 16), textcoords="offset points",
                ha="center", va="bottom", fontsize=10.5, color=ALERT, fontweight="bold")
    ax.annotate(f"Normal\n{b['B']:.0f} dB", (b["B"], y), xytext=(0, 16), textcoords="offset points",
                ha="center", va="bottom", fontsize=10.5, color=TEXT, fontweight="bold")
    ax.annotate(f"All time\n{b['D1']:.0f}", (b["D1"], y), xytext=(0, -16), textcoords="offset points",
                ha="center", va="top", fontsize=9.5, color=TEXT)
    ax.annotate(f"20 dB\napportion-\nment {b['D2']:.0f}", (b["D2"], y), xytext=(0, -16), textcoords="offset points",
                ha="center", va="top", fontsize=9.5, color=TEXT)
ax.axvline(0, color=TEXT, lw=1.4, ls="--", zorder=2)
ax.annotate("Allowance", (0, 1.62), ha="center", va="bottom", fontsize=10.5, color=TEXT, fontweight="bold",
            annotation_clip=False)
ax.annotate("Above: criterion exceeded", (2, 1.45), ha="left", fontsize=9.5, color=TEXT, annotation_clip=False)
ax.set_yticks(ys, [r[0] for r in rows], fontsize=11)
ax.set_ylim(-0.75, 1.6)
ax.set_xlim(-70, 55)
ax.set_xlabel("Time above the short-term criterion relative to the allowance (dB)")
ax.spines["left"].set_visible(False)
ax.tick_params(axis="y", length=0)
ax.grid(axis="x", color="#E6E6E6")
ax.set_axisbelow(True)
page.save("viz01_barbell", [ACCENT, ALERT, CONTEXT, TEXT])
