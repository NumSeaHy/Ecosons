"""
Applies tidal correction to sonar depth measurements by:

- Reading hourly tide data from a file (with columns: hour, minute, height in cm)
- Converting tide timestamps to fractional hours
- Interpolating tide heights to match the timestamps of the depth measurements
- Subtracting interpolated tide height from measured depth to produce corrected depths

# Arguments
- `sdepth`: Vector of raw sonar/measured depths that include tidal influence
- `tmes`: Vector of timestamps (in fractional hours) corresponding to the values in `sdepth`
- `fname`: Path to a file containing tide data (tab-separated values: hour, minute, height in cm)

# Returns
- `cdepth`: Vector of tide-corrected depth values (same size as `sdepth`)
"""
function tidecorrectDay(
    sdepth::AbstractVector,
    tmes::AbstractVector,
    fname::AbstractString)
    if !isfile(fname)
        throw(ArgumentError("Tide file \"$fname\" not found."))
    end
    # Open the file and skip the first line
    open(fname, "r") do f
        readline(f)  # skip header line

        hr = Int[]
        mn = Int[]
        hcm = Float64[]
        
        while !eof(f)
            line = readline(f)
            # Parse the line expecting "int int float" separated by tabs
            parts = split(strip(line))  # splits on any whitespace (space, tab, etc.)
            if length(parts) < 3
                break
            end
            push!(hr, parse(Int, parts[1]))
            push!(mn, parse(Int, parts[2]))
            push!(hcm, parse(Float64, parts[3]))
        end
        
        tref = hr .+ (mn ./ 60)  # convert to fractional hours
        href = copy(hcm)               # tide heights in meters

        # Interpolated correction using triginterp (assumed implemented elsewhere)
        ddepth = triginterp(tref, href, tmes)

        # Apply correction
        cdepth = sdepth .- ddepth
        
        return cdepth
    end
end
