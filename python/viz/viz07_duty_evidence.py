"""Figure 7. The duty cycles every study in this band assumes, against the duty cycle that would reach the allowance."""

import numpy as np

from ntia_style import ACCENT, ALERT, CONTEXT, REPO, TEXT, Page, num, read_csv

cit = read_csv("duty_cycle_citations.csv", REPO / "docs")
be_c = read_csv("duty_break_even_ccny.csv")
be_w = read_csv("duty_break_even_wallops.csv")
app_avg = next(num(r["break_even_duty_pct"]) for r in be_c
               if r["density"] == "Annual average" and "apportionment" in r["case"])
app_peak = next(num(r["break_even_duty_pct"]) for r in be_c
                if r["density"].startswith("Sustained") and "apportionment" in r["case"])
wal_none = all(r["continuous_stays_under"] in ("1", "true", "True") for r in be_w)
top = max(num(r["activity_pct"]) for r in cit)

sources = list(dict.fromkeys(r["source"] for r in cit))
page = Page(
    headline=(f"Every study in this band assumes {top:.0f}% or less; reaching the allowance takes {app_avg:.1f}% in "
              f"Manhattan, and no duty cycle reaches it at the NASA station"),
    subhead=("UWB activity factors and duty cycles used in compatibility studies of 6-8.5 GHz UWB, percent of time, "
             "log scale. The vertical lines are the duty cycles at which every drone carrying UWB would use up the "
             "short-term allowance, with the 20 dB apportionment and average density."),
    source=("Sources: ECC Report 327 (2021); CEPT Report 9 (2005); ECC Report 94 (2006); FiRa UWB Simulation Report "
            "(2025); FCC 26-66 NPRM (2026). Break-even: nicklasorte/7GHz_UWB_NRPM, example_bridge_rev1.m, run of "
            "November 11, 2026 (docs/duty_cycle_citations.csv, docs/bridge_results/duty_break_even_*.csv)."),
    alt=(f"Dot strip chart of cited UWB activity factors from 0.006% to {top:.0f}%, one row per source. A line at "
         f"{app_avg:.1f}% marks the duty cycle that would reach the allowance at CCNY with the 20 dB apportionment, "
         f"above every cited value. A dashed line at {app_peak:.1f}% marks the same case at a sustained peak density. "
         f"At the NASA Wallops station, no duty cycle up to continuous transmission reaches the allowance."),
    axes_rect=(0.26, 0.20, 0.70, 0.46),
)
ax = page.ax
ys = {s: len(sources) - 1 - i for i, s in enumerate(sources)}
for s in sources:
    xs = [num(r["activity_pct"]) for r in cit if r["source"] == s]
    ax.scatter(xs, [ys[s]] * len(xs), s=70, color=CONTEXT, edgecolor=TEXT, linewidth=0.6, zorder=3)
    ax.plot([min(xs), max(xs)], [ys[s]] * 2, color=CONTEXT, lw=1, zorder=2)
fira6 = [r for r in cit if r["source"].startswith("FiRa") and num(r["activity_pct"]) == 6]
if fira6:
    ax.annotate("6% (one appendix table, outdoor vehicles)", (6, ys[fira6[0]["source"]]), xytext=(4, -12),
                textcoords="offset points", fontsize=9, va="top", ha="right",
                bbox=dict(fc="white", ec="none", pad=1.5))
nprm = [r for r in cit if r["source"].startswith("FCC")]
ax.annotate("Under 1% in any 24 hours\n(proposed new category)", (1, ys[nprm[0]["source"]]), xytext=(-8, 0),
            textcoords="offset points", fontsize=9, va="center", ha="right")
ax.axvline(app_avg, color=ALERT, lw=2.4, zorder=1)
ax.annotate(f"Manhattan break-even\n{app_avg:.1f}%", (app_avg, len(sources) - 0.55), xytext=(6, 0),
            textcoords="offset points", fontsize=10.5, fontweight="bold", color=ALERT, va="center")
ax.axvline(app_peak, color=ALERT, lw=1.2, ls="--", zorder=1)
ax.annotate(f"{app_peak:.1f}% at a sustained\npeak density (x6)", (app_peak, -0.62), xytext=(6, 0),
            textcoords="offset points", fontsize=9.5, color=ALERT, va="center")
if wal_none:
    ax.annotate("NASA Wallops:\nno break-even up to\ncontinuous (100%)", (100, len(sources) - 2.5),
                xytext=(-6, 0), textcoords="offset points", ha="right", va="center", fontsize=10.5,
                fontweight="bold", color=ACCENT)
ax.set_yticks([ys[s] for s in sources], sources, fontsize=10.5)
ax.set_xscale("log")
ax.set_xlim(0.003, 120)
ax.set_ylim(-1, len(sources))
ax.set_xticks([0.01, 0.1, 1, 10, 100], ["0.01%", "0.1%", "1%", "10%", "100%"])
ax.set_xlabel("Activity factor or duty cycle (percent of time)")
ax.spines["left"].set_visible(False)
ax.tick_params(axis="y", length=0)
ax.grid(axis="x", color="#E6E6E6")
ax.set_axisbelow(True)
page.save("viz07_duty_evidence", [CONTEXT, ALERT, ACCENT, TEXT])
