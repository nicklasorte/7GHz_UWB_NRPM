function d = drone_density_faa_rev1(pop_density_per_km2, opts)
%DRONE_DENSITY_FAA_REV1 Active UWB drone density near a site, built from public FAA and Census data.
%   d = DRONE_DENSITY_FAA_REV1(pop_density_per_km2) returns a table of
%   active UWB-transmitting drones per km^2 for a site with the given
%   resident population density, for every combination of the swept
%   factors below. Each step is a separate column so it can be checked.
%
%   Step 1. Average number of drones airborne in the United States:
%           2025 flight hours / 8,760 hours per year.
%           FAA, Small Unmanned Aircraft Systems Survey Report 2025, Table 1:
%           21,676,799 flight hours and 57,836,452 flights in calendar 2025
%           (population-weighted national estimates).
%   Step 2. Per resident: divide by the U.S. population, 341,784,857 on
%           July 1, 2025 (Census Bureau Vintage 2025, via Cornell PAD,
%           "V2025 State Highlights").
%   Step 3. State adjustment: the state's flights per resident divided by
%           the national flights per resident (FAA survey Table 6, Census
%           V2025 state population). This assumes flight hours scale with
%           flights.
%   Step 4. Local density: multiply by resident population per km^2.
%           This assumes drones fly where people live; the FAA forecast says
%           recreational ownership "maps closely against the population
%           centers" (FAA Aerospace Forecast FY2021-2041, UAS chapter).
%   Step 5. Peak-hour factor: flights cluster in daylight and on weekends.
%           No public hourly distribution was found (TODO). Swept: 1 (annual
%           average), 3, and 6.
%   Step 6. UWB-equipped fraction: no public data on drones carrying
%           channel 9 UWB (TODO). Swept: 0.1 and 1.
%   Step 7. UWB transmit activity: ECC Report 327 activity factors of 1-5%
%           (via the FiRa 2025 report) and 100% (continuous, worst case).
%
%   Name-value options:
%     state_flights   flights in the site's state, 2025 (default New York, 1,366,899)
%     state_pop       state population, July 1, 2025 (default New York, 20,002,427)
%     peak_factor     default [1 3 6]
%     equipped_frac   default [0.1 1]
%     activity        default [0.05 1]
arguments
    pop_density_per_km2 (1,1) double {mustBePositive}
    opts.state_flights (1,1) double = 1366899
    opts.state_pop (1,1) double = 20002427
    opts.peak_factor (1,:) double = [1 3 6]
    opts.equipped_frac (1,:) double = [0.1 1]
    opts.activity (1,:) double = [0.05 1]
end
faa_hours_2025 = 21676799;        % FAA sUAS Survey Report 2025, Table 1
faa_flights_2025 = 57836452;      % FAA sUAS Survey Report 2025, Table 1
us_pop_2025 = 341784857;         % Census V2025, July 1, 2025

airborne_us = faa_hours_2025 / 8760;                                        % step 1
per_person = airborne_us / us_pop_2025;                                     % step 2
state_ratio = (opts.state_flights / opts.state_pop) / (faa_flights_2025 / us_pop_2025);   % step 3
airborne_avg_km2 = per_person * state_ratio * pop_density_per_km2;          % step 4

[pk, eq, ac] = ndgrid(opts.peak_factor, opts.equipped_frac, opts.activity);
d = table(pk(:), eq(:), ac(:), 'VariableNames', {'peak_factor', 'equipped_frac', 'activity'});
d.airborne_per_km2 = airborne_avg_km2 * d.peak_factor;                      % step 5
d.active_uwb_per_km2 = d.airborne_per_km2 .* d.equipped_frac .* d.activity; % steps 6-7
d.Properties.UserData = struct('airborne_us_avg', airborne_us, 'airborne_per_person', per_person, ...
    'state_ratio', state_ratio, 'airborne_avg_per_km2', airborne_avg_km2, ...
    'pop_density_per_km2', pop_density_per_km2, 'faa_hours_2025', faa_hours_2025, ...
    'faa_flights_2025', faa_flights_2025, 'us_pop_2025', us_pop_2025);
end
