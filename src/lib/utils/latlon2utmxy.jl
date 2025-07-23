""" Converts geographic coordinates (latitude and longitude in degrees)
to UTM (Universal Transverse Mercator) coordinates (in meters).

# Arguments
- `zn`: Integer or Vector of Integers  
    UTM zone(s). If ≤ 0 or invalid, it will be computed automatically from longitude.
- `lat`: Vector{Float64}  
    Latitudes in degrees.
- `lon`: Vector{Float64}  
    Longitudes in degrees.

# Returns
- `x`: Vector{Float64} — UTM Easting coordinates (meters)
- `y`: Vector{Float64} — UTM Northing coordinates (meters)
- `zn`: Vector{Int} — Updated UTM zone(s) used in the conversion
- `hm`: Vector{Int} — Hemisphere flags (1 for Northern, 0 for Southern)
"""
function latlon2utmxy(
    zn:: Union{Vector{Float64}, Float64, Int64, Vector{Int64}},
    lat:: Vector{Float64},
    lon:: Vector{Float64}
    )
    # Scale factor for UTM projection
    UTMScaleFactor = 0.9996

    # Ellipsoid parameters for WGS84
    sm_a = 6378137.0          # Semi-major axis (meters)
    sm_b = 6356752.314        # Semi-minor axis (meters)
    sm_EccSquared = 6.69437999013e-03  # Eccentricity squared

    # Compute second eccentricity squared parameter ep2
    ep2 = (sm_a + sm_b) * (sm_a - sm_b) / sm_b^2

    # Estimate best UTM zone if zn <= 0 or contains invalid values
    if length(zn) == 1 && zn <= 0
        # Compute mean longitude ignoring NaNs and calculate zone
       zn = round(Int, (mean(filter(!isnan, lon)) + 183) / 6)
    else
        # For array zn: replace invalid zones with zone computed from corresponding lon
        for i in eachindex(zn)
            if isnan(zn[i])
                mean_lon = mean(skipmissing(lon))
                zn[i] = round(Int, (mean_lon + 183) / 6)
            elseif zn[i] <= 0
                zn[i] = round(Int, (lon[i] + 183) / 6)
            end
        end
    end

    # Central meridian longitude for each zone (degrees)
    lon0 = 6 .* zn .- 183

    # Calculate parameters for projection
    cphi = cosd.(lat)            # Cosine of latitude in degrees
    nu2 = ep2 .* cphi.^2         # Square of second eccentricity times cos²(latitude)
    N = (sm_a^2 / sm_b) .* (1 .+ nu2) .^ (-0.5)   # Radius of curvature in the prime vertical
    t = tand.(lat)               # Tangent of latitude
    t2 = t.^2                   # Square of tangent

    # Difference in longitude from central meridian (radians)
    l = deg2rad.(lon .- lon0)

    # Coefficients used in series expansions for Easting and Northing calculations
    l3coef = 1 .- t2 .+ nu2
    l4coef = 5 .- t2 .+ (9 .+ 4 .* nu2) .* nu2
    l5coef = 5 .+ (t2 .- 18) .* t2 .+ (14 .- 58 .* t2) .* nu2
    l6coef = 61 .+ (t2 .- 58) .* t2 .+ (270 .- 330 .* t2) .* nu2
    l7coef = 61 .+ ((179 .- t2) .* t2 .- 479) .* t2
    l8coef = 1385 .+ ((543 .- t2) .* t2 .- 3111) .* t2

    # Calculate Easting (x) using series expansion
    x = N .* cphi .* l .* (1 .+
        (1/6) .* cphi.^2 .* l.^2 .* (l3coef .+
        (1/20) .* cphi.^2 .* l.^2 .* (l5coef .+
        (1/42) .* cphi.^2 .* l.^2 .* l7coef)))

    # Calculate Northing (y) using series expansion and meridian arc length
    y = ArcLengthOfMeridian.(deg2rad.(lat)) .+ 0.5 .* t .* N .* (cphi.^2 .* l.^2) .* (1 .+
        (1/12) .* cphi.^2 .* l.^2 .* (l4coef .+
        (1/30) .* cphi.^2 .* l.^2 .* (l6coef .+
        (1/56) .* cphi.^2 .* l.^2 .* l8coef)))

    # Apply scale factor and add false easting of 500,000 meters
    x = x .* UTMScaleFactor .+ 500000

    # Apply scale factor to northing
    y = y .* UTMScaleFactor

    # Add false northing of 10,000,000 meters for southern hemisphere points
    y = y .+ 1e7 .* (y .< 0)

    # Determine hemisphere: 1 for northern, 0 for southern hemisphere
    hm = map(lat_val -> lat_val > 0 ? 1 : 0, lat)

    return x, y, zn, hm
end


