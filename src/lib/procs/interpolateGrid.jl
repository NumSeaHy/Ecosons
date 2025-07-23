"""
General 2D grid interpolation function that bins scattered data points into a grid,
then applies smoothing with a hat-shaped kernel to produce an interpolated surface.

# Arguments
- `X`, `Y`: Arrays of coordinates (longitude/latitude if `isGeographic=true`, else projected coordinates like UTM)
- `P`: Array of property values (e.g., depth measurements) at each coordinate
- `wRm`: Interpolation radius in meters, controlling smoothing scale
- `cellSz`: Cell size in meters for the output grid resolution
- `isGeographic`: Boolean flag; set true if `X`, `Y` are geographic coordinates (lon/lat). Default is false.

# Returns
- `Is`: Smoothed/interpolated grid of property values
- `I`: Raw binned grid (average property per cell before smoothing)
- `av`: Mean deviation between smoothed and raw grid on sampled cells (quality metric)
- `se`: Standard error of the smoothing difference (quality metric)
- `X_min`, `X_max`, `Y_min`, `Y_max`: Bounds of the input coordinates (for reference)
"""

function interpolateGrid(X, Y, P, wRm, cellSz; isGeographic=false)
    # Mean Earth radius in meters
    earthR = (6378137.0 + 6356752.314) / 2

    # Coordinate bounds
    if isGeographic
        lat, lon = Y, X

        lat_min, lat_max = extrema(lat)
        lon_min, lon_max = extrema(lon)

        lonscale = cos(pi / 360 * (lat_max + lat_min))
        sizeY = round(Int, (pi / 180) * (lat_max - lat_min) * (earthR / cellSz))
        sizeX = round(Int, (pi / 180) * lonscale * (lon_max - lon_min) * (earthR / cellSz))

        transform_coords = (x, y) -> (
            round(Int, 1 + (x - lon_min) / (lon_max - lon_min) * (sizeX - 1)),
            round(Int, 1 + (lat_max - y) / (lat_max - lat_min) * (sizeY - 1))
        )
    else
        X_min, X_max = extrema(X)
        Y_min, Y_max = extrema(Y)

        sizeX = round(Int, (X_max - X_min) / cellSz)
        sizeY = round(Int, (Y_max - Y_min) / cellSz)

        transform_coords = (x, y) -> (
            round(Int, 1 + (x - X_min) / (X_max - X_min) * (sizeX - 1)),
            round(Int, 1 + (Y_max - y) / (Y_max - Y_min) * (sizeY - 1))
        )

        lat_min, lat_max, lon_min, lon_max = Y_min, Y_max, X_min, X_max
    end

    # Initialize accumulation arrays
    I = zeros(Float64, sizeY, sizeX)   # sum of property values per cell
    cI = zeros(Float64, sizeY, sizeX)  # count of points per cell
    ct = 0

    # Bin data into grid cells
    for n in eachindex(P)
        if !(isnan(X[n]) || isnan(Y[n]) || isnan(P[n]))
            j, i = transform_coords(X[n], Y[n])

            # Clamp to grid bounds
            j = clamp(j, 1, sizeX)
            i = clamp(i, 1, sizeY)

            I[i, j] += P[n]
            cI[i, j] += 1
            ct += 1
        end
    end

    # If no valid points, return NaNs
    if ct == 0
        nangrid = fill(NaN, sizeY, sizeX)
        return nangrid, nangrid, NaN, NaN, lat_min, lat_max, lon_min, lon_max
    end

    # Compute average per cell
    I[cI .> 0] ./= cI[cI .> 0]

    # Create smoothing kernel (hat function)
    wRs = wRm / cellSz
    hr = round(Int, 3 * wRs)
    hat = zeros(Float64, 2 * hr + 1, 2 * hr + 1)
    for dy in -hr:hr
        for dx in -hr:hr
            hat[hr + dy + 1, hr + dx + 1] = 1 / (1 + (dx^2 + dy^2) / wRs^2)
        end
    end
    cutoff = 1 / (1 + (hr / wRs)^2)
    hat[hat .< cutoff] .= 0
    hat ./= sum(hat)

    # Pad arrays manually for full convolution (to match Octave conv2 'full')
    pad_size = hr
    pad_mode = Pad(:replicate)

    # Full convolution via imfilter with padding
    cI_mask = cI .> 0

    # To get full convolution size like Octave conv2, pad inputs before filtering
    function padarray(arr, pad)
        h, w = size(arr)
        padded = zeros(eltype(arr), h + 2*pad, w + 2*pad)
        padded[pad+1:pad+h, pad+1:pad+w] .= arr

        # replicate edges
        # top
        padded[1:pad, pad+1:pad+w] .= arr[1:1, :]
        # bottom
        padded[pad+h+1:end, pad+1:pad+w] .= arr[end:end, :]
        # left
        padded[:, 1:pad] .= padded[:, pad+1:pad+1]
        # right
        padded[:, pad+w+1:end] .= padded[:, pad+w:pad+w]
        return padded
    end

    I_padded = padarray(I, pad_size)
    cI_mask_padded = padarray(Float64.(cI_mask), pad_size)

    # Convolve
    Is_full = imfilter(I_padded, hat, pad_mode)
    cIs_full = imfilter(cI_mask_padded, hat, pad_mode)

    # Crop output to match Octave indexing: from hr to end-hr-1
    start_idx = hr + 1
    end_idx_row = size(Is_full, 1) - hr - 1
    end_idx_col = size(Is_full, 2) - hr - 1

    Is = Is_full[start_idx:end_idx_row, start_idx:end_idx_col]
    cIs = cIs_full[start_idx:end_idx_row, start_idx:end_idx_col]

    # Crop I and cI the same way for stats to avoid dimension mismatch
    I_cropped = I[start_idx - pad_size : end_idx_row - pad_size, start_idx - pad_size : end_idx_col - pad_size]
    cI_cropped = cI_mask[start_idx - pad_size : end_idx_row - pad_size, start_idx - pad_size : end_idx_col - pad_size]

    # Mark cells with zero weight as NaN
    Is[cIs .== 0] .= NaN

    # Compute statistics on valid cells
    mask = cI_cropped .> 0
    av = mean(skipmissing(Is[mask] .- I_cropped[mask]))
    se = std(skipmissing(Is[mask] .- I_cropped[mask]))

    return Is, I, av, se, lat_min, lat_max, lon_min, lon_max
end
