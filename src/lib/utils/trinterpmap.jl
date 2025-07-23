"""
Interpolates scattered data P at coordinates (lat, lon) onto a 2D grid.

# Inputs
- `lat`, `lon`: vectors of latitude and longitude coordinates (degrees).
- `P`: vector of values at each coordinate.
- `wRm`: filter radius in meters.
- `cellSz`: cell size of output map in meters.

# Outputs
- `Is`: interpolated map (weighted smoothing).
- `I`: map with averaged original points per cell.
- `av`: mean interpolation error (mean difference between Is and I at data points).
- `se`: std dev of interpolation error.
- `lat_min`, `lat_max`, `lon_min`, `lon_max`: limits of the map.
"""
function trinterpmap(lat::Vector{Float64}, lon::Vector{Float64}, P::Vector{Float64}, wRm::Real, cellSz::Real)
    earthR = (6378137.0 + 6356752.314) / 2

    # Determine map bounds
    lat_min = minimum(lat)
    lat_max = maximum(lat)
    lon_min = minimum(lon)
    lon_max = maximum(lon)
    println(lat_max)
    println(lat_min)
    println(lon_min)
    println(lon_max)
    # Scale factor for longitude based on latitude average
    lonscale = cos((pi/360)*(lat_max + lat_min))
    # Map size in cells
    sizeY = max(round(Int, (π/180) * (lat_max - lat_min) * (earthR / cellSz)), 1)
    sizeX = max(round(Int, (π/180) * lonscale * (lon_max - lon_min) * (earthR / cellSz)), 1)
    println("Map size: $(sizeX) x $(sizeY) cells")
    # Initialize accumulators
    cI = zeros(Int, sizeY, sizeX)
    I = zeros(Float64, sizeY, sizeX)
    ct = 0
    for n in eachindex(lat)
        if !isnan(lat[n]) && !isnan(lon[n]) && !isnan(P[n])
            # Map lat/lon to grid indices (row i, column j)
            j = Int(round(1 + (lon[n] - lon_min) / (lon_max - lon_min) * (sizeX - 1)))
            i = Int(round(1 + (lat_max - lat[n]) / (lat_max - lat_min) * (sizeY - 1)))
            # Accumulate counts and sums
            cI[i, j] += 1
            I[i, j] += P[n]
            ct += 1
        end
    end
  
    if ct == 0
        I .= NaN
        Is = copy(I)
        av = NaN
        se = NaN
        return Is, I, av, se, NaN, NaN, NaN, NaN
    end

    # Average values per cell where points exist
    I[cI .> 0] ./= cI[cI .> 0]

    # Weight radius in cell units
    wRs = wRm / cellSz
    hr = Int(3 * wRs)

    # Create hat filter kernel
    sizeH = 2 * hr + 1
    hat = zeros(Float64, sizeH, sizeH)
    for i in -hr:hr, j in -hr:hr
        hat[i+hr+1, j+hr+1] = 1 / (1 + (i^2 + j^2) / wRs^2)
    end

    cutoff = 1 / (1 + (hr / wRs)^2)
    hat[hat .< cutoff] .= 0
    hat ./= sum(hat)
    # Convolve counts and sums with the hat filter
    cIs = conv(cI .> 0, hat)  # boolean mask as float 0/1
    Is = conv(I, hat)

    # Normalize interpolated sums by convolved counts
    Is ./= cIs
    ny, nx = size(Is)
    Is  = Is[hr:(ny − hr − 1), hr:(nx − hr − 1)]
    cIs = cIs[hr:(ny − hr − 1), hr:(nx − hr − 1)]
    # Mask zeros in convolved counts as NaN in result
    Is[cIs .== 0] .= NaN

    # Calculate interpolation error statistics only where original data present
    data_mask = cI .> 0
    av = mean(Is[data_mask] .- I[data_mask])
    se = std(Is[data_mask] .- I[data_mask])

    println("wRm, cellSz, wRs, hr = ", (wRm, cellSz, wRs, hr))
    println("sizeX, sizeY = ", (sizeX, sizeY))
    println("Sum kernel elements: ", sum(hat))
    println("Center kernel value: ", hat[hr+1, hr+1])

    return Is, I, av, se, lat_min, lat_max, lon_min, lon_max
end
