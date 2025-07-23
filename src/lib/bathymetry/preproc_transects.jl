"""
Extracts and prepares transect data from either raw `SonarDataRAW` or processed `Bathymetry` records.

# Arguments
- `baths`: Vector of `Bathymetry` objects (used when `sel == 2`).
- `data`: Vector of `SonarDataRAW` objects (used when `sel == 1`).
- `sel`: Integer selector:
    - `1`: Use `data`
    - `2`: Use `baths`
- `use_utm`: If `true`, convert coordinates to UTM. Otherwise, use lat/lon.

# Returns
- `ntr`: Transect IDs corresponding to each data point.
- `utmCoords`: Whether UTM coordinates are used.
- `xCoord`: Easting (if UTM) or longitude.
- `yCoord`: Northing (if UTM) or latitude.
- `znCoord`: UTM zone (if UTM), otherwise NaN.
- `depth`: Depth values (empty if `sel == 1`).
- `time`: Time values for each point.
"""
function preproc_transects(
    baths::Array{Bathymetry},
    data::Array{SonarDataRAW};
    sel::Int = 2,
    use_utm::Bool = false
)
    # === Initialize outputs ===
    ntr = Int[]
    utmCoords = false
    xCoord = Float64[]
    yCoord = Float64[]
    znCoord = NaN

    lat = Float64[]
    lon = Float64[]
    depth = Float64[]
    time = Float64[]

    # === Input checks ===
    if sel == 1
        if isempty(data)
            error("Input `data` array is empty but sel=1 (use SonarDataRAW).")
        end
    elseif sel == 2
        if isempty(baths)
            error("Input `baths` array is empty but sel=2 (use Bathymetry).")
        end
    else
        error("Invalid sel value: $sel. Must be 1 (SonarDataRAW) or 2 (Bathymetry).")
    end

    # === Extract coordinates and metadata ===
    if sel == 1
        for (idx, dta) in enumerate(data)
            # Check SonarDataRAW fields presence (optional but recommended)
            if !(:G ∈ fieldnames(typeof(dta)))
                error("SonarDataRAW element $idx missing field 'G'")
            end
            for g in dta.G
                if g.time >= 0
                    push!(ntr, idx)
                    push!(lat, g.latitude)
                    push!(lon, g.longitude)
                    push!(time, g.time)
                end
            end
        end

    elseif sel == 2
        for (idx, bath) in enumerate(baths)
            ll = length(bath.time)
            if length(bath.latitude) != ll || length(bath.longitude) != ll || length(bath.depth) != ll
                error("Bathymetry element $idx has inconsistent array lengths.")
            end
            append!(ntr, fill(idx, ll))
            append!(lat, bath.latitude)
            append!(lon, bath.longitude)
            append!(depth, bath.depth)
            append!(time, bath.time)
        end
    end

    # === Coordinate transformation ===
    if use_utm
        if isempty(lon)
            error("No longitude data available for UTM conversion.")
        end
        utmCoords = true
        znCoord = round(Int, (lon[1] + 183) / 6)
        xCoord, yCoord, znCoord = latlon2utmxy(znCoord, lat, lon)
    else
        xCoord = lon
        yCoord = lat
        znCoord = NaN
    end

    return ntr, utmCoords, xCoord, yCoord, znCoord, depth, time
end
