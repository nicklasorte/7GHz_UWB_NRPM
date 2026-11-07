function p_dBm = uwb_power_in_band_rev1(f_victim_MHz, ref_bw_MHz, uwb)
%UWB_POWER_IN_BAND_REV1 UWB EIRP (dBm) falling in a victim reference bandwidth.
%   p_dBm = UWB_POWER_IN_BAND_REV1(f_victim_MHz, ref_bw_MHz, uwb) integrates the
%   UWB EIRP spectral density over [f - ref_bw/2, f + ref_bw/2] for each victim
%   center frequency. uwb is the .uwb field of UWB_EESS_PARAMS_REV1.
%
%   mask_type "ieee802154": 0 dBr within 0.65/Tp of fc, then -10 and -18 dBr
%   (an upper bound on the device PSD, referenced to the 15.519 limit).
%   mask_type "flat": the FCC envelope, -41.3 dBm/MHz across 3100-10600 MHz.
%   This is the result of ITU-R SM.337 FDR (on-tune + off-frequency rejection)
%   with a rectangular victim filter of width ref_bw_MHz.
arguments
    f_victim_MHz double {mustBePositive}
    ref_bw_MHz (1,1) double {mustBePositive}
    uwb struct
end
switch uwb.mask_type
    case "ieee802154"
        off = uwb.mask_offset_x_chip*uwb.chip_rate_MHz;
        brk = uwb.fc_MHz + [-fliplr(off) off];
        mask_dBr = @(f) ieee_mask(f, uwb.fc_MHz, off, uwb.mask_level_dBr);
    case "flat"
        brk = [3100 10600];
        mask_dBr = @(f) flat_mask(f);
    otherwise
        error('uwb_power_in_band_rev1:mask', 'Unknown mask_type "%s".', uwb.mask_type);
end

p_dBm = zeros(size(f_victim_MHz));
for k = 1:numel(f_victim_MHz)
    lo = f_victim_MHz(k) - ref_bw_MHz/2;
    hi = f_victim_MHz(k) + ref_bw_MHz/2;
    wp = brk(brk > lo & brk < hi);
    if isempty(wp)
        bw_eq = integral(@(f) 10.^(mask_dBr(f)/10), lo, hi);
    else
        bw_eq = integral(@(f) 10.^(mask_dBr(f)/10), lo, hi, 'Waypoints', wp);
    end
    p_dBm(k) = uwb.eirp_dBm_per_MHz - uwb.eirp_offset_dB + 10*log10(bw_eq);
end
end

function m = ieee_mask(f, fc, off, lev)
d = abs(f - fc);
m = zeros(size(f));
m(d > off(1)) = lev(1);
m(d > off(2)) = lev(2);
end

function m = flat_mask(f)
m = zeros(size(f));
m(f < 3100 | f > 10600) = -20;   % 47 CFR 15.519(c): -61.3 dBm/MHz outside 3100-10600 MHz (above 1990 MHz)
end
