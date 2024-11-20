module Utils

using Statistics, LinearAlgebra, Dierckx, DSP
include("./Geo.jl")
using .Geo

export triginterp, interpPS!, radialSubsampling, trinterpmap
"""
    trinterpmap(lat::Vector{Float64}, lon::Vector{Float64}, P::Vector{Float64}, wRm::Float64, cellSz::Float64)

Interpolate values at given latitudes (`lat`), longitudes (`lon`), and values (`P`) 
using a weight filter radius (`wRm`) and cell size (`cellSz`). It returns interpolated map (`Is`),
original point map (`I`), mean (`av`) and standard deviation (`se`) of interpolation error, 
and the map limits (`lat_min`, `lat_max`, `lon_min`, `lon_max`).

# Arguments
- `lat::Vector{Float64}`: Latitudes of the points.
- `lon::Vector{Float64}`: Longitudes of the points.
- `P::Vector{Float64}`: Values at the given lat-lon coordinates to be interpolated.
- `wRm::Float64`: Radius of the weight filter in meters.
- `cellSz::Float64`: Size of a map cell in meters.

# Returns
- `Is`: Interpolated map.
- `I`: Map of points before interpolation.
- `av`: Mean of the interpolation error.
- `se`: Standard deviation of the interpolation error.
- `lat_min`, `lat_max`, `lon_min`, `lon_max`: Map limits.
"""
function (lat::Vector{Float64}, lon::Vector{Float64}, P::Vector{Float64}, wRm::Float64, cellSz::Float64)
    earthR = (6378137.0 + 6356752.314) / 2

    # Initialize map limits
    lat_min, lat_max = extrema(filter(!isnan, lat))
    lon_min, lon_max = extrema(filter(!isnan, lon))

    lonscale = cos(deg2rad((lat_max + lat_min) / 2))
    sizeY = round(Int, deg2rad(lat_max - lat_min) * (earthR / cellSz))
    sizeX = round(Int, deg2rad(lonscale * (lon_max - lon_min) * (earthR / cellSz)))

    cI = zeros(sizeY, sizeX)
    I = zeros(sizeY, sizeX)

    for n in eachindex(lat)
        if !isnan(lon[n]) && !isnan(lat[n]) && !isnan(P[n])
            j = round(Int, 1 + (lon[n] - lon_min) / (lon_max - lon_min) * (sizeX - 1))
            i = round(Int, 1 + (lat_max - lat[n]) / (lat_max - lat_min) * (sizeY - 1))
            
            cI[i, j] += 1
            I[i, j] += P[n]
        end
    end

    # Handle no data case
    if sum(cI) == 0
        return fill(NaN, size(I)), I, NaN, NaN, NaN, NaN, NaN, NaN
    end

    I[cI .> 0] ./= cI[cI .> 0]

    wRs = wRm / cellSz
    hr = round(Int,3 * wRs)
    hat = zeros(2*hr + 1, 2*hr + 1)
    for i in -hr:hr, j in -hr:hr
        hat[hr+i+1, hr+j+1] = 1 / (1 + (i^2 + j^2) / wRs^2)
    end
    hat[hat .< 1 / (1 + (hr / wRs)^2)] .= 0
    hat .= hat / sum(hat)

    cIs = conv(cI .> 0, hat)
    cIs[abs.(cIs) .< 1e-16] .= 0
    Is = conv(I, hat)
    Is ./= cIs

    Is = Is[hr+1:end-hr, hr+1:end-hr]
    cIs = cIs[hr+1:end-hr, hr+1:end-hr]
    # Is[cIs .== 0] .= NaN

    av = mean(Is[cI .> 0] .- I[cI .> 0])
    se = std(Is[cI .> 0] .- I[cI .> 0])

    return Is, I, av, se, lat_min, lat_max, lon_min, lon_max
end


"""
    triginterp(t::Vector{Float64}, x::Vector{Float64}, tp::Vector{Float64}, T::Union{Float64,Nothing}=nothing)

Performs a minimum square trigonometric interpolation.

# Arguments
- `t`: Independent variable ("time").
- `x`: Values evaluated at `t`.
- `tp`: Interpolation abscissae.
- `T`: Interpolation period (optional; default is calculated based on `t`).

# Returns
- `xp`: Interpolated values at `tp`.
"""
function triginterp(t::Vector{Float64}, x::Vector{Float64}, tp::Vector{Float64}, T::Union{Float64,Nothing}=nothing)
    _eps = 1e-10
    # Ensure data are vectors (Julia's default so this step might be redundant unless working with matrix)

    # Remove NaNs
    sel = .!isnan.(t) .& .!isnan.(x)
    t, x = t[sel], x[sel]

    # Default period
    if T === nothing
        T = length(t) * (maximum(t) - minimum(t)) / (length(t) - 1)
    end

    # Average and residue
    A0 = mean(x)
    rx = x .- A0

    An = zeros(Float64, length(t))
    Bn = zeros(Float64, length(t))

    for n in 1:length(t)
        # Harmonic frequencies
        wfr = 2 * π * n / T
        cs = cos.(wfr .* t)
        sn = sin.(wfr .* t)

        # Trigonometric regression sums
        Scx = rx' * cs
        Ssx = rx' * sn
        Sc2 = cs' * cs
        Ss2 = sn' * sn
        Ssc = sn' * cs

        # Regression coefficients
        An[n] = (Ssc * Ssx - Ss2 * Scx) / (Ssc^2 - Sc2 * Ss2 + _eps)
        Bn[n] = (Ssc * Scx - Sc2 * Ssx) / (Ssc^2 - Sc2 * Ss2 + _eps)

        # Residue
        rx .-= An[n] .* cos.(wfr .* t) .+ Bn[n] .* sin.(wfr .* t)
    end

    # Interpolation formula
    xp = fill(A0, length(tp))
    for n in 1:length(t)
        wfr = 2 * π * n / T
        xp .+= An[n] .* cos.(wfr .* tp) .+ Bn[n] .* sin.(wfr .* tp)
    end

    return xp
end

"""
    interpPS!(PS::Vector{<:Any})

Interpolates missing or invalid GPS coordinates (latitude and longitude) for a collection of positional data.
This is done by identifying points with valid time but invalid (zero) coordinates, setting them to `NaN`,
finding segments where GPS coordinates change, and interpolating missing values using spline interpolation over these segments.

## Arguments
- `PS`: A vector of objects of type GPS(e.g., structs) where each object must have `time`, `latitude`, and `longitude` fields.
 Objects with a time greater than `0` but with both latitude and longitude as `0` are considered to have missing coordinates and
 are set to `NaN` before interpolation.

## Operation
- The function modifies the input vector `PS` in-place. It first identifies points with valid geographic movement by detecting changes in latitude or longitude.
 It then computes midpoints for these segments and performs spline interpolation to fill in missing or invalid latitude and longitude values based on the available data.

## Usage
```julia
# Assuming PS is a vector of objects with time, latitude, and longitude fields
interpPS!(PS)
"""
function interpPS!(PS)
    # Extract time, latitude, and longitude, setting invalid or zero entries to NaN
    tme = baths[1].time
    lat = [time > 0 && !(lat == 0 && lon == 0) ? lat : NaN for (time, lat, lon) in zip(baths[1].time, baths[1].latitude, baths[1].longitude)]
    lon = [time > 0 && !(lat == 0 && lon == 0) ? lon : NaN for (time, lat, lon) in zip(baths[1].time, baths[1].latitude, baths[1].longitude)]
    
    # Find indices where either latitude or longitude changes
    msk = findall((diff(lat) .!= 0) .| (diff(lon) .!= 0))

    # Compute midpoints for time, latitude, and longitude
    tmeM = (baths[1].time[msk] .+ baths[1].time[msk .+ 1]) ./ 2
    latM = (lat[msk] .+ lat[msk .+ 1]) ./ 2
    lonM = (lon[msk] .+ lon[msk .+ 1]) ./ 2

    # Interpolate latitude and longitude using the midpoints and spline interpolation
    spl_lat = Spline1D(tmeM, latM; k=3)
    lat = spl_lat(tme)
    spl_lon = Spline1D(tmeM, lonM; k=3)
    lat = spl_lon(tme)


    # Update PS with the interpolated values
    for n in eachindex(PS)
        PS[n].latitude = lat[n]
        PS[n].longitude = lon[n]
    end
end


"""
    radialSubsampling(sradius::Float64, lat::Vector{Float64}, lon::Vector{Float64}, tme::Vector{Float64}, depth::Vector{Float64})

Subsamples a series of coordinates and depth values based on a search radius criterion.

# Arguments
- `sradius`: Search radius in meters.
- `lat`: Vector of latitude coordinates.
- `lon`: Vector of longitude coordinates.
- `tme`: Vector of measurement times.
- `depth`: Vector of depth values.

# Returns
- `slat`: Vector of subsampled latitudes.
- `slon`: Vector of subsampled longitudes.
- `stme`: Vector of subsampled times.
- `sdepth`: Vector of subsampled depths.

The function averages the coordinates, times, and depths for points within the search radius,
returning the reduced dataset.
"""
function radialSubsampling(sradius::Float64, lat::Vector{Float64}, lon::Vector{Float64}, tme::Vector{Float64}, depth::Vector{Float64})
    nn = length(depth)
    if nn == 1
        return [lat[1]], [lon[1]], [tme[1]], [depth[1]]
    end

    slat, slon, stme, sdepth = Float64[], Float64[], Float64[], Float64[]

    dd = sradius^2
    gpsx, gpsy, zn, hm = latlon2utmxy(-1, lat, lon)
    gpsxa, gpsya = gpsx[1], gpsy[1]

    p_last_valid = 1
    for p in 1:nn
        if isnan(gpsx[p]) || isnan(gpsy[p])
            continue
        end
        rr = (gpsxa - gpsx[p])^2 + (gpsya - gpsy[p])^2
        if rr >= dd || p == 1
            gpsxa, gpsya = gpsx[p], gpsy[p]
            indices = max(1, p-50):min(p+50, nn)
            filtered = filter(i -> (gpsx[i] - gpsx[p])^2 + (gpsy[i] - gpsy[p])^2 < dd, indices)
            if isempty(filtered)
                continue
            end
            sslat, sslon, sstme, ssdep = mean(lat[filtered]), mean(lon[filtered]), mean(tme[filtered]), median(depth[filtered])
            push!(slat, sslat)
            push!(slon, sslon)
            push!(stme, sstme)
            push!(sdepth, ssdep)
            p_last_valid = p
        end
    end

    return slat, slon, stme, sdepth
end






end