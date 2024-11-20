module Tides

include("Utils.jl")
using .Utils

export parseFnameDate, tidecorrect, tidecorrectDay!


"""
    tidecorrectDay(sdepth::Vector{Float64}, tmes::Vector{Float64}, fname::String) -> Vector{Float64}

Corrects depths through interpolation of recorded tide heights.

# Arguments
- `sdepth`: Vector of sonar depths.
- `tmes`: Vector of sonar measurement times.
- `fname`: Name of the data file containing tide heights.

# Returns
- `cdepth`: Vector of corrected depths.
"""
function tidecorrectDay!(bath, fname)
    hr, mn, hcm = Int[], Int[], Float64[]
    open(fname, "r") do f
        readline(f)  # Skip header line
        for line in eachline(f)
            data = split(line)
            push!(hr, parse(Int, data[1]))
            push!(mn, parse(Int, data[2]))
            push!(hcm, parse(Float64, data[3]))
        end
    end

    tref = hr .+ mn / 60.0
    href = hcm
    times = bath.time

    # Perform trigonometric interpolation
    itp = triginterp(tref, href, times)
    bath.depth .-=  itp
end


"""
    tidecorrect(sdepth, tmes, ttmes, thgts)

Corrects depths through trigonometrical interpolation of tide heights.

# Arguments
- `sdepth`: Sonar depths.
- `tmes`: Time of ping acquisition (hour, minute, second).
- `ttmes`:  Hours of the day of high and low tide acquisition (in decimal hours and sorted in ascending order).
- `thgts`:  Tide height at the moments of high and low tide (sorted according to `ttmes`)(in meters).

# Returns
- `cdepth`: Corrected depths.
"""
function tidecorrect!(sdepth::Vector{Float64}, tmes::Vector{Float64}, ttmes::Vector{Float64}, thgts::Vector{Float64})
    # Note: No need to initialize cdepth as a copy of sdepth since we'll be modifying sdepth directly.

    # Extrapolate before
    ii = tmes .< ttmes[1]
    sdepth[ii] .-= thgts[2] - 0.5 * (thgts[2] - thgts[1]) * (1 .+ cos(π * (tmes[ii] .- ttmes[1]) / (ttmes[2] - ttmes[1])))

    # Interpolate between
    for n in 1:(length(ttmes) - 1)
        ii = (ttmes[n] .<= tmes) .& (tmes .<= ttmes[n + 1])
        sdepth[ii] .-= thgts[n + 1] - 0.5 * (thgts[n + 1] - thgts[n]) * (1 .+ cos(π * (tmes[ii] .- ttmes[n]) / (ttmes[n + 1] - ttmes[n])))
    end

    # Extrapolate after
    ii = ttmes[end] .< tmes
    sdepth[ii] .-= thgts[end] - 0.5 * (thgts[end] - thgts[end - 1]) * (1 .+ cos(π * (tmes[ii] .- ttmes[end - 1]) / (ttmes[end] - ttmes[end - 1])))

    # No need to return sdepth as it's modified in-place
end





"""
    parseFnameDate(nm, patt) -> (yy, mm, dd)

Parse year (4 digits), month, and day from a filename according to a given pattern.

# Arguments
- `nm`: Filename to parse.
- `patt`: Pattern containing 'yyyy', 'mm', and 'dd' to indicate where in the filename
         the year, month, and day can be found, respectively.

# Returns
- `yy`, `mm`, `dd`: Year, month, and day extracted from the filename.
"""
function parseFnameDate(nm::String)
    
    patt = patt = "Lxxxx-DyyyyMMdd-Ttttttt-SSSSS"
    
    if length(nm) != length(patt)
        return (-1, -1, -1)
    end

    # Helper function to find a pattern and convert substring to number
    function extract_number(pattern::String, default)
        i = findfirst(occursin(pattern), patt)
        return i !== nothing ? parse(Int, nm[i[1]:i[1]+length(pattern)-1]) : default
    end

    # Year
    yy = extract_number("yyyy", NaN)
    yy = isnan(yy) ? extract_number("YYYY", NaN) : yy

    # Month
    mm = extract_number("mm", NaN)
    mm = isnan(mm) ? extract_number("MM", NaN) : mm

    # Day
    dd = extract_number("dd", NaN)
    dd = isnan(dd) ? extract_number("DD", NaN) : dd

    return (yy, mm, dd)
end

end