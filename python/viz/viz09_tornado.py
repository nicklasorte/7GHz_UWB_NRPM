"""Figure 9. What could move the normal-conditions result at the NASA station."""

from ntia_style import ACCENT, CONTEXT, TEXT, Page, num, read_csv

tor = read_csv("tornado_wallops.csv")
br = {r["step"]: num(r["ratio_dB"]) for r in read_csv("bridge_wallops.csv")}
base = br["B"]
ends = {"UWB duty cycle": ("0.25%", "5%"), "Share of drones carrying UWB": ("10%", "100%"),
        "Drone density": ("Average", "Peak x6"), "Device EIRP": ("Lowest measured", "At the limit"),
        "Time basis": ("All time", "Tracking time"), "Apportionment": ("None", "20 dB")}
worst = max(max(num(r["result_low"]), num(r["result_high"])) for r in tor)

page = Page(
    headline=f"No single assumption brings the NASA station within {-worst:.0f} dB of the allowance",
    subhead=(f"Wallops NEN 11.3 m, normal conditions ({base:.0f} dB relative to the short-term allowance). Each bar "
             f"moves one input across its range and holds the others at the base case: AirTag-measured EIRP, 1% duty "
             f"cycle, every drone carrying UWB, average density, tracking-time basis, no apportionment."),
    source=("Source: nicklasorte/7GHz_UWB_NRPM, example_bridge_rev1.m, run of November 11, 2026 "
            "(docs/bridge_results/tornado_wallops.csv). Duty-cycle range from ECC Report 327 Table 18."),
    alt=(f"Tornado chart of six inputs around the Wallops normal-conditions result of {base:.0f} dB. The widest bar "
         f"is the 20 dB apportionment, which reaches {worst:.0f} dB. Every bar stays well left of the allowance "
         f"at 0 dB, drawn on the same axis."),
    axes_rect=(0.26, 0.15, 0.68, 0.52),
)
ax = page.ax
rows = sorted(tor, key=lambda r: num(r["span"]))
for k, r in enumerate(rows):
    lo, hi = num(r["result_low"]), num(r["result_high"])
    a, b = min(lo, hi), max(lo, hi)
    ax.barh(k, b - a, left=a, height=0.55, color=ACCENT if k == len(rows) - 1 else CONTEXT)
    el, eh = ends.get(r["input"], ("", ""))
    ax.annotate(el, (lo, k), xytext=(-5 if lo <= hi else 5, 0), textcoords="offset points",
                ha="right" if lo <= hi else "left", va="center", fontsize=9.5)
    ax.annotate(eh, (hi, k), xytext=(5 if hi >= lo else -5, 0), textcoords="offset points",
                ha="left" if hi >= lo else "right", va="center", fontsize=9.5)
ax.axvline(base, color=TEXT, lw=1.2)
ax.annotate(f"Base case {base:.0f} dB", (base, len(rows) - 0.35), xytext=(0, 4), textcoords="offset points",
            ha="center", va="bottom", fontsize=10, fontweight="bold")
ax.axvline(0, color=TEXT, lw=1.4, ls="--")
ax.annotate("Allowance", (0, len(rows) - 0.35), xytext=(0, 4), textcoords="offset points", ha="center",
            va="bottom", fontsize=10, fontweight="bold")
ax.annotate(f"{-worst:.0f} dB of margin\nin the worst single case", (worst / 2, 1.5), ha="center", va="center",
            fontsize=10.5, color=TEXT)
ax.annotate("", (0, 1.0), (worst, 1.0), arrowprops=dict(arrowstyle="<->", color=TEXT, lw=1))
ax.set_yticks(range(len(rows)), [r["input"] for r in rows], fontsize=10.5)
ax.set_xlim(-72, 5)
ax.set_ylim(-0.7, len(rows) + 0.2)
ax.set_xlabel("dB relative to the short-term allowance")
ax.spines["left"].set_visible(False)
ax.tick_params(axis="y", length=0)
ax.grid(axis="x", color="#E6E6E6")
ax.set_axisbelow(True)
page.save("viz09_tornado", [ACCENT, CONTEXT, TEXT])
