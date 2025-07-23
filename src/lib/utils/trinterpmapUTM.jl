"""
Interpolates scattered data in projected coordinates (e.g., UTM) onto a 2D regular grid using a distance-weighted smoothing kernel.

# Arguments
- `gX::AbstractVector{<:Real}`: X coordinates in meters (e.g., UTM Easting).
- `gY::AbstractVector{<:Real}`: Y coordinates in meters (e.g., UTM Northing).
- `P::AbstractVector{<:Real}`: Data values to interpolate (e.g., depth).
- `wRm::Real`: Interpolation radius in meters. Determines the spatial influence of each point.
- `cellSz::Real`: Desired grid resolution in meters.

# Returns
- `Is::Matrix{Float64}`: Interpolated (smoothed) 2D map.
- `I::Matrix{Float64}`: Raw averaged values per cell before smoothing.
- `av::Float64`: Mean deviation between `Is` and `I` at populated locations.
- `se::Float64`: Standard error of the deviation.
- `gX_min::Float64`, `gX_max::Float64`: X-coordinate (Easting) bounds of the grid.
- `gY_min::Float64`, `gY_max::Float64`: Y-coordinate (Northing) bounds of the grid.
"""
function trinterpmapUTM(gX, gY, P, wRm, cellSz)
    # Compute grid bounds
    gX_min, gX_max = extrema(gX)
    gY_min, gY_max = extrema(gY)

    sizeX = round(Int, (gX_max - gX_min) / cellSz)
    sizeY = round(Int, (gY_max - gY_min) / cellSz)

    # Initialize grids
    I = zeros(Float64, sizeY, sizeX)  # accumulated values
    cI = zeros(Float64, sizeY, sizeX) # counts

    # Bin data
    for n in eachindex(P)
        x, y, p = gX[n], gY[n], P[n]
        if !isnan(x) && !isnan(y) && !isnan(p)
            j = clamp(round(Int, 1 + (x - gX_min) / (gX_max - gX_min) * (sizeX - 1)), 1, sizeX)
            i = clamp(round(Int, 1 + (gY_max - y) / (gY_max - gY_min) * (sizeY - 1)), 1, sizeY)
            I[i, j] += p
            cI[i, j] += 1
        end
    end

    # Return NaNs if no data
    if all(cI .== 0)
        return fill(NaN, sizeY, sizeX), fill(NaN, sizeY, sizeX), NaN, NaN, gX_min, gX_max, gY_min, gY_max
    end

    # Compute average values per cell
    I[cI .> 0] ./= cI[cI .> 0]

    # Construct smoothing kernel (hat)
    wRs = wRm / cellSz
    hr = round(Int, 3 * wRs)
    hat = [1 / (1 + (i^2 + j^2) / wRs^2) for i in -hr:hr, j in -hr:hr]
    cutoff = 1 / (1 + (hr / wRs)^2)
    hat[hat .< cutoff] .= 0
    hat ./= sum(hat)

    # Convolve I and mask
    I_smooth = imfilter(I, hat, Pad(:replicate))
    M_smooth = imfilter(cI .> 0, hat, Pad(:replicate))

    # Normalize, avoiding divide-by-zero
    Is = fill(NaN, size(I_smooth))
    mask = M_smooth .> 1e-8
    Is[mask] .= I_smooth[mask] ./ M_smooth[mask]

    # Crop edges
    if size(Is, 1) <= 2hr || size(Is, 2) <= 2hr
        error("Grid too small after convolution cropping — returning uncropped result")
    else
        Is_crop = Is[hr+1:end-hr, hr+1:end-hr]
        I_crop = I[hr+1:end-hr, hr+1:end-hr]
        cI_crop = cI[hr+1:end-hr, hr+1:end-hr]
    end

    # Deviation metrics
    valid_mask = cI_crop .> 0
    devs = skipmissing(Is_crop[valid_mask] .- I_crop[valid_mask])
    av = mean(devs)
    se = std(devs)

    return Is_crop, I, av, se, gX_min, gX_max, gY_min, gY_max
end
