%RUN_ALL_VIZ_REV1 Rebuild the three MATLAB figures (3, 4, 5) of the data visualization plan.
%   Run from any folder:  matlab -batch "run('matlab/viz/run_all_viz_rev1.m')"
%   The Python figures rebuild with:  python python/viz/run_all.py
%   Requires itu_p528 cloned next to this repository (for the P.528 table).
here = fileparts(mfilename('fullpath'));
run(fullfile(here, 'viz03_plan_view_rev1.m'));
run(fullfile(here, 'viz04_side_view_rev1.m'));
run(fullfile(here, 'viz05_beam_dwell_rev1.m'));
