"""
Computes bathymetry data from a given array of `SonarDataRAW` records.

# Arguments
- `data::Array{SonarDataRAW}`: A non-empty array of sonar echogram data structures, each containing geolocation and depth information.
- `depth_cutoff::Float64 = 0.0`: (Optional) Minimum depth threshold for filtering data points. Only depth values greater than this threshold will be included.

# Returns
- `Array{Bathymetry}`: An array of `Bathymetry` objects with filtered geospatial depth data.
"""
function compute_bathymetry(
    data::Vector{SonarDataRAW};
    depth_cutoff::Real = 0.0,
    )::Vector{Bathymetry}

    if isnothing(data) || isempty(data)
        error("No echograms defined")
    end

    println("Minimum depth cutoff: $(depth_cutoff)")
    baths = Bathymetry[]

    for (i, dta) in enumerate(data)
        # --- Field validation ---
        for fld in (:P, :Q, :G, :R)
            if !hasfield(typeof(dta), fld)
                error("SonarDataRAW at index $(i) is missing required field '$(fld)'")
            end
        end

        n_pings = size(dta.P, 1)
        if length(dta.G) < n_pings || length(dta.R) < n_pings || length(dta.Q) < n_pings
            error("SonarDataRAW[$i]: Inconsistent field lengths in P, Q, G, or R")
        end

        time = []; latitude = []; longitude = []; depth = []
        # --- Ping filtering ---
        for j in 1:n_pings
            dd = hasfield(typeof(dta.Q[j]), :depth) ? dta.Q[j].depth : convert_true_depth(dta.R[j] - 2, dta; ping = j)

            if dta.G[j].time < 0 || dd < depth_cutoff
                continue
            end
            push!(time, dta.G[j].time)
            push!(latitude, dta.G[j].latitude)
            push!(longitude, dta.G[j].longitude)
            push!(depth, dd)
        end
        bath = Bathymetry(
            dta.name,
            time,
            latitude,
            longitude,
            depth
        )

        push!(baths, bath)
    end

    return baths
end

function has_depth(q)
    hasfield(typeof(q), :depth) ? getfield(q, :depth) : nothing
end