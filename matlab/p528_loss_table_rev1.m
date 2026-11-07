function [F, tbl] = p528_loss_table_rev1(f_mhz, h_es_m, opts)
%P528_LOSS_TABLE_REV1 Cached ITU-R P.528-5 basic transmission loss table and interpolant.
%   [F, tbl] = P528_LOSS_TABLE_REV1(f_mhz, h_es_m) computes P.528-5 loss on
%   a grid of distance, other-terminal height, and time percentage between
%   an earth station at h_es_m and a UWB transmitter, and returns
%   F(log10(d_km), h_m, p) as a griddedInterpolant (linear). Terminals are
%   ordered low/high as P.528 requires; the loss is reciprocal.
%
%   The loss comes from the MATLAB port in github.com/nicklasorte/itu_p528
%   (validated against the NTIA C++ reference). Its src folder must be on
%   the path or at opts.p528_src.
%
%   Name-value options:
%     d_km, h_m, p_pct   grid vectors (defaults below)
%     T_pol              0 horizontal, 1 vertical (default 1)
%     cache_dir          folder for the cached .mat (default ../output/cache)
%     tf_recalculate     1 forces recomputation (default 0)
%     parallel_flag      passed to p528_rev1 (default 0)
%     p528_src           path to itu_p528/src (default: sibling clone)
%
%   tbl has fields d_km, h_m, p_pct, A_db (n_d x n_h x n_p), mode, key.
arguments
    f_mhz (1,1) double {mustBePositive}
    h_es_m (1,1) double {mustBePositive}
    opts.d_km (1,:) double = [0.02 0.05 0.1 0.2 0.3 0.5 0.75 1 1.25 1.5 2 2.5 3 4 5 6 8 10 12.5 15 20 25 30 35 40 45 50 55 60 65 70 80 90 100 120 150]
    opts.h_m (1,:) double = [1.5 5 10 15 20 30 45 60 80 100 121.92 150 200 243.84]
    opts.p_pct (1,:) double = [1 2 5 10 20 30 40 50 60 70 80 90 95 98 99]
    opts.T_pol (1,1) double = 1
    opts.cache_dir (1,1) string = string(fullfile(fileparts(mfilename('fullpath')), '..', 'output', 'cache'))
    opts.tf_recalculate (1,1) double = 0
    opts.parallel_flag (1,1) double = 0
    opts.p528_src (1,1) string = string(fullfile(fileparts(mfilename('fullpath')), '..', '..', 'itu_p528', 'src'))
end
if isempty(which('p528_rev1'))
    if ~isfolder(opts.p528_src)
        error('p528_loss_table_rev1:noP528', ...
            'p528_rev1 not on the path and %s not found. Clone github.com/nicklasorte/itu_p528 next to this repo.', opts.p528_src);
    end
    addpath(opts.p528_src);
end
if ~isfolder(opts.cache_dir), mkdir(opts.cache_dir); end

key_str = sprintf('f%.6g_hes%.6g_pol%d|d%s|h%s|p%s', f_mhz, h_es_m, opts.T_pol, ...
    strjoin(compose("%.15g", opts.d_km), ','), strjoin(compose("%.15g", opts.h_m), ','), strjoin(compose("%.15g", opts.p_pct), ','));
md = java.security.MessageDigest.getInstance('MD5');
hash = reshape(dec2hex(typecast(md.digest(uint8(char(key_str))), 'uint8'))', 1, []);
cache_file = fullfile(opts.cache_dir, sprintf('p528_table_f%g_hes%g_%s.mat', f_mhz, h_es_m, hash(1:12)));

if isfile(cache_file) && opts.tf_recalculate == 0
    s = load(cache_file, 'tbl');
    tbl = s.tbl;
else
    [D, H, P] = ndgrid(opts.d_km, opts.h_m, opts.p_pct);
    h_lo = min(H, h_es_m);
    h_hi = max(H, h_es_m);
    [A, res] = p528_rev1(D, h_lo, h_hi, f_mhz, opts.T_pol, P, 'parallel_flag', opts.parallel_flag);
    tbl.d_km = opts.d_km;
    tbl.h_m = opts.h_m;
    tbl.p_pct = opts.p_pct;
    tbl.A_db = A;
    tbl.mode = reshape([res.propagation_mode], size(A));
    tbl.f_mhz = f_mhz;
    tbl.h_es_m = h_es_m;
    tbl.T_pol = opts.T_pol;
    tbl.key = key_str;
    save_atomic(cache_file, tbl);
end
if any(~isfinite(tbl.A_db(:)))
    error('p528_loss_table_rev1:nonfinite', 'P.528 table has non-finite entries; check the grid against P.528 limits.');
end
F = griddedInterpolant({log10(tbl.d_km), tbl.h_m, tbl.p_pct}, tbl.A_db, 'linear', 'nearest');
end

function save_atomic(file, tbl)
% Write to a unique temp file in the same folder, then move into place
% atomically (first writer wins), so parallel servers never read a partial file.
tmp = [tempname(fileparts(file)) '.part.mat'];
save(tmp, 'tbl');
src = java.io.File(tmp).toPath();
dst = java.io.File(file).toPath();
if isfile(file)
    delete(tmp);
    return
end
opt = javaArray('java.nio.file.CopyOption', 1);
opt(1) = java.nio.file.StandardCopyOption.ATOMIC_MOVE;
try
    java.nio.file.Files.move(src, dst, opt);
catch
    if isfile(tmp), delete(tmp); end   % another writer finished first
end
end
