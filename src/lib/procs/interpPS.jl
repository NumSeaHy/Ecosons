using Dierckx, Interpolations

"""
Interpolates missing or invalid GPS coordinates (latitude and longitude) for a collection of positional data.
This is done by identifying points with valid time but invalid (zero) coordinates, setting them to `NaN`,
finding segments where GPS coordinates change, and interpolating missing values using spline interpolation over these segments.

## Arguments
- `PS`: A vector of objects of type GPS(e.g., structs) where each object must have `time`, `latitude`, and `longitude` fields.
 Objects with a time greater than `0` but with both latitude and longitude as `0` are considered to have missing coordinates and
 are set to `NaN` before interpolation.

## Operation
- The function modifies the input vector `PS` in-place. It first identifies points with valid geographic movement
by detecting changes in latitude or longitude.  It then computes midpoints for these segments and performs spline
interpolation to fill in missing or invalid latitude and longitude values based on the available data.
"""
function interpPS!(PS::Vector{GPSDataRAW})
    N = length(PS)
    lat = fill(NaN, N)
    lon = fill(NaN, N)
    tme = fill(NaN, N)

    # Extract valid data
    for n in 1:N
        tme[n] = PS[n].time
        if tme[n] > 0 && !(PS[n].latitude == 0 && PS[n].longitude == 0)
            lat[n] = PS[n].latitude
            lon[n] = PS[n].longitude
        end
    end

    # Find indices where latitude or longitude change
    msk = findall(i -> i < N && (lat[i+1] ≠ lat[i] || lon[i+1] ≠ lon[i]), 1:N-1)
    if isempty(msk)
        return PS  # No variation to interpolate
    end

    # Midpoints
    tmeM = (tme[msk] .+ tme[msk .+ 1]) ./ 2
    latM = (lat[msk] .+ lat[msk .+ 1]) ./ 2
    lonM = (lon[msk] .+ lon[msk .+ 1]) ./ 2

    # Remove NaNs
    valid = .!isnan.(tmeM) .& .!isnan.(latM) .& .!isnan.(lonM)
    tmeM = tmeM[valid]
    latM = latM[valid]
    lonM = lonM[valid]

    # Ensure enough data for interpolation
    if length(tmeM) < 2
        return PS
    end

    # Sort in time (Interpolations.jl requires sorted x-values)
    sorted_idx = sortperm(tmeM)
    tmeM_sorted = tmeM[sorted_idx]
    latM_sorted = latM[sorted_idx]
    lonM_sorted = lonM[sorted_idx]

    # Construct interpolation functions
    lat_itp = LinearInterpolation(tmeM_sorted, latM_sorted, extrapolation_bc=Line())
    lon_itp = LinearInterpolation(tmeM_sorted, lonM_sorted, extrapolation_bc=Line())

    # Interpolate and update
    for n in 1:N
        PS[n].latitude = lat_itp(tme[n])
        PS[n].longitude = lon_itp(tme[n])
    end

    return PS
end
