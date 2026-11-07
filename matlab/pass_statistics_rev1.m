function ps = pass_statistics_rev1(site, opts)
%PASS_STATISTICS_REV1 Earth station pointing time series from real LEO passes (SGP4).
%   ps = PASS_STATISTICS_REV1(site) propagates public two-line elements for
%   the listed satellites with satelliteScenario (SGP4), computes azimuth
%   and elevation from the site, and models the dish as tracking the
%   highest-priority satellite in view above the minimum elevation. When no
%   satellite is in view the dish is idle and not receiving.
%
%   site: struct with name, lat_deg, lon_deg, alt_m.
%
%   Name-value options:
%     norad_ids      NORAD catalog numbers in priority order
%                    (default Aqua 27424, Terra 25994, Landsat 8 39084, Landsat 9 49260)
%     start_utc      datetime (default 2026-11-01 00:00 UTC)
%     duration_days  default 30
%     sample_s       default 20
%     el_min_deg     default 5 (ITU-R SA.1026-5)
%     tle_file       cached TLE file (default ../data/tle_eess.txt); fetched
%                    from CelesTrak (celestrak.org/NORAD/elements/gp.php) if missing
%
%   ps fields: t (datetime), tracking (logical), az_deg, el_deg, sat_idx,
%   frac_tracking, el_edges_deg, el_hist_frac (share of tracking time per
%   elevation bin), frac_tracking_below_6deg, site, norad_ids, tle_file.
arguments
    site struct
    opts.norad_ids (1,:) double = [27424 25994 39084 49260]
    opts.start_utc (1,1) datetime = datetime(2026, 11, 1, 0, 0, 0, 'TimeZone', 'UTC')
    opts.duration_days (1,1) double {mustBePositive} = 30
    opts.sample_s (1,1) double {mustBePositive} = 20
    opts.el_min_deg (1,1) double = 5
    opts.tle_file (1,1) string = string(fullfile(fileparts(mfilename('fullpath')), '..', 'data', 'tle_eess.txt'))
end
if ~isfile(opts.tle_file)
    fetch_tles(opts.norad_ids, opts.tle_file);
end
sc = satelliteScenario(opts.start_utc, opts.start_utc + days(opts.duration_days), opts.sample_s);
sats = satellite(sc, char(opts.tle_file));
names = strings(1, numel(sats));
for k = 1:numel(sats), names(k) = string(sats(k).Name); end
gs = groundStation(sc, site.lat_deg, site.lon_deg, 'Altitude', site.alt_m, 'Name', site.name);

n_s = numel(opts.norad_ids);
if numel(sats) ~= n_s
    error('pass_statistics_rev1:tleCount', 'TLE file has %d satellites; expected %d (one per NORAD ID, in priority order).', numel(sats), n_s);
end
[~, ~, ~, t] = aer(gs, sats(1));
n_t = numel(t);
AZ = zeros(n_s, n_t); EL = zeros(n_s, n_t);
for k = 1:n_s                                        % TLE file order = priority order
    [AZ(k, :), EL(k, :)] = aer(gs, sats(k));
end

in_view = EL >= opts.el_min_deg;
tracking = any(in_view, 1);
[~, first] = max(in_view, [], 1);                    % highest priority in view
idx = sub2ind(size(EL), first, 1:n_t);
ps.t = t(:);
ps.tracking = tracking(:);
ps.sat_idx = first(:) .* tracking(:);
ps.az_deg = AZ(idx)'; ps.el_deg = EL(idx)';
ps.az_deg(~tracking) = NaN; ps.el_deg(~tracking) = NaN;
ps.frac_tracking = mean(tracking);
ps.el_edges_deg = [opts.el_min_deg 6 8 10 13 20 30 45 60 90];
ps.el_hist_frac = histcounts(ps.el_deg(tracking), ps.el_edges_deg) / nnz(tracking);
ps.frac_tracking_below_6deg = mean(ps.el_deg(tracking) < 6);
ps.site = site;
ps.norad_ids = opts.norad_ids;
ps.sat_names = names;
ps.tle_file = opts.tle_file;
ps.start_utc = opts.start_utc;
ps.duration_days = opts.duration_days;
end

function fetch_tles(ids, file)
folder = fileparts(file);
if ~isfolder(folder), mkdir(folder); end
txt = strings(0, 1);
for id = ids
    url = sprintf('https://celestrak.org/NORAD/elements/gp.php?CATNR=%d&FORMAT=TLE', id);
    t = webread(url, weboptions('Timeout', 30));
    lines = strtrim(splitlines(string(t)));
    lines = lines(strlength(lines) > 0);
    if numel(lines) < 3
        error('pass_statistics_rev1:tleFetch', 'CelesTrak returned no TLE for NORAD %d.', id);
    end
    txt = [txt; lines(1:3)]; %#ok<AGROW> four satellites
end
writelines(txt, file);
end
