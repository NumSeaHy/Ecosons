"""
Converts geographic coordinates (latitude, longitude) in decimal degrees to
UTM (Universal Transverse Mercator) coordinates using the WGS-84 ellipsoid.

# Arguments
- `lat::Float64`: Latitude in decimal degrees.
- `lon::Float64`: Longitude in decimal degrees.

# Returns
- `x::Float64`: UTM easting in meters.
- `y::Float64`: UTM northing in meters.
- `zone::Int`: UTM longitudinal zone number (1 to 60).
- `hemisphere::String`: `"North"` or `"South"` depending on the latitude.

# Notes
- The output coordinates use a scale factor `k₀ = 0.9996` and a false easting of 500,000 meters.
- For latitudes in the Southern Hemisphere, a false northing of 10,000,000 meters is added.
- Based on standard UTM projection formulas.
"""
function latlon2utm(lat::Float64, lon::Float64)
    # Ellipsoid parameters for WGS-84
    a = 6378137.0                  # Equatorial radius (semi-major axis)
    f = 1 / 298.257223563          # Flattening
    k0 = 0.9996                    # Scale factor along central meridian

    e = sqrt(f * (2 - f))          # Eccentricity of the ellipsoid

    # Determine UTM zone based on longitude
    zone = floor(Int, (lon + 180) / 6) + 1

    # Longitude of the central meridian of the zone in radians
    λ₀ = deg2rad(-183 + 6 * zone)

    # Convert latitude and longitude to radians
    ϕ = deg2rad(lat)
    λ = deg2rad(lon)

    # Calculate parameters needed for projection
    N = a / sqrt(1 - e^2 * sin(ϕ)^2)        # Radius of curvature in prime vertical
    T = tan(ϕ)^2                            # Square of tangent of latitude
    C = (e^2 / (1 - e^2)) * cos(ϕ)^2       # Radius of curvature in meridian
    A = cos(ϕ) * (λ - λ₀)                   # Difference in longitude from central meridian

    # Calculate the meridional arc length
    M = a * ((1 - e^2/4 - 3*e^4/64 - 5*e^6/256) * ϕ
        - (3*e^2/8 + 3*e^4/32 + 45*e^6/1024) * sin(2*ϕ)
        + (15*e^4/256 + 45*e^6/1024) * sin(4*ϕ)
        - (35*e^6/3072) * sin(6*ϕ))

    # Calculate easting (x)
    x = k0 * N * (A + (1 - T + C)*A^3/6 + (5 - 18*T + T^2 + 72*C - 58*e^2)*A^5/120) + 500000

    # Calculate northing (y)
    y = k0 * (M + N * tan(ϕ) * (A^2/2 + (5 - T + 9*C + 4*C^2)*A^4/24 +
           (61 - 58*T + T^2 + 600*C - 330*e^2)*A^6/720))

    # Adjust northing for southern hemisphere
    hemisphere = lat < 0 ? "South" : "North"
    if lat < 0
        y += 10000000  # Add false northing for southern hemisphere
    end

    return x, y, zone, hemisphere
end
