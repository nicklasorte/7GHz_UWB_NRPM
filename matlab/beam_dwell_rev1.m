function bd = beam_dwell_rev1(p, ps, F, f_mhz, opts)
%BEAM_DWELL_REV1 How long the tracking beam stays on a hovering drone placed on boresight.
%   bd = BEAM_DWELL_REV1(p, ps, F, f_mhz) answers the boresight worst case
%   (Bookend A) in time. For every tracking sample in the pass statistics
%   ps, it places one drone, hovering at height opts.h_drone_m, exactly on
%   the dish boresight at that moment, and computes:
%
%     1. The ground distance at which the boresight crosses the drone
%        height, d_bore, from the 4/3-Earth geometry.
%     2. The boresight margin: interference at boresight minus the
%        criterion, with P.528 loss at opts.p_time percent of time.
%     3. The exceedance cone: the off-axis angle phi_x at which the dish
%        gain has fallen by the margin, G(phi_x) = G0 - margin.
%     4. The dish angular rate omega, from successive pointing samples of
%        the same pass (great-circle angle between unit vectors over the
%        sample interval).
%     5. The dwell, 2 phi_x / omega: the time the moving beam keeps the
%        hovering drone inside the exceedance cone. The drone sits on the
%        beam's path, so this is the longest dwell for that moment.
%
%   Per pass, the worst placement is the sample with the longest dwell.
%   bd.hover_frac_trk is the sum of those per-pass maxima over total
%   tracking time: the share of tracking time above the criterion if a
%   drone were moved to the ideal spot before every pass. It is an upper
%   bound; a drone that stays at one spot is crossed by far fewer passes.
%
%   Name-value options:
%     h_drone_m   drone height above ground (default p.drone.h_max_m, 400 ft)
%     criterion   "short" (default) or "long"
%     p_time      P.528 time percentage (default 50)
%     eirp_offset_dB  reduction from the limit (default 0; measured AirTag 0.54)
%     crit_offset_dB  apportionment, subtracted from the criterion (default 0)
%     pattern     "single" (default; main lobe) or "multiple"
%
%   Outputs (fields): el_deg, omega_deg_s, d_bore_km, margin_dB, phi_x_deg,
%   dwell_s (one per tracking sample); pass (table: sat_idx, start, duration_s,
%   max_el_deg, max_dwell_s, el_at_max_dwell_deg); hover_frac_trk;
%   beamwidth_deg (3 dB, from the pattern); settings.
%
%   Built-ins considered: the satelliteScenario access and aer functions
%   give pointing but not beam dwell; the angular rate is computed here
%   from the pointing samples to avoid a second propagation.
arguments
    p struct
    ps struct
    F
    f_mhz (1,1) double {mustBePositive}
    opts.h_drone_m (1,1) double {mustBePositive} = p.drone.h_max_m
    opts.criterion (1,1) string {mustBeMember(opts.criterion, ["short", "long"])} = "short"
    opts.p_time (1,1) double {mustBeInRange(opts.p_time, 1, 99)} = 50
    opts.eirp_offset_dB (1,1) double = 0
    opts.crit_offset_dB (1,1) double = 0
    opts.pattern (1,1) string {mustBeMember(opts.pattern, ["single", "multiple"])} = "single"
end
if opts.h_drone_m <= p.es.h_m
    error('beam_dwell_rev1:belowDish', 'Drone height %.1f m is not above the dish height %.1f m; boresight is unreachable.', ...
        opts.h_drone_m, p.es.h_m);
end
crit = eess_criteria_rev1(f_mhz, p);
crit_dBm = crit.(opts.criterion + "_dBm") - opts.crit_offset_dB;
e10 = uwb_power_in_band_rev1(f_mhz, p.crit.ref_bw_MHz, p.uwb);
const_dB = e10 - opts.eirp_offset_dB - p.uwb.pol_loss_dB - p.es.site_shield_dB;
g0 = es_gain_rev1(0, p.es.diam_m, f_mhz, p.es.eff, opts.pattern);

% Main-lobe gain table, used to invert G(phi) = G0 - margin
phi_tab = logspace(-4, log10(20), 4000);
g_tab = es_gain_rev1(phi_tab, p.es.diam_m, f_mhz, p.es.eff, opts.pattern);
g_tab = cummin(g_tab);                               % monotone envelope, so the inverse is single-valued
[g_u, iu] = unique(g_tab, 'stable');
phi_u = phi_tab(iu);
phi_of_drop = @(drop) interp1(g0 - g_u, phi_u, drop, 'linear', NaN);
bw = 2 * phi_of_drop(3);

% Ground distance at which the boresight crosses the drone height
d_grid = logspace(log10(0.005), log10(200), 6000);
[~, el_grid, los] = air_to_ground_geometry_rev1(d_grid, p.es.h_m, opts.h_drone_m, p.prop.k_factor, p.prop.re_km);
keep = los(:)' & isfinite(el_grid(:)');
[el_s, is] = sort(el_grid(keep));
d_s = d_grid(keep); d_s = d_s(is);
[el_s, iu2] = unique(el_s);
d_s = d_s(iu2);

trk = ps.tracking(:);
el = ps.el_deg(:); az = ps.az_deg(:); sat = ps.sat_idx(:);
t_s = seconds(ps.t(:) - ps.t(1));
n = numel(el);

% Pass segmentation: contiguous tracking samples of one satellite
new_pass = trk & ([true; ~trk(1:end-1)] | [true; sat(2:end) ~= sat(1:end-1)]);
pass_id = cumsum(new_pass) .* trk;

% Angular rate from central differences within each pass
u = [cosd(el) .* sind(az), cosd(el) .* cosd(az), sind(el)];
omega = NaN(n, 1);
for k = 1:n
    if ~trk(k), continue, end
    a = k - 1; b = k + 1;
    if a < 1 || pass_id(a) ~= pass_id(k), a = k; end
    if b > n || pass_id(b) ~= pass_id(k), b = k; end
    if a == b, continue, end
    ang = acosd(min(max(dot(u(a, :), u(b, :)), -1), 1));
    omega(k) = ang / (t_s(b) - t_s(a));
end

d_bore = NaN(n, 1);
d_bore(trk) = interp1(el_s, d_s, el(trk), 'linear', NaN);
L = NaN(n, 1);
ok = trk & isfinite(d_bore);
L(ok) = F(log10(max(d_bore(ok), 0.02)), repmat(opts.h_drone_m, nnz(ok), 1), repmat(opts.p_time, nnz(ok), 1));
margin = const_dB + g0 - L - crit_dBm;
phi_x = zeros(n, 1);
pos = ok & margin > 0;
phi_x(pos) = phi_of_drop(margin(pos));
phi_x(pos & isnan(phi_x)) = phi_u(end);               % margin beyond the table: whole tabulated lobe
phi_x(~ok) = NaN;
dwell = 2 * phi_x ./ omega;
dwell(ok & margin <= 0) = 0;

% Per-pass worst placement
ids = unique(pass_id(pass_id > 0));
np = numel(ids);
pass = table('Size', [np 6], 'VariableTypes', {'double', 'datetime', 'double', 'double', 'double', 'double'}, ...
    'VariableNames', {'sat_idx', 'start', 'duration_s', 'max_el_deg', 'max_dwell_s', 'el_at_max_dwell_deg'});
dt = median(diff(t_s));
for j = 1:np
    m = find(pass_id == ids(j));
    [mx, im] = max(dwell(m), [], 'omitnan');
    if isempty(mx) || isnan(mx), mx = 0; im = 1; end
    pass.sat_idx(j) = sat(m(1));
    pass.start(j) = ps.t(m(1));
    pass.duration_s(j) = numel(m) * dt;
    pass.max_el_deg(j) = max(el(m));
    pass.max_dwell_s(j) = mx;
    pass.el_at_max_dwell_deg(j) = el(m(im));
end

bd.el_deg = el; bd.omega_deg_s = omega; bd.d_bore_km = d_bore; bd.margin_dB = margin;
bd.phi_x_deg = phi_x; bd.dwell_s = dwell;
bd.pass = pass;
bd.hover_frac_trk = sum(pass.max_dwell_s) / (nnz(trk) * dt);
bd.beamwidth_deg = bw;
bd.g0_dBi = g0;
bd.crit_dBm = crit_dBm;
bd.settings = opts;
end
