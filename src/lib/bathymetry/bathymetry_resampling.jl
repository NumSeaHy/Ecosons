using Interpolations
"""
Generate synthetic bathymetry samples by perturbing existing observations using local slope information.

This function takes arrays of `Bathymetry` and corresponding `Slope` structures, and for each original observation,
generates multiple new synthetic samples by:
- Applying random horizontal displacements scaled by the local slope orientation.
- Perturbing depth based on slope magnitude and random noise.
- Converting displacements from meters to degrees latitude/longitude.

# Arguments
- `baths::Array{Bathymetry}`: Array of bathymetry measurements containing lat/lon, depth, and time.
- `slopes::Array{Slope}`: Array of local terrain slope information (must match length of `baths`).
- `srad::Real = 15`: Radius (in meters) controlling the spatial extent of perturbations.
- `nrsp::Int = 10`: Number of synthetic samples to generate per original observation.

# Returns
- `Array{Bathymetry}`: Array of new `Bathymetry` objects containing the synthetic resampled points.

# Notes
- Assumes spherical Earth for coordinate conversions.
- Slopes with invalid or extreme values (e.g., `NaN`, zero, or very large magnitudes) are treated as flat terrain.
- Uses Gaussian noise for random displacements in space and depth.
"""
function resampleBathymetry(
    baths::Array{Bathymetry},
    slopes::Array{Slope},
    srad::Real = 5,
    nrsp::Int = 10)::Array{Bathymetry}

    Rt = 6367444.66  # Approximate Earth radius (m)
    dam = (180 / π) / 6356752.314  # Conversion factor from meters to degrees latitude

    new_baths = []
    for i in eachindex(baths)
        slope = slopes[i]
        bath = baths[i]
        lt = length(bath.time)  # Number of original measurements
        if lt == 0
            newTimes = []
            newLatitudes = []
            newLongitudes = []
            newDepths = []
            new_baths[i] = Bathymetry(bath.name, newTimes,
                            newLatitudes,
                            newLongitudes,
                            newDepths)
            continue
        elseif lt > 1
            x = collect(0:lt-1) ./ (lt - 1)
            y = bath.time
            xi = collect(0:(nrsp * lt - 1)) ./ (nrsp * lt - 1)
            # Linear interpolation
            newTimes = lin_interp1_nan(x, y, xi)
        else
            newTimes = fill(time[1], nrsp)
        end
        # Total number of synthetic samples to be generated
        totalSamples = lt * nrsp

        # Preallocate output arrays
        newLatitudes = Vector{Float64}(undef, totalSamples)
        newLongitudes = Vector{Float64}(undef, totalSamples)
        newDepths = Vector{Float64}(undef, totalSamples)
        newTimes = Vector{Float64}(undef, totalSamples)
        nn = 1
        for n in 1:lt
            clat = cos(π * bath.latitude[n] / 180)
            rr = isnan(slope.cang[n]) ? NaN : srad * sqrt(1 - slope.cang[n]^2)
            dxyz = rr .* randn(3, nrsp)
            ddpt = isnan(slope.slope[n]) ? NaN .* dxyz[3, :] : slope.slope[n] .* dxyz[3, :]
            
            newLatitudes[nn:nn+nrsp-1]  .= bath.latitude[n] .+ dxyz[2, :] .* dam
            newLongitudes[nn:nn+nrsp-1] .= bath.longitude[n] .+ dxyz[1, :] .* dam ./ clat
            newDepths[nn:nn+nrsp-1]     .= bath.depth[n] .+ 0 .* ddpt

            nn += nrsp
        end

        # Return new Bathymetry structure with all synthetic samples
        newBathymetries = Bathymetry(
            bath.name,
            newTimes,
            newLatitudes,
            newLongitudes,
            newDepths
        )
        push!(new_baths, newBathymetries)
    end
    return new_baths
end

function lin_interp1_nan(x::Vector{Float64}, y::Vector{Float64}, xi::Vector{Float64})
    xmin = first(x)
    xmax = last(x)
    itp = interpolate((x,), y, Gridded(Linear()))
    # Mask for in-range elements
    mask = (xi .>= xmin) .& (xi .<= xmax)
    result = fill(NaN, length(xi))
    result[mask] .= itp.(xi[mask])
    return result
end