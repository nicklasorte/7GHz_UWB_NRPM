"""Rebuild the seven Python figures (1, 2, 6, 7, 8, 9, 10) of the data visualization plan.

Run from the repository root:  python python/viz/run_all.py
Each script reads the published CSV files in docs/bridge_results/ and writes
PNG, PDF, SVG, alt text, and lint metadata to docs/figures/viz/. The script
exits with status 1 if any figure reports a lint error.
"""

import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPTS = ["viz01_barbell.py", "viz02_bridge.py", "viz06_threshold_distance.py", "viz07_duty_evidence.py",
           "viz08_hours_to_allowance.py", "viz09_tornado.py", "viz10_two_stations.py"]

errors = 0
for name in SCRIPTS:
    out = subprocess.run([sys.executable, str(HERE / name)], cwd=HERE, capture_output=True, text=True)
    print(out.stdout.strip())
    if out.returncode != 0 or "[error]" in out.stdout:
        errors += 1
        print(out.stderr.strip())
sys.exit(1 if errors else 0)
