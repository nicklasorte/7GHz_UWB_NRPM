function out = single_entry_separation_rev1(p, h_d_m, el_point_deg, f_MHz, opts)
%SINGLE_ENTRY_SEPARATION_REV1 Worst-case separation for one hovering UWB drone.
%   out = SINGLE_ENTRY_SEPARATION_REV1(p, h_d_m, el_point_deg, f_MHz) places one
%   drone at altitude h_d_m in the ES pointing azimuth (worst case) and sweeps
%   ground distance. It reports the largest distance at which interference
%   exceeds the long-term criterion (a hovering drone is present >20% of the
%   time) and the short-term criterion (a transiting drone), using the
%   ITU-R SA.509-3 single-entry pattern.
%
%   out.d_km, out.i_dBm(n_alt, n_el, n_d), out.sep_long_km(n_alt, n_el),
%   out.sep_short_km(n_alt, n_el), out.crit
arguments
    p struct
    h_d_m (:,1) double
    el_point_deg (1,:) double
    f_MHz (1,1) double
    opts.d_km (1,:) double = [0.01:0.01:5, 5.05:0.05:60]
end
crit = eess_criteria_rev1(f_MHz, p);
d = opts.d_km;
n_alt = numel(h_d_m); n_el = numel(el_point_deg);
i_dBm = NaN(n_alt, n_el, numel(d));
sep_long = NaN(n_alt, n_el);
sep_short = NaN(n_alt, n_el);
for a = 1:n_alt
    for e = 1:n_el
        i_row = uwb_to_es_interference_rev1(p, d, repmat(h_d_m(a), size(d)), zeros(size(d)), ...
            el_point_deg(e), f_MHz, "single");
        i_dBm(a, e, :) = i_row;
        sep_long(a, e)  = last_exceed(d, i_row, crit.long_dBm);
        sep_short(a, e) = last_exceed(d, i_row, crit.short_dBm);
    end
end
out.d_km = d;
out.h_d_m = h_d_m;
out.el_point_deg = el_point_deg;
out.i_dBm = i_dBm;
out.sep_long_km = sep_long;
out.sep_short_km = sep_short;
out.crit = crit;
end

function s = last_exceed(d, i_row, lim)
k = find(i_row > lim, 1, 'last');
if isempty(k)
    s = 0;
elseif k == numel(d)
    error('single_entry_separation_rev1:grid', ...
        'Interference exceeds the criterion at the end of the distance grid (%.1f km); extend opts.d_km.', d(end));
else
    s = d(k+1);
end
end
