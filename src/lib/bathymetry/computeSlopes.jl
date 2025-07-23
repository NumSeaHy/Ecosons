"""
Compute slope information for a set of bathymetry transects.

# Arguments
- `baths::Array{Bathymetry}`: Array of `Bathymetry` objects, each representing a transect with time and position data.
- `slopes::Array{Slope}`: Optional precomputed slope data. If not empty, it is returned directly.
- `choice::Int`: Determines slope computation method:
    - `1`: Load slope data from a CSV file.
    - `2`: Assign default slope values (`slope = 0.0`, `trans_dir = -1.0`, `cang = 0.5`).
- `csv_file::String`: Path to CSV file containing slope information (used only when `choice == 1`).
- `has_header::Bool`: Specifies whether the CSV file contains a header row.
- `col_id::Union{String, Int}`: Column identifier for matching ping IDs with bathymetry points.
- `col_slp::Union{String, Int}`: Column identifier for slope magnitude values.
- `col_ang::Union{String, Int}`: Column identifier for slope angle (in degrees).
- `col_tang::Union{String, Int}`: Column identifier for travel or bathymetry direction (in degrees).
- `deg_factor::Float64`: Conversion factor from degrees to radians (default is `π/180`).
- `slope_factor::Float64`: Multiplier applied to slope magnitudes (default is `0.01`).

# Returns
- `Array{Slope}`: An array of `Slope` objects corresponding to each bathymetry transect, containing:
    - `slope`: Slope magnitude.
    - `trans_dir`: Travel direction in radians.
    - `cang`: Cosine of the angle difference between slope direction and travel direction.

# Notes
- When `choice == 1`, the CSV file is parsed and the slopes are matched to bathymetry records based on ID.
- When `choice == 2`, default placeholder slopes are assigned.
- If `slopes` is not empty, it is returned as-is and computation is skipped.

# Throws
- `ArgumentError`: If `choice` is invalid or the CSV file is not found or invalid.
"""
function computeSlopes(
    baths::Array{Bathymetry},
    slopes::Array{Slope} = Slope[];
    choice::Int = 2,
    csv_file::String = "",
    has_header::Bool = true,
    col_id::Union{String, Int} = "",  # Column in CSV identifying the ping ID or index to match bathsymetry data points
    col_slp::Union{String, Int} = "", # Column containing slope magnitude values (e.g., seabed slope)
    col_ang::Union{String, Int} = "", # Column containing slope direction in degrees (orientation of the slope)
    col_tang::Union{String, Int} = "",# Column containing bath (or travel) direction in degrees
    deg_factor::Float64 = π/180,      # Degrees to radians conversion factor
    slope_factor::Float64 = 0.01,     # Optional multiplier for slope magnitude
    )::Array{Slope}

    if !isempty(slopes)
        println("Slopes already computed")
        return slopes
    end

    if choice == 1
        SLOPES = []
        # CSV input
        if isempty(csv_file) || !isfile(csv_file)
            throw(ArgumentError("Invalid or missing CSV file: '$csv_file'"))
        end

        cols, headers = csvreadcols(csv_file, has_header)
        ecols = extractCols(headers, cols, col_id, col_slp, col_ang, col_tang)

        sort_idx = sortperm(ecols[1])
        for i in eachindex(ecols)
            ecols[i] = ecols[i][sort_idx]
        end

        nid = 1
        id_counter = 0
        for bath in baths
            N = length(bath.time)
            slope = Slope(Float64[], Float64[], Float64[])
            for _ in 1:N
                id_counter += 1
                if nid <= length(ecols[1]) && id_counter == ecols[1][nid]
                    slope.slope =  slope_factor * ecols[2][nid]
                    slope.trans_dir = deg_factor * ecols[4][nid]
                    slope.cang = cos(deg_factor * (ecols[3][nid] - ecols[4][nid]))
                    nid += 1
                else
                    slope.slope =  0.0
                    slope.trans_dir = -1.0
                    slope.cang = 0.5
                end
            end
            push!(SLOPES, slope)
        end
        return SLOPES
       
    elseif choice == 2
        SLOPES = []
        for bath in baths
            N = length(bath.time)
            slope = Slope(zeros(N), -1.0 .* ones(N), 0.5 .* ones(N))
            push!(SLOPES, slope)
        end
        return SLOPES

    else
        throw(ArgumentError("Invalid slope computation choice: $choice"))
    end
end