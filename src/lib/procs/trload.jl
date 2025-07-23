"""
Load tab-separated values from a text file and extract latitude, longitude, and parameter columns.

# Arguments
- `fn`: Path to the text file to load.
- `nlat`: Column index (1-based) for latitude values.
- `nlon`: Column index (1-based) for longitude values.
- `nP`: Column index (1-based) for the scalar parameter (e.g., intensity, depth, etc.).

# Returns
A tuple of vectors: `lat`, `lon`, and `P`, each containing parsed `Float64` values from the specified columns.

# Notes
- Assumes the file has a header line, which is skipped.
- Columns are expected to be tab-separated.
"""
function trload(fn::AbstractString, nlat::Int, nlon::Int, nP::Int)
    lat = Float64[]
    lon = Float64[]
    P = Float64[]
    
    open(fn, "r") do f
        readline(f)  # skip header line
        for line in eachline(f)
            ss = split(line, '\t')
            push!(lat, parse(Float64, ss[nlat]))
            push!(lon, parse(Float64, ss[nlon]))
            push!(P,   parse(Float64, ss[nP]))
        end
    end
    
    return lat, lon, P
end
