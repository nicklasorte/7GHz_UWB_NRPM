function ci = mc_tail_ci_rev1(x, pct_exceed, crit, level)
%MC_TAIL_CI_REV1 Confidence intervals for Monte Carlo percentiles and exceedance fractions.
%   ci = MC_TAIL_CI_REV1(x, pct_exceed, crit, level) takes n independent
%   Monte Carlo samples x (column, linear units), the percentages of time
%   pct_exceed whose levels are wanted (for example [20 0.005]), criteria
%   crit (same units as x, one per pct_exceed), and the confidence level
%   (for example 0.95). It returns:
%     ci.level_db       point estimate 10 log10 of the (100 - pct) percentile
%     ci.level_db_lo/hi distribution-free order-statistic interval: the
%                       count of samples below the true percentile is
%                       Binomial(n, 1 - pct/100), so the interval runs from
%                       the k_lo-th to the k_hi-th sorted sample
%     ci.n_tail         expected number of samples beyond the percentile
%     ci.frac           fraction of samples above each criterion
%     ci.frac_lo/hi     Clopper-Pearson (exact binomial) interval
%   NaN bounds mean the sample is too small to bound that side.
%
%   Built-ins used: binoinv and betainv (Statistics and Machine Learning
%   Toolbox). bootci was considered; a bootstrap of an extreme order
%   statistic is unreliable, while the order-statistic interval is exact.
arguments
    x (:,1) double
    pct_exceed (1,:) double {mustBeGreaterThan(pct_exceed, 0), mustBeLessThan(pct_exceed, 100)}
    crit (1,:) double
    level (1,1) double {mustBeGreaterThan(level, 0), mustBeLessThan(level, 1)} = 0.95
end
if numel(crit) ~= numel(pct_exceed)
    error('mc_tail_ci_rev1:size', 'Give one criterion per percentage.');
end
n = numel(x);
a = 1 - level;
xs = sort(x);
q = 1 - pct_exceed / 100;
ci.pct_exceed = pct_exceed;
ci.n = n;
ci.n_tail = n * pct_exceed / 100;
ci.level_db = reshape(10 * log10(prctile(x, 100 * q)), 1, []);
k_lo = binoinv(a / 2, n, q);
k_hi = binoinv(1 - a / 2, n, q) + 1;
ci.level_db_lo = NaN(size(q));
ci.level_db_hi = NaN(size(q));
ok = k_lo >= 1;
ci.level_db_lo(ok) = 10 * log10(xs(k_lo(ok)));
ok = k_hi <= n;
ci.level_db_hi(ok) = 10 * log10(xs(k_hi(ok)));

k = sum(x > crit, 1);
ci.frac = k / n;
ci.frac_lo = zeros(size(k));
ci.frac_hi = ones(size(k));
m = k > 0;
ci.frac_lo(m) = betainv(a / 2, k(m), n - k(m) + 1);
m = k < n;
ci.frac_hi(m) = betainv(1 - a / 2, k(m) + 1, n - k(m));
ci.conf_level = level;
end
