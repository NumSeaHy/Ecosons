"""
Computes slope magnitudes and directions from bathymetry profile data.

For each depth point `p` in the bathymetry profile:
- Converts latitude and longitude to UTM coordinates.
- Finds neighboring points within a radius `krad` meters.
- Filters neighbors to exclude outliers based on depth mean ± 2 standard deviations.
- Splits neighbors into two groups: points before `p` (`pa`) and points after `p` (`pb`) in profile order.
- Finds the points furthest from `p` in each group.
- Calculates the slope as the vertical depth difference between these two points divided by their horizontal distance.
- Computes the slope direction as the angle of the vector between these two points.
- Assigns a constant cosine angle `cang` (set to √0.5 for all points).

# Arguments
- `baths`: An array of `Bathymetry` objects
- `krad`: A search radius (in meters) used to find neighboring points for slope calculation (default: 15).

# Returns
- An array of `Slope` objects, each one containing:
  - `slope`: Vector of slope magnitudes at each depth point.
  - `cang`: Vector of constant cosine angles (all set to √0.5).
  - `trans_dir`: Vector of slope directions in degrees (transverse direction).

"""
function slopesFromBathymetry(
    baths::Array{Bathymetry},
    krad::Real = 15
    )::Array{Slope}

    Slopes = []
    utmZ = -1

    for (nt, bath) in enumerate(baths)
        # Initialize UTM zone to -1 to trigger auto-selection in latlon2utmxy

        # Convert lat/lon to UTM coordinates (x, y) and get zone number (zn)
        x, y, zn = latlon2utmxy(utmZ, bath.latitude, bath.longitude)
        if nt == 1
            utmZ = zn[1]
        end

        # Extract depths from bathymetry
        z = bath.depth
        # Initialize vectors for slope magnitude and horizontal vector components
        gg = fill(NaN, length(z))  # slope magnitudes (initialized as NaN)
        tx = fill(NaN, length(z))  # x-component of vector between furthest points
        ty = fill(NaN, length(z))  # y-component of vector between furthest points

        # Loop over all points in the depth profile
        for p in 1:length(z)
            # Calculate horizontal distances from point p to all others
            d = hypot.(x .- x[p], y .- y[p])

            # Mask neighbors within radius krad and with valid depth
            valid  = (d .< krad) .& .!isnan.(z)

           if any(valid)
                zm = mean(z[valid])
                zs = std(z[valid])
                inlier = valid .& (abs.(z .- zm) .<= 2 * zs)

                pa_mask = inlier .& (1:length(z) .<= p)
                pb_mask = inlier .& (1:length(z) .>= p)

                if !any(pa_mask) || !any(pb_mask)
                    continue
                else
                    _, pa = findmax(d[pa_mask])
                    _, pb = findmax(d[pb_mask])
                end
                dx = x[pb] - x[pa]
                dy = y[pb] - y[pa]
                tx[p] = dx + 1e-10  # avoid divide-by-zero
                ty[p] = dy + 1e-10
                gg[p] = (z[pb] - z[pa]) / hypot(tx[p], ty[p])
           end
        end

        # Calculate transverse slope direction in degrees
        trans_dir = (180 / π) .* atan.(tx, ty)

        # Constant cosine angle vector (√0.5) for all points
        cang = sqrt(0.5) .* ones(length(z))
        push!(Slopes, Slope(gg, trans_dir, cang))
    end
    return Slopes
end

