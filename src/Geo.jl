module Geo

using LinearAlgebra, Statistics

export latlon2utmxy, ArcLengthOfMeridian

"""
    latlon2utmxy(zn, lat, lon)

Converts latitude-longitude coordinates to Universal Transverse Mercator (UTM) projection coordinates.

# Arguments
- `zn`: UTM zone; if `zn <= 0`, it is computed from `lon`.
- `lat`: Latitude in degrees.
- `lon`: Longitude in degrees.

# Returns
- `x`, `y`: UTM coordinates.
- `zn`: UTM zone.
- `hm`: Hemisphere indicator (`1` for northern, `-1` for southern).
"""
function latlon2utmxy(zn, lat::AbstractVector, lon::AbstractVector)
    UTMScaleFactor = 0.9996
    sm_a = 6378137.0
    sm_b = 6356752.314
    sm_EccSquared = 6.69437999013e-03

    ep2 = (sm_a^2 - sm_b^2) / sm_b^2

    # Estimate best UTM-zone
    if length(zn) == 1 && zn <= 0
        zn = round(Int, (mean(filter(!isnan, lon)) + 183) / 6)
    else
        zn = map(zn) do z
            if z <= 0 || isnan(z)
                round(Int, (mean(filter(!isnan, lon)) + 183) / 6)
            else
                z
            end
        end
    end

    lon0 = 6 .* zn .- 183
    cphi = cosd.(lat)
    nu2 = ep2 .* cphi.^2
    N = (sm_a^2 / sm_b) ./ sqrt.(1 .+ nu2)
    t = tand.(lat)
    t2 = t.^2
    l = deg2rad.(lon .- lon0)

    l3coef = 1 .- t2 .+ nu2
    l4coef = 5 .- t2 .+ (9 .+ 4 .* nu2) .* nu2
    l5coef = 5 .+ (t2 .- 18) .* t2 .+ (14 .- 58 .* t2) .* nu2
    l6coef = 61 .+ (t2 .- 58) .* t2 .+ (270 .- 330 .* t2) .* nu2
    l7coef = 61 .+ ((179 .- t2) .* t2 .- 479) .* t2
    l8coef = 1385 .+ ((543 .- t2) .* t2 .- 3111) .* t2

    # Calculate easting (x)
    x = N .* cphi .* l .* (1 .+ (1/6) .* cphi.^2 .* l.^2 .* (l3coef .+ (1/20) .* cphi.^2 .* l.^2 .* (l5coef .+ (1/42) .* cphi.^2 .* l.^2 .* l7coef)))
    x = x .* UTMScaleFactor .+ 500000

    # Calculate northing (y)
    y = ArcLengthOfMeridian.(deg2rad.(lat)) .+ 0.5 .* t .* N .* (cphi.^2 .* l.^2) .* (1 .+ (1/12) .* cphi.^2 .* l.^2 .* (l4coef .+ (1/30) .* cphi.^2 .* l.^2 .* (l6coef .+ (1/56) .* cphi.^2 .* l.^2 .* l8coef)))
    y = y .* UTMScaleFactor
    y .+= 10000000 .* (y .< 0)

    # Define hemisphere
    hm = sign.(lat)

    return x, y, zn, hm
end

function latlon2utmxy(zn::Int, lat::Number, lon::Number)
    UTMScaleFactor = 0.9996
    sm_a = 6378137.0
    sm_b = 6356752.314
    sm_EccSquared = 6.69437999013e-03

    ep2 = (sm_a^2 - sm_b^2) / sm_b^2

    # Estimate UTM-zone if not provided or invalid
    if zn <= 0
        zn = round(Int, (lon + 183) / 6)
    end

    lon0 = 6 * zn - 183
    cphi = cosd(lat)
    nu2 = ep2 * cphi^2
    N = (sm_a^2 / sm_b) / sqrt(1 + nu2)
    t = tand(lat)
    t2 = t^2
    l = deg2rad(lon - lon0)

    l3coef = 1 - t2 + nu2
    l4coef = 5 - t2 + (9 + 4 * nu2) * nu2
    l5coef = 5 + (t2 - 18) * t2 + (14 - 58 * t2) * nu2
    l6coef = 61 + (t2 - 58) * t2 + (270 - 330 * t2) * nu2
    l7coef = 61 + ((179 - t2) * t2 - 479) * t2
    l8coef = 1385 + ((543 - t2) * t2 - 3111) * t2

    # Calculate easting (x)
    x = N * cphi * l * (1 + (1/6) * cphi^2 * l^2 * (l3coef + (1/20) * cphi^2 * l^2 * (l5coef + (1/42) * cphi^2 * l^2 * l7coef)))
    x = x * UTMScaleFactor + 500000

    # Calculate northing (y)
    y = ArcLengthOfMeridian(deg2rad(lat)) + 0.5 * t * N * (cphi^2 * l^2) * (1 + (1/12) * cphi^2 * l^2 * (l4coef + (1/30) * cphi^2 * l^2 * (l6coef + (1/56) * cphi^2 * l^2 * l8coef)))
    y = y * UTMScaleFactor
    y += 10000000 * (y < 0 ? 1 : 0)

    # Define hemisphere
    hm = sign(lat)

    return x, y, zn, hm
end


"""
    ArcLengthOfMeridian(ϕ)

Computes the meridian arc length for a given latitude (ϕ in radians).

# Arguments
- `ϕ`: Latitude in radians.

# Returns
- Meridian arc length.
"""
function ArcLengthOfMeridian(ϕ)
    sm_a = 6378137.0
    sm_b = 6356752.314
    n = (sm_a - sm_b) / (sm_a + sm_b)
    α = (sm_a + sm_b) / 2 * (1 + (n^2 / 4) + (n^4 / 64))
    β = (-3 * n / 2) + (9 * n^3 / 16) + (-3 * n^5 / 32)
    γ = (15 * n^2 / 16) - (15 * n^4 / 32)
    δ = (-35 * n^3 / 48) + (105 * n^5 / 256)
    ϵ = (315 * n^4 / 512)

    result = α * (ϕ + β * sin(2 * ϕ) + γ * sin(4 * ϕ) + δ * sin(6 * ϕ) + ϵ * sin(8 * ϕ))
    return result
end



end