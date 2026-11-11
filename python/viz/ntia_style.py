"""Shared page style for the UWB channel 9 figures: NTIA palette, one accent, direct labels.

Each figure is a one-page landscape chart with a headline (the takeaway, not a
topic), a subhead (units and scope), a source line, the DRAFT//PRE-DECISIONAL
marking, and alt text. ``save`` writes PNG (300 dpi), PDF, and SVG, an
``.alt.txt`` file, and a ``.meta.json`` file with simple lint results (text
overlap, text off the page, font sizes below 8 pt).

Palette: dark blue text, gray context marks, light blue accent for the hero
mark, purple for the worst case or alert. Bars start at zero; no dual axes.
"""

from __future__ import annotations

import csv
import itertools
import json
import textwrap
from dataclasses import dataclass, field
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.text import Text  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
RESULTS = REPO / "docs" / "bridge_results"
OUT = REPO / "docs" / "figures" / "viz"

TEXT = "#163353"
ACCENT = "#5674C4"
ALERT = "#6E4F92"
CONTEXT = "#8A8D91"
LIGHT = "#C9CCD0"
GRID = "#E6E6E6"
PANEL = "#E8E9EA"
MARKING = "DRAFT//PRE-DECISIONAL"
MIN_PT = 8

matplotlib.rcParams.update({
    "font.family": "serif",
    "font.serif": ["Times New Roman", "Times", "Liberation Serif", "DejaVu Serif"],
    "font.size": 11,
    "text.color": TEXT,
    "axes.labelcolor": TEXT,
    "axes.edgecolor": CONTEXT,
    "axes.titlecolor": TEXT,
    "xtick.color": TEXT,
    "ytick.color": TEXT,
    "xtick.labelsize": 10,
    "ytick.labelsize": 10,
    "axes.labelsize": 11,
    "axes.spines.top": False,
    "axes.spines.right": False,
    "axes.grid": False,
    "grid.color": GRID,
    "pdf.fonttype": 42,
    "svg.fonttype": "none",
})


def read_csv(name: str, folder: Path = RESULTS) -> list[dict]:
    """Read one published result table as a list of dicts (strings)."""
    with open(folder / name, newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def num(x: str) -> float:
    return float("nan") if x in ("", "NaN", "nan") else float(x)


@dataclass
class Page:
    """A landscape one-page figure with headline, subhead, source, and marking."""

    headline: str
    subhead: str
    source: str
    alt: str
    size: tuple = (11.0, 7.0)
    axes_rect: tuple = (0.09, 0.15, 0.86, 0.60)
    fig: plt.Figure = field(init=False)
    ax: plt.Axes = field(init=False)

    def __post_init__(self):
        self.fig = plt.figure(figsize=self.size, facecolor="white")
        w = self.size[0]
        wrap = int(w * 7.2)
        self.fig.text(0.04, 0.955, MARKING, fontsize=10, color=ALERT, fontweight="bold", va="top")
        self.fig.text(0.04, 0.915, "\n".join(textwrap.wrap(self.headline, wrap)), fontsize=19,
                      fontweight="bold", va="top", linespacing=1.15)
        n_head = len(textwrap.wrap(self.headline, wrap))
        self.fig.text(0.04, 0.915 - 0.052 * n_head - 0.01, "\n".join(textwrap.wrap(self.subhead, int(w * 11))),
                      fontsize=12, va="top", color=TEXT)
        self.fig.text(0.04, 0.03, "\n".join(textwrap.wrap(self.source, int(w * 15))), fontsize=9, va="bottom",
                      color=TEXT)
        self.ax = self.fig.add_axes(self.axes_rect)

    def lint(self) -> list[dict]:
        issues = []
        self.fig.canvas.draw()
        r = self.fig.canvas.get_renderer()
        hidden = set()                                  # tick labels outside the axis range are kept but not drawn
        for a in self.fig.axes:
            for axis, lim in ((a.xaxis, a.get_xlim()), (a.yaxis, a.get_ylim())):
                lo, hi = min(lim), max(lim)
                for tick in axis.get_major_ticks() + axis.get_minor_ticks():
                    if not (lo - 1e-9 <= tick.get_loc() <= hi + 1e-9):
                        hidden.update({id(tick.label1), id(tick.label2)})
        texts = [t for t in self.fig.findobj(Text) if t.get_visible() and t.get_text().strip()
                 and id(t) not in hidden]
        boxes = []
        W, H = self.fig.bbox.width, self.fig.bbox.height
        for t in texts:
            if t.get_fontsize() < MIN_PT - 1e-6:
                issues.append({"severity": "error", "message": f"Text below {MIN_PT} pt: {t.get_text()[:40]!r}"})
            bb = t.get_window_extent(r)
            if bb.x0 < -1 or bb.y0 < -1 or bb.x1 > W + 1 or bb.y1 > H + 1:
                issues.append({"severity": "error", "message": f"Text off the page: {t.get_text()[:40]!r}"})
            boxes.append((t, bb))
        for (a, ba), (b, bb) in itertools.combinations(boxes, 2):
            if ba.overlaps(bb):
                ox = min(ba.x1, bb.x1) - max(ba.x0, bb.x0)
                oy = min(ba.y1, bb.y1) - max(ba.y0, bb.y0)
                if ox > 2 and oy > 2:
                    issues.append({"severity": "error",
                                   "message": f"Text overlap: {a.get_text()[:30]!r} and {b.get_text()[:30]!r}"})
        return issues

    def save(self, stem: str, mark_colors: list[str]) -> dict:
        OUT.mkdir(parents=True, exist_ok=True)
        issues = self.lint()
        base = OUT / stem
        for fmt in ("png", "pdf", "svg"):
            meta_kw = {"Title": self.headline, ("Subject" if fmt == "pdf" else "Description"): self.alt}
            self.fig.savefig(base.with_suffix(f".{fmt}"), dpi=300, facecolor="white", metadata=meta_kw)
        base.with_suffix(".alt.txt").write_text(self.alt + "\n", encoding="utf-8")
        sizes = sorted({round(t.get_fontsize(), 1) for t in self.fig.findobj(Text)
                        if t.get_visible() and t.get_text().strip()})
        meta = {"theme": "ntia", "page_inches": list(self.size), "dpi": 300, "background": "#FFFFFF",
                "marking": MARKING, "font_sizes_pt": sizes, "mark_colors": sorted(set(mark_colors)),
                "accent": ACCENT, "context": CONTEXT, "alt": self.alt, "alt_supplied": True, "lint": issues}
        base.with_suffix(".meta.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
        for i in issues:
            print(f"[{i['severity']}] {stem}: {i['message']}")
        print(f"Saved {base}.png/.pdf/.svg")
        plt.close(self.fig)
        return meta


def label(ax, x, y, s, color=TEXT, **kw):
    """Direct label next to a mark."""
    kw.setdefault("fontsize", 10)
    return ax.annotate(s, (x, y), color=color, **kw)
