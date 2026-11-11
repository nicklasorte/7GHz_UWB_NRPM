"""Figure 2. The bridge from the boresight worst case to normal conditions, one assumption at a time (Wallops)."""

from ntia_style import ACCENT, ALERT, CONTEXT, LIGHT, TEXT, Page, num, read_csv

br = read_csv("bridge_wallops.csv")
v = {r["step"]: num(r["ratio_dB"]) for r in br}
steps = ["A", "1", "2", "3", "4", "B", "D1", "D2"]
notes = {
    "A": "One drone that\nfollows the beam,\nat the limit,\ncontinuous",
    "1": "It hovers at the\nideal spot; the\nbeam sweeps past",
    "2": "Random position,\nlocal traffic",
    "3": "AirTag-measured\nEIRP",
    "4": "1% duty cycle",
    "B": "Normal\nconditions",
    "D1": "Decision:\ncount over\nall time",
    "D2": "Decision:\n20 dB\napportionment",
}
d_beam = v["A"] - v["1"]
d_traffic = v["1"] - v["2"]
d_duty = v["3"] - v["4"]
gap = v["A"] - v["B"]

page = Page(
    headline=(f"Most of the {gap:.0f} dB gap at the NASA station is one step: from a drone placed perfectly in the "
              f"beam to real traffic ({d_traffic:.0f} dB)"),
    subhead=(f"Wallops NEN 11.3 m, EESS 8160 MHz. Each bar changes one assumption and keeps the earlier ones. "
             f"The moving beam accounts for {d_beam:.0f} dB and the 1% duty cycle for {d_duty:.0f} dB. Decisions are "
             f"measured from normal conditions. dB relative to the short-term allowance (0.005% of time)."),
    source=("Source: nicklasorte/7GHz_UWB_NRPM, example_bridge_rev1.m and bridge_steps_rev1.m, run of November 11, "
            "2026 (docs/bridge_results/bridge_wallops.csv)."),
    alt=(f"Waterfall chart from +{v['A']:.0f} dB for one drone following the beam to {v['B']:.0f} dB under normal "
         f"conditions at the Wallops NEN station. The largest step, {d_traffic:.0f} dB, is going from a perfectly "
         f"placed drone to random traffic. Counting over all time gives {v['D1']:.0f} dB; a 20 dB apportionment "
         f"gives {v['D2']:.0f} dB. Both stay below the allowance at 0 dB."),
    axes_rect=(0.08, 0.27, 0.88, 0.40),
)
ax = page.ax
floor = -70
for k, s in enumerate(steps):
    if s == "A":
        y0, y1, c = floor, v[s], ALERT
    elif s == "B":
        y0, y1, c = floor, v[s], ACCENT
    elif s in ("D1", "D2"):
        y0, y1, c = v["B"], v[s], LIGHT
    else:
        y0, y1, c = v[steps[k - 1]], v[s], CONTEXT
    ax.bar(k, y1 - y0, bottom=y0, width=0.62, color=c, edgecolor=TEXT if s in ("D1", "D2") else "none",
           linewidth=0.8)
    up = y1 >= y0
    ax.annotate(f"{v[s]:+.0f} dB", (k, y1), xytext=(0, 4 if up else -4), textcoords="offset points",
                ha="center", va="bottom" if up else "top", fontsize=10.5, fontweight="bold",
                color=ALERT if s == "A" else TEXT)
ax.axhline(0, color=TEXT, lw=1.4, ls="--")
ax.annotate("Allowance", (7.45, 0), xytext=(0, 4), textcoords="offset points", ha="right", va="bottom",
            fontsize=10, fontweight="bold")
ax.set_xticks(range(len(steps)), [notes[s] for s in steps], fontsize=9.5)
ax.set_ylim(floor, 55)
ax.set_xlim(-0.6, len(steps) - 0.4)
ax.set_ylabel("dB relative to the allowance")
ax.grid(axis="y", color="#E6E6E6")
ax.set_axisbelow(True)
page.save("viz02_bridge", [ALERT, ACCENT, CONTEXT, LIGHT, TEXT])
