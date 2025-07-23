"""
Computes approximate distances to the first available point from an array of GPS+time coordinates.

# Arguments
- `G`: An array of structs of type GPS containing `time`, `latitude`, and `longitude`.

# Returns
- `d2o`: Distances to the first available point.
"""
function gcoords2distances(G::Array{GPSDataRAW})

    Rt = 6371008.7714  # Radius of the Earth in meters
    
    # Pre-allocate arrays for time, latitude (in radians), and longitude (in radians)
    tt = fill(NaN, length(G))
    xlt = fill(NaN, length(G))
    xln = fill(NaN, length(G))
    
    # Extract valid time, latitude, and longitude values
    for n in eachindex(G)
        if G[n].time > 0
            tt[n] = G[n].time
            xlt[n] = (pi / 180) * G[n].latitude
            xln[n] = (pi / 180) * G[n].longitude
        end
    end
    
    # Find the index of the first available point
    n0 = argmin(tt)
    
    # Calculate Cartesian coordinates of the first point
    px0 = sin(xlt[n0]) * cos(xln[n0])
    py0 = sin(xlt[n0]) * sin(xln[n0])
    pz0 = cos(xlt[n0])
    
    # Compute distances to the first point
    d2o = Rt .* acos.(sin.(xlt) .* (px0 .* cos.(xln) .+ py0 .* sin.(xln)) .+ pz0 .* cos.(xlt))
    
    return d2o
end
