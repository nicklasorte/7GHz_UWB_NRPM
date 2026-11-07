function m = uwb_pulse_metrics_rev1(rx_bw_MHz, uwb, t_on_ms)
%UWB_PULSE_METRICS_REV1 How a pulsed UWB emission appears inside a victim receiver bandwidth.
%   m = UWB_PULSE_METRICS_REV1(rx_bw_MHz, uwb, t_on_ms) returns, for each victim
%   bandwidth (in-channel, at the 47 CFR 15.519 limits):
%
%   m.avg_dBm        long-term average EIRP in rx_bw (15.519(c): -41.3 dBm/MHz,
%                    RMS over 1 ms per 15.521(d))
%   m.burst_boost_dB in-packet average PSD above the 1 ms average when a packet
%                    of length t_on_ms (< 1 ms) is the only emission in a 1 ms
%                    window: 10 log10(1 ms / t_on), capped so the in-packet
%                    average in 1 MHz does not exceed the 15.519(e)/15.521(g)
%                    peak limit of 20 log10(1/50) = -34 dBm in 1 MHz
%   m.burst_dBm      in-packet average EIRP in rx_bw
%   m.peak_env_dBm   regulatory peak envelope in rx_bw: 20 log10(B/50) dBm
%                    (15.521(g), defined for 1-50 MHz; extrapolated above 50 MHz
%                    and capped at the channel bandwidth, flagged in m.peak_note)
%   m.par_reg_dB     peak envelope minus long-term average
%   m.regime         per mean PRF: "noise-like" if B < PRF, "pulse-resolved" if B > PRF
%                    (NTIA Report 01-383, sec. 3.3)
%   m.par_pulse_dB   first-order peak-to-average for a resolved pulse train,
%                    10 log10(B/PRF) when B > PRF, else 0 dB (Gaussian crest
%                    factor not included)
%
%   uwb.mean_prf_MHz may be a vector (BPRF 62.4 MHz; HPRF 124.8 and 249.6 MHz).
arguments
    rx_bw_MHz (:,1) double {mustBePositive}
    uwb struct
    t_on_ms (1,:) double {mustBePositive, mustBeLessThanOrEqual(t_on_ms,1)} = 1
end
b = rx_bw_MHz;
b_eff = min(b, uwb.bw_MHz);                       % emission cannot exceed the channel
m.rx_bw_MHz = b;
m.avg_dBm = uwb.eirp_dBm_per_MHz + 10*log10(b_eff);

peak_1MHz_dBm = 20*log10(1/50);                   % 15.521(g) at RBW = 1 MHz
boost_cap = peak_1MHz_dBm - uwb.eirp_dBm_per_MHz; % 7.3 dB
m.t_on_ms = t_on_ms;
m.burst_boost_dB = min(10*log10(1./t_on_ms), boost_cap);
m.burst_dBm = m.avg_dBm + m.burst_boost_dB;       % (n_bw x n_ton)

m.peak_env_dBm = 20*log10(min(b, uwb.bw_MHz)/50);
m.peak_note = repmat("15.521(g) range", size(b));
m.peak_note(b < 1) = "below 1 MHz: outside 15.521(g)";
m.peak_note(b > 50) = "above 50 MHz: 20log extrapolation (assumption)";
m.par_reg_dB = m.peak_env_dBm - m.avg_dBm;

prf = uwb.mean_prf_MHz(:)';
m.mean_prf_MHz = prf;
m.regime = repmat("noise-like", numel(b), numel(prf));
m.regime(b > prf) = "pulse-resolved";
m.par_pulse_dB = max(10*log10(b_eff ./ prf), 0);
end
