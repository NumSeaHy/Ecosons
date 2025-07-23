"""
Applies radial subsampling to each `Bathymetry` object in `baths` in-place, reducing data density based on spatial proximity.

# Arguments
- `baths::Array{Bathymetry}`: Array of `Bathymetry` structs to be subsampled.
- `sradius::Float64`: Search radius (in the same spatial units as latitude and longitude) for subsampling neighbors. Defaults to `10.0`.

# Returns
- Modified `baths` array with each `Bathymetry`'s data subsampled according to the search radius.

# Errors
- Returns `(1, "Invalid search radius; aborting")` if `sradius` is non-positive.
- Returns `"No depth data!"` if any `Bathymetry` object has `nothing` as its depth data.

# Notes
- The subsampling reduces the number of points by spatially aggregating data within the `sradius`.
- This function modifies the input `baths` array in-place.
"""
function subsampleBathymetry!(
    baths::Array{Bathymetry};
    sradius::Real = 10.0
    )::Array{Bathymetry}
    # --- Check for valid input ---
    if sradius <= 0
        error("Invalid search radius; must be positive")
    end

    for bath in baths
        if !isnothing(bath.depth)
            slat, slon, stme, sdep = radialSubsampling(
                sradius,
                bath.latitude,
                bath.longitude,
                bath.time,
                bath.depth
            )
        else
            return "No depth data!"
        end

        bath.latitude = slat
        bath.longitude = slon
        bath.time = stme
        bath.depth = sdep 
    end
    
    return baths
end
