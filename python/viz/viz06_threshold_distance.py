"""Figure 6. How close one drone has to be, by angle off the boresight of the Wallops dish."""

import re

import numpy as np

from ntia_style import ACCENT, CONTEXT, LIGHT, PANEL, RESULTS, TEXT, Page, num, read_csv

td = read_csv("threshold_distance_wallops.csv")
phi = np.array([num(r["off_axis_deg"]) for r in td])
ds = np.array([num(r["d_short_m"]) for r in td])
dl = np.array([num(r["d_long_m"]) for r in td])
da = np.array([num(r["d_short_app20_m"]) for r in td])
half = phi[np.array([r["region"] for r in td]) == "main beam"].max()
txt = (RESULTS / "run_log_bridge_rev1.txt").read_text(encoding="utf-8")   # the 5 deg reach is printed in the run log
reach_km = float(re.search(r"boresight of a 5 deg pass only out to ([0-9.]+) km", txt).group(1))
at = {a: ds[np.argmin(abs(phi - a))] for a in (1, 5, 20)}

page = Page(
    headline=(f"Off the main beam, the distance collapses: one drone must be within {at[1]:.0f} m at 1° off "
              f"boresight, {at[5]:.0f} m at 5°, and {at[20]:.0f} m at 20°"),
    subhead=(f"Wallops NEN 11.3 m (ITU-R SA.509-3 pattern), EESS 8160 MHz. Slant distance inside which one drone at "
             f"400 ft exceeds the short-term criterion whenever it transmits; AirTag-measured EIRP, 3 dB polarization "
             f"loss, P.528 median loss. Distance doesn't depend on duty cycle."),
    source=("Source: nicklasorte/7GHz_UWB_NRPM, threshold_distance_rev1.m via example_bridge_rev1.m, run of "
            "November 11, 2026 (docs/bridge_results/threshold_distance_wallops.csv)."),
    alt=(f"Log-log line chart of threshold distance against off-axis angle at the Wallops NEN dish. On boresight "
         f"the short-term distance is {ds[phi == 0][0] / 1000:.1f} km, but a 400 ft drone can only reach the "
         f"boresight of a 5 degree pass within {reach_km:.2f} km. The distance falls to {at[1]:.0f} m at 1 degree, "
         f"{at[5]:.0f} m at 5 degrees, and {at[20]:.0f} m at 20 degrees. Gray lines show the long-term criterion and "
         f"the 20 dB apportionment case."),
    axes_rect=(0.09, 0.15, 0.86, 0.55),
)
ax = page.ax
x = np.maximum(phi, 0.01)
ax.axvspan(0.009, half, color=PANEL, zorder=0)
ax.text(0.0105, 1.6, "Main beam", fontsize=10, color=TEXT, va="bottom")
ax.plot(x, dl, color=LIGHT, lw=1.6, zorder=2)
ax.plot(x, da, color=CONTEXT, lw=1.6, ls="--", zorder=2)
ax.plot(x, ds, color=ACCENT, lw=3, marker="o", ms=6, zorder=3)
ax.axhline(reach_km * 1000, color=TEXT, lw=1.2, ls=":")
ax.annotate(f"A 400 ft drone meets the boresight\nof a 5° pass only out to {reach_km:.2f} km",
            (0.0105, reach_km * 1000), xytext=(0, -5), textcoords="offset points", fontsize=9.5, va="top")
i05 = int(np.argmin(abs(phi - 0.5)))
i10 = int(np.argmin(abs(phi - 10)))
ax.annotate("Long-term criterion (solid gray): one drone\ncan't exceed it below 20% duty", (x[i05], dl[i05]),
            xytext=(14, -6), textcoords="offset points", fontsize=9.5, color=CONTEXT, va="top",
            bbox=dict(fc="white", ec="none", pad=1.5))
ax.annotate("Short-term, 20 dB\napportionment (dashed)", (x[i10], da[i10]), xytext=(10, 8), textcoords="offset points",
            fontsize=9.5, color=CONTEXT)
for a in (1, 5, 20):
    i = int(np.argmin(abs(phi - a)))
    ax.annotate(f"{ds[i]:.0f} m", (x[i], ds[i]), xytext=(-8, -14), textcoords="offset points", ha="right",
                fontsize=10.5, fontweight="bold", color=TEXT)
ax.annotate(f"Short-term criterion\n{ds[phi == 0][0] / 1000:.1f} km on boresight", (x[0], ds[0]), xytext=(8, -30),
            textcoords="offset points", fontsize=10.5, fontweight="bold", color=TEXT)
ax.set_xscale("log")
ax.set_yscale("log")
ax.set_xlim(0.009, 100)
ax.set_ylim(1, 1e5)
ax.set_xlabel("Angle off the dish boresight (degrees; boresight drawn at 0.01)")
ax.set_ylabel("Distance (m)")
ax.grid(which="major", color="#E6E6E6")
ax.set_axisbelow(True)
page.save("viz06_threshold_distance", [ACCENT, CONTEXT, LIGHT, TEXT])
