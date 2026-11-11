function rg = region_chord_rev1(x_km, y_km, Z, level)
%REGION_CHORD_REV1 Area, perimeter, and mean chord of the region where a map exceeds a level.
%   rg = REGION_CHORD_REV1(x_km, y_km, Z, level) takes a gridded map Z
%   (rows follow y_km, columns follow x_km) and returns the region Z > level:
%     rg.area_km2       cell count times cell area
%     rg.perimeter_km   length of the level contour (contourc)
%     rg.mean_chord_km  pi * area / perimeter: the mean length of a random
%                       straight line through the region (Cauchy-Crofton),
%                       exact for convex regions, an approximation otherwise
%     rg.length_km, rg.width_km  extent along and across the principal axis
%     rg.n_regions      number of separate contour loops
%
%   A drone crossing the region on a random straight path at speed v stays
%   inside for mean_chord_km / v on average.
%
%   Built-ins used: contourc for the contour length, polyarea is not used
%   for the area because the contour of a gridded field can self-touch;
%   the cell count is exact on the grid.
arguments
    x_km (1,:) double
    y_km (1,:) double
    Z (:,:) double
    level (1,1) double
end
if ~isequal(size(Z), [numel(y_km) numel(x_km)])
    error('region_chord_rev1:size', 'Z must be numel(y_km)-by-numel(x_km).');
end
dx = mean(diff(x_km)); dy = mean(diff(y_km));
mask = Z > level;
rg.area_km2 = nnz(mask) * abs(dx * dy);
rg.n_regions = 0;
rg.perimeter_km = 0;
if rg.area_km2 == 0
    rg.mean_chord_km = 0; rg.length_km = 0; rg.width_km = 0;
    return
end
C = contourc(x_km, y_km, double(mask), [0.5 0.5]);
k = 1;
while k < size(C, 2)
    nv = C(2, k);
    xy = C(:, k+1:k+nv);
    rg.perimeter_km = rg.perimeter_km + sum(hypot(diff(xy(1, :)), diff(xy(2, :))));
    rg.n_regions = rg.n_regions + 1;
    k = k + nv + 1;
end
rg.mean_chord_km = pi * rg.area_km2 / rg.perimeter_km;
[YY, XX] = ndgrid(y_km, x_km);
P = [XX(mask), YY(mask)];
P = P - mean(P, 1);
[V, ~] = eig(cov(P));
proj = P * V;
ext = max(proj) - min(proj) + [abs(dx) abs(dy)];
rg.length_km = max(ext);
rg.width_km = min(ext);
end
