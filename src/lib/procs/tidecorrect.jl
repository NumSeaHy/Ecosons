"""
This function applies tide height corrections to depth measurements (`sdepth`) based on:
- The times of the depth samples (`tmes`)
- The times of available tide height observations (`ttmes`)
- The tide heights at those times (`thgts`)

It uses cosine interpolation for smooth transitions between tide points,
and extrapolates similarly for values outside the known range.

Arguments:
- `sdepth`: Vector of raw sonar/measured depths (likely influenced by tides)
- `tmes`: Vector of timestamps corresponding to each depth value in `sdepth`
- `ttmes`: Vector of timestamps when tide height measurements were taken
- `thgts`: Vector of tide height values corresponding to each time in `ttmes`

Returns:
- A vector of corrected depth values (`cdepth`), with tide influence removed
"""
function tidecorrect(
    sdepth::AbstractVector,
    tmes::AbstractVector,
    ttmes::AbstractVector,
    thgts::AbstractVector)

    # Make a copy of the original depths to apply corrections to
    cdepth = copy(sdepth)

    # -------------------------------
    # 1. Extrapolate Before First Tide Measurement
    # -------------------------------
    # Identify indices of depth measurements that occurred before the first tide observation
    ii = findall(t -> t < ttmes[1], tmes)
    if !isempty(ii)
        # Apply cosine-based extrapolation using the first two tide heights
        # This provides a smooth estimate of tide height prior to the first measured value
        cdepth[ii] .= sdepth[ii] .- (
            thgts[2] - 0.5 * (thgts[2] - thgts[1]) *
            (1 .+ cos.(π .* (tmes[ii] .- ttmes[1]) ./ (ttmes[2] - ttmes[1])))
        )
    end

    # -------------------------------
    # 2. Interpolate Between Tide Measurements
    # -------------------------------
    # Loop over each pair of consecutive tide measurement intervals
    for n in 1:(length(ttmes) - 1)
        # Find indices of depth measurements between two known tide times
        ii = findall(t -> (ttmes[n] <= t <= ttmes[n+1]), tmes)
        if !isempty(ii)
            # Apply cosine interpolation to compute tide at each intermediate time
            # Subtract the interpolated tide height from the raw depth
            cdepth[ii] .= sdepth[ii] .- (
                thgts[n+1] - 0.5 * (thgts[n+1] - thgts[n]) *
                (1 .+ cos.(π .* (tmes[ii] .- ttmes[n]) ./ (ttmes[n+1] - ttmes[n])))
            )
        end
    end

    # -------------------------------
    # 3. Extrapolate After Last Tide Measurement
    # -------------------------------
    # Identify indices of depth measurements that occurred after the last tide observation
    ii = findall(t -> t > ttmes[end], tmes)
    if !isempty(ii)
        # Apply cosine-based extrapolation using the last two tide heights
        # Provides a smooth transition beyond the last measured tide value
        cdepth[ii] .= sdepth[ii] .- (
            thgts[end] - 0.5 * (thgts[end] - thgts[end-1]) *
            (1 .+ cos.(π .* (tmes[ii] .- ttmes[end-1]) ./ (ttmes[end] - ttmes[end-1])))
        )
    end

    return cdepth
end
