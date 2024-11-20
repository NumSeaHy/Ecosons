module Slopes

export Slope, slopesFromBathymetry

using Statistics
include("Geo.jl")
include("ComputeBathymetry.jl")
using .Geo
using .ComputeBathymetry

"""
    slopesFromBathymetry(bathymetry::Vector{Bathymetry}, krad::Float64) -> Vector{Slopes}

Computes slopes from bathymetry data along transects.

# Arguments
- `BAT`: Vector of `Bathymetry` objects containing latitude, longitude, and depth.
- `krad`: Kernel radius for the convolution function used in the interpolation, in meters.

# Returns
- `slopes`: Vector of `Slopes` objects containing slope magnitude, direction, and the cosine angle formed by the slope and the transect directions.

# Example
```julia
bathymetry = [Bathymetry(latitude, longitude, depth), ...]
krad = 1000.0
slopes = slopesFromBathymetry(bathymetry, krad)
"""
struct Slope
    slope::Vector{Float64}
    slope_dir::Vector{Float64}
    cang::Vector{Float64}
end

function slopesFromBathymetry(bathymetry, krad::Float64)::Vector{Slope}
    SLOPES = Vector{Slope}(undef, length(bathymetry))
    utmZ = -1

    for nt in eachindex(bathymetry)
        x, y, zn, _ = latlon2utmxy(utmZ, bathymetry[nt].latitude, bathymetry[nt].longitude)
        if nt == 1
            utmZ = zn
        end
        z = bathymetry[nt].depth

        gg = fill(NaN, length(z))
        tx = fill(NaN, length(z))
        ty = fill(NaN, length(z))

        for p in 1:length(z)
            d = hypot.(x .- x[p], y .- y[p])
            m = (d .< krad) .& .!isnan.(z)
            if any(m)
                zm = mean(filter(!isnan, z[m]))
                zs = std(filter(!isnan, z[m]))
                m = m .& (abs.(z .- zm) .<= 2 .* zs)

                pa_indices = findall(i -> i <= p && m[i], 1:length(z))
                pb_indices = findall(i -> i >= p && m[i], 1:length(z))

                if !isempty(pb_indices) && !isempty(pa_indices)
                    pa = first(pa_indices)
                    pb = first(pb_indices)
                    tx[p] = x[pb] - x[pa] + 1e-10
                    ty[p] = y[pb] - y[pa] + 1e-10
                    gg[p] = (z[pb] - z[pa]) / hypot(tx[p], ty[p])
                end
            end
        end

        slope_dir = (180/pi) .* atan.(ty, tx)
        cang = sqrt(0.5) .* ones(length(z))

        SLOPES[nt] = Slope(gg, slope_dir, cang)
    end

    return SLOPES
end






end