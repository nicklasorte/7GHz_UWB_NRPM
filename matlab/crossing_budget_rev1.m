function cb = crossing_budget_rev1(area_km2, chord_km, tracking_frac, allowance_pct, opts)
%CROSSING_BUDGET_REV1 Turn the short-term time allowance into drone traffic and crossings.
%   cb = CROSSING_BUDGET_REV1(area_km2, chord_km, tracking_frac, allowance_pct)
%   uses the single-drone exceedance footprint (area_km2, averaged over the
%   dish pointing while it tracks) and the mean chord of the exceedance
%   region (chord_km) to answer "how much drone traffic uses up the
%   allowance?"
%
%   The time one drone spends inside the footprint, summed over a year,
%   depends only on how long drones are airborne per unit area and on the
%   footprint area, not on their speed: with airborne density rho (drones
%   per km^2, averaged over the year) and UWB duty cycle u,
%
%     exceedance time = rho * u * area * (tracking time per year)        (1)
%
%   Speed sets how that time is split into events: each crossing lasts
%   chord / v. So the paper reports both:
%
%     allowed density  rho_allow = T_allow / (u * area * T_track)        (2)
%     dwell per crossing        = chord / v                               (3)
%     allowed crossings a year  = T_allow / dwell                         (4)
%
%   T_allow is allowance_pct of tracking time ("tracking" basis) or of all
%   time ("all" basis). Equation (1) is the low-density (Poisson thinning)
%   limit; it holds while rho * area << 1.
%
%   Name-value options:
%     basis          "tracking" (default) or "all"
%     duty           UWB duty cycle as a fraction (default 1)
%     speeds_mps     drone speeds (default [5 10 20])
%     density_per_km2  local airborne density to compare (default NaN)
%
%   Fields: T_allow_s, T_track_s, rho_allow_per_km2,
%   drone_hours_allow_per_km2 (rho_allow times hours in a year),
%   table (speed, dwell_s, crossings_allowed, crossings_expected),
%   expected_exceed_s, ratio_to_allowance (NaN without a density).
arguments
    area_km2 (1,1) double {mustBeNonnegative}
    chord_km (1,1) double {mustBeNonnegative}
    tracking_frac (1,1) double {mustBeInRange(tracking_frac, 0, 1)}
    allowance_pct (1,1) double {mustBePositive}
    opts.basis (1,1) string {mustBeMember(opts.basis, ["tracking", "all"])} = "tracking"
    opts.duty (1,1) double {mustBeInRange(opts.duty, 0, 1)} = 1
    opts.speeds_mps (1,:) double {mustBePositive} = [5 10 20]
    opts.density_per_km2 (1,1) double = NaN
end
year_s = 365.25 * 86400;
cb.T_track_s = tracking_frac * year_s;
if opts.basis == "tracking"
    cb.T_allow_s = allowance_pct / 100 * cb.T_track_s;
else
    cb.T_allow_s = allowance_pct / 100 * year_s;
end
denom = opts.duty * area_km2 * cb.T_track_s;
cb.rho_allow_per_km2 = cb.T_allow_s / denom;
cb.drone_hours_allow_per_km2 = cb.rho_allow_per_km2 * year_s / 3600;
dwell = 1000 * chord_km ./ opts.speeds_mps;
cb.expected_exceed_s = opts.density_per_km2 * denom;
cb.ratio_to_allowance = cb.expected_exceed_s / cb.T_allow_s;
cb.table = table(opts.speeds_mps(:), dwell(:), cb.T_allow_s ./ dwell(:), cb.expected_exceed_s ./ dwell(:), ...
    'VariableNames', {'speed_mps', 'dwell_s', 'crossings_allowed', 'crossings_expected'});
cb.settings = opts;
cb.inputs = struct('area_km2', area_km2, 'chord_km', chord_km, 'tracking_frac', tracking_frac, 'allowance_pct', allowance_pct);
end
