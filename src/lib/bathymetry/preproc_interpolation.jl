using Printf
using ..Interpolation: trinterpmap, trinterpmapUTM

"""
Interpolates bathymetry data onto a regular spatial grid.

Gathers all latitude, longitude, and depth values from the input `baths` array.
Performs 2D spatial interpolation on either UTM or geographic coordinates using a Gaussian kernel.
Returns the interpolated grid and relevant metadata.

# Arguments
- `baths`::Vector{Bathymetry}:
    Vector of bathymetry data objects, each with latitude, longitude, and depth vectors.
- `cellSz`::Float64:
    Grid cell size for interpolation, in meters or degrees depending on coordinate system (default: 10.0).
- `wRm`::Float64:
    Search radius (standard deviation of Gaussian kernel), in same units as `cellSz` (default: 10.0).
- `useUTM`::Bool:
    Whether to use UTM projection (`true`) or geographic coordinates (`false`) for interpolation.

# Returns
- `Is`::Matrix{Float64}:
    Interpolated depth surface (grid).
- `useUTM`::Bool:
    Indicates whether UTM projection was used.
- `gX_min`, `gX_max`, `gY_min`, `gY_max`::Float64:
    Bounding box of the interpolation grid.
- `znCoord`::Int:
    UTM zone used (if applicable), or 0 if geographic.
"""
function preproc_interpolation(
    baths::Array{Bathymetry};
    cellSz::Float64=10.0,
    wRm::Float64=10.0,
    useUTM::Bool=false
    )
    # --- Check input validity
    if isempty(baths)
        error("Input `baths` array is empty.")
    end

    # --- Initialize coordinate and depth arrays
    lat = Float64[]
    lon = Float64[]
    depth = Float64[]

    # --- Collect all data points from each transect in baths
    for (i, bath) in enumerate(baths)
        if length(bath.latitude) != length(bath.longitude) || length(bath.latitude) != length(bath.depth)
            error("Bathymetry element $i has inconsistent latitude, longitude, or depth array lengths.")
        end
        append!(lat, bath.latitude)
        append!(lon, bath.longitude)
        append!(depth, bath.depth)
    end

    if isempty(lat) || isempty(lon) || isempty(depth)
        error("No data points collected from baths for interpolation.")
    end

    if useUTM
        # --- Use UTM projection
        znCoord = round(Int, (lon[1] + 183) / 6)  # Compute UTM zone from first longitude
        # Convert lat/lon to UTM x/y coordinates
        xCoord, yCoord, znCoord = latlon2utmxy(znCoord, lat, lon)
        # Perform interpolation using UTM x/y
        Is, I, av, se, gY_min, gY_max, gX_min, gX_max = trinterpmapUTM(xCoord, yCoord, depth, wRm, cellSz)
    else
        # --- Use geographic (lat/lon) coordinates
        znCoord = 0  # Placeholder for geographic coordinates
        # Perform interpolation using lat/lon, flag geographic coordinates explicitly
        Is, I, av, se, gY_min, gY_max, gX_min, gX_max = trinterpmap(lat, lon, depth, wRm, cellSz)
    end

    # Discrepancies with Octave (tens of cm) due to the adding of floating-number errors! 
    @printf("Bathymetry mean deviation: %.2f m\n", av)
    @printf("Bathymetry standard error: %.2f m\n", se)

    # --- Return interpolated surface and metadata
    return Is, useUTM, gX_min, gX_max, gY_min, gY_max, znCoord
end
