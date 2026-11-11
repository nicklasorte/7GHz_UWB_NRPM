function br = bridge_steps_rev1(ing)
%BRIDGE_STEPS_REV1 Walk from the boresight worst case to normal conditions, one assumption at a time.
%   br = BRIDGE_STEPS_REV1(ing) returns a table, one row per step, of the
%   share of time above the short-term criterion and its ratio to the
%   allowance in dB (10 log10 of the ratio; 0 dB = exactly at the
%   allowance). Each step changes one assumption and keeps the earlier
%   changes.
%
%   ing fields (all from model runs):
%     margin_bore_dB    boresight margin of one drone at the limit (beam_dwell_rev1)
%     hover_frac_trk    share of tracking time for a drone hovering at the
%                       ideal spot before every pass (beam_dwell_rev1)
%     rho_per_km2       local airborne drone density
%     uwb_share         share of drones carrying UWB
%     area_limit_km2    single-drone short-term footprint, device at the limit
%     area_meas_km2     footprint, measured device EIRP
%     area_app_km2      footprint, measured EIRP and the apportioned criterion
%     duty              UWB duty cycle (fraction)
%     tracking_frac     share of all time the dish tracks
%     allowance_pct     short-term allowance (percent of time)
%     labels            optional struct of display strings (see below)
%
%   Steps:
%     A  One drone follows the beam (hypothetical): 1 if margin > 0
%     1  It hovers at the ideal fixed spot; the tracking beam sweeps past
%     2  Random positions at normal altitudes, local traffic, at the limit
%     3  Measured device EIRP
%     4  UWB duty cycle
%     B  = step 4 (normal conditions, tracking-time basis, full criterion)
%     D1 Decision: count over all time instead of tracking time (from B)
%     D2 Decision: 20 dB apportionment, tracking-time basis (from B; moves
%        toward interference)
%
%   Fractions use the Poisson form 1 - exp(-rho * share * area) and then
%   multiply by the duty cycle, which treats transmissions as independent
%   of position.
arguments
    ing struct
end
need = ["margin_bore_dB", "hover_frac_trk", "rho_per_km2", "uwb_share", "area_limit_km2", ...
    "area_meas_km2", "area_app_km2", "duty", "tracking_frac", "allowance_pct"];
miss = need(~isfield(ing, need));
if ~isempty(miss)
    error('bridge_steps_rev1:missing', 'Missing input fields: %s.', strjoin(miss, ', '));
end
allow = ing.allowance_pct / 100;
rho = ing.rho_per_km2 * ing.uwb_share;
f = zeros(8, 1);
f(1) = double(ing.margin_bore_dB > 0);
f(2) = min(ing.hover_frac_trk, 1);
f(3) = 1 - exp(-rho * ing.area_limit_km2);
f(4) = 1 - exp(-rho * ing.area_meas_km2);
f(5) = ing.duty * f(4);
f(6) = f(5);
f(7) = f(6) * ing.tracking_frac;                      % share of all time, against an all-time allowance
f(8) = ing.duty * (1 - exp(-rho * ing.area_app_km2));   % from B: tracking-time basis, apportioned criterion
step = ["A"; "1"; "2"; "3"; "4"; "B"; "D1"; "D2"];
label = ["A: one drone follows the beam, at the limit, continuous (hypothetical)"; ...
         "1: hovers at the ideal spot; the tracking beam sweeps past"; ...
         "2: random positions, local traffic, device at the limit"; ...
         "3: measured device EIRP"; ...
         "4: UWB duty cycle"; ...
         "B: normal conditions (tracking-time basis, full criterion)"; ...
         "Decision 1: count over all time"; ...
         "Decision 2: 20 dB apportionment"];
short = ["A: on boresight," + newline + "follows the beam"; "1: hovers; beam" + newline + "sweeps past"; ...
         "2: random position," + newline + "local traffic"; "3: measured" + newline + "device EIRP"; ...
         "4: duty cycle" + newline + sprintf("(%g%%)", 100 * ing.duty); "B: normal" + newline + "conditions"; ...
         "D1: count over" + newline + "all time"; "D2: 20 dB" + newline + "apportionment"];
kind = ["physics"; "physics"; "physics"; "physics"; "physics"; "result"; "decision"; "decision"];
ratio_dB = 10 * log10(max(f / allow, realmin));
ratio_dB(f == 0) = -Inf;
br = table(step, label, short, kind, f, f / allow, ratio_dB, ...
    'VariableNames', {'step', 'label', 'short_label', 'kind', 'frac_above', 'ratio_to_allowance', 'ratio_dB'});
end
