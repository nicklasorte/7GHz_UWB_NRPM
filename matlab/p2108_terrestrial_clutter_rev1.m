function L_ctt_db = p2108_terrestrial_clutter_rev1(f_ghz, d_km, p_loc)
%P2108_TERRESTRIAL_CLUTTER_REV1 ITU-R P.2108-1 sec. 3.2 statistical clutter loss, terrestrial paths.
%   L_ctt_db = P2108_TERRESTRIAL_CLUTTER_REV1(f_ghz, d_km, p_loc) returns the
%   clutter loss not exceeded for p_loc percent of locations, applied at one
%   end of a terrestrial path (Eqns 3a-6). d_km and p_loc expand implicitly.
%   Paths shorter than 0.25 km get 0 dB (outside the model's range). The
%   loss is capped at its 2 km value (Eqn 6).
%
%   Source: Recommendation ITU-R P.2108-1 (09/2021), section 3.2,
%   https://www.itu.int/rec/R-REC-P.2108/en. Valid 0.5-67 GHz.
%   TODO verify Eqn 3b (sigma_cb) against the official PDF; the extracted
%   text was garbled and this form is a reconstruction.
arguments
    f_ghz (1,1) double {mustBeInRange(f_ghz, 0.5, 67)}
    d_km double
    p_loc double {mustBeGreaterThan(p_loc, 0), mustBeLessThan(p_loc, 100)}
end
L_l = -2 * log10(10^(-5 * log10(f_ghz) - 12.5) + 10^(-16.5));   % Eqn 4a
sigma_l = 4;                                                       % Eqn 4b
sigma_s = 6;                                                       % Eqn 5b
d_eff = min(max(d_km, 0.25), 2);                                   % Eqn 6 cap at 2 km
L_s = 32.98 + 23.9 * log10(d_eff) + 3 * log10(f_ghz);              % Eqn 5a
w_l = 10.^(-0.2 * L_l);
w_s = 10.^(-0.2 * L_s);
sigma_cb = sqrt((sigma_l^2 * w_l + sigma_s^2 * w_s) ./ (w_l + w_s));   % Eqn 3b (reconstructed)
q_inv = sqrt(2) * erfcinv(2 * p_loc / 100);                      % Q^-1(p/100), inverse complementary normal
L_ctt_db = -5 * log10(w_l + w_s) - sigma_cb .* q_inv;             % Eqn 3a
L_ctt_db(d_km < 0.25) = 0;
end
