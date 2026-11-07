function c = eess_criteria_rev1(f_MHz, p)
%EESS_CRITERIA_REV1 Long- and short-term interference criteria at a victim frequency.
%   c = EESS_CRITERIA_REV1(f_MHz, p) returns a struct with long_dBm, long_pct,
%   short_dBm, short_pct (per p.crit.ref_bw_MHz) and the source text. Errors
%   if f_MHz is outside every protected band in p.crit.table.
arguments
    f_MHz (1,1) double
    p struct
end
t = p.crit.table;
k = find(f_MHz >= t.f_lo_MHz & f_MHz <= t.f_hi_MHz, 1);
if isempty(k)
    error('eess_criteria_rev1:noBand', ...
        '%.1f MHz is not in a protected EESS/MetSat space-to-Earth band in p.crit.table.', f_MHz);
end
c.long_dBm  = t.long_dBW(k) + 30;
c.long_pct  = t.long_pct(k);
c.short_dBm = t.short_dBW(k) + 30;
c.short_pct = t.short_pct(k);
c.source    = t.source(k);
c.ref_bw_MHz = p.crit.ref_bw_MHz;
% Express as I/N for reference (thermal noise in the reference bandwidth).
n_dBm = 10*log10(physconst('Boltzmann')*p.es.tsys_K*p.crit.ref_bw_MHz*1e6) + 30;
c.n_dBm = n_dBm;
c.long_IN_dB  = c.long_dBm - n_dBm;
c.short_IN_dB = c.short_dBm - n_dBm;
end
