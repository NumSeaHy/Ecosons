using Statistics
"""
Reduces the density of bathymetric (depth) data by grouping nearby points
(within a given spatial radius) and returning representative averaged values.

Arguments:
- `sradius`: radial distance threshold (in meters)
- `lat`: vector of latitudes (degrees)
- `lon`: vector of longitudes (degrees)
- `tme`: vector of time values (can be any numeric representation)
- `depth`: vector of depth values (e.g., in meters)

Returns:
- `slat`: subsampled latitudes
- `slon`: subsampled longitudes
- `stme`: averaged time values per group
- `sdepth`: representative (median) depths per group
"""
function radialSubsampling(sradius::Float64,
                           lat::Vector{Float64},
                           lon::Vector{Float64},
                           tme::Vector{Float64},
                           depth::Vector{Float64})

    nn = length(depth)
    if nn == 1
        return ([lat[1]], [lon[1]], [tme[1]], [depth[1]])
    end

    slat = Float64[]
    slon = Float64[]
    stme = Float64[]
    sdepth = Float64[]

    dd = sradius^2  # squared search radius (m²)

    # UTM coordinates (zone autodetected, e.g., -1)
    gpsx, gpsy = latlon2utmxy(-1, lat, lon)

    gpsxa = gpsx[1]
    gpsya = gpsy[1]

    for p in 1:nn
        rr = (gpsxa - gpsx[p])^2 + (gpsya - gpsy[p])^2
        if !isnan(rr) && rr < dd
            continue  # too close to previous retained point
        elseif !isnan(rr)
            gpsxa = gpsx[p]
            gpsya = gpsy[p]
        else
            gpsxa = gpsx[p]
            gpsya = gpsy[p]
            continue
        end

        # Neighborhood averaging
        ss = 0
        sslat = 0.0
        sslon = 0.0
        sstme = 0.0
        ssdep = Float64[]

        for q in -50:50
            pq = p + q
            if pq > 0 && pq <= nn
                r2 = (gpsx[pq] - gpsx[p])^2 + (gpsy[pq] - gpsy[p])^2
                if r2 < dd
                    ss += 1
                    sslat += lat[pq]
                    sslon += lon[pq]
                    sstme += tme[pq]
                    push!(ssdep, depth[pq])
                end
            end
        end

        if ss > 0
            push!(slat, sslat / ss)
            push!(slon, sslon / ss)
            push!(stme, sstme / ss)

            # Robust mean depth (90th percentile: ~first decile value)
            sorted_dep = sort(ssdep)
            idx = 1 + floor(Int, length(sorted_dep) / 10)
            push!(sdepth, sorted_dep[idx])
        else
            push!(slat, NaN)
            push!(slon, NaN)
            push!(stme, NaN)
            push!(sdepth, NaN)
        end
    end

    return slat, slon, stme, sdepth
end
