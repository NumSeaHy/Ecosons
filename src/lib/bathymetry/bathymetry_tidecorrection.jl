include("../procs/tidecorrect.jl")
include("../procs/tidecorrectDay.jl")

"""
Applies tide correction to a set of Bathymetry objects in-place.

# Arguments
- `baths::Array{Bathymetry}`: Array of Bathymetry structs to correct.
- `tide_file::String`: Tide file path or placeholder if not used directly.
- `dtf::Int`: Method for parsing the date:
    - `1`: Extract date from filename using a pattern.
    - `2`: Date is in DD-MM-YYYY format.
    - `3`: Date is in YYYY-MM-DD format.
    - `4`: `datafile_name` is a Julia tuple string like "[2024, 06, 15]".
    
# Keyword Arguments
- `tdi::Int`: Tide data method:
    - `1`: Manual tide data (`tide_times`, `tide_heights`).
    - `2`: Explicit tide file (`tide_file`).
    - `3`: Auto-resolve tide file using `tide_file_pattern`.
- `date_pattern::String`: Used with `dtf == 1`, pattern to parse date.
- `tide_file_pattern::String`: Used with `tdi == 3`, e.g. `"tides-yyyyMMdd.txt"`.
- `datafile_name::String`: Input name used to infer date.
- `tide_times::Vector{Float64}`: Used with `tdi == 1`, tide times (seconds or fractional days).
- `tide_heights::Vector{Float64}`: Used with `tdi == 1`, tide heights (in meters).

# Returns
- `(baths)`: Modified array of Bathymetry structs with corrected depths.
- On error, returns a tuple: `(1, "Error message")`
"""
function tideCorrection!(
    baths::Array{Bathymetry},
    tide_file::String;
    dtf::Int = 1,
    tdi::Int = 2,
    date_pattern::AbstractString = "",
    tide_file_pattern::String = "",
    datafile_name::AbstractString = "",
    tide_times::Vector{Float64} = Float64[],
    tide_heights::Vector{Float64} = Float64[]
)
    # Parse date
    yy, mm, dd = try
        if dtf == 1
            parseFnameDate(datafile_name, date_pattern)
        elseif dtf == 2
            parseDDMMYYYY(datafile_name)
        elseif dtf == 3
            parseYYYYMMDD(datafile_name)
        elseif dtf == 4
            eval(Meta.parse(datafile_name))  # Interprets string tuple
        else
            error("Invalid date format selection")
        end
    catch e
        error("Date parsing failed: $(e)")
    end

    # Method 1: Manual tide data
    if tdi == 1
        if length(tide_times) < 2 || length(tide_heights) < 2
            error("At least two tide entries required for interpolation")
        end
        idx = sortperm(tide_times)
        sorted_times = tide_times[idx]
        sorted_heights = tide_heights[idx]

        for bath in baths
            new_depth = tidecorrect(bath.depth, bath.time, sorted_times, sorted_heights)
            bath.depth = new_depth
        end

    # Method 2: Use tide file explicitly
    elseif tdi == 2
        if isempty(tide_file)
            error("Tide file not specified")
        end
        for bath in baths
            new_depth= tidecorrectDay(bath.depth, bath.time, tide_file)
            bath.depth = new_depth
        end

    # Method 3: Auto-generate tide file name
    elseif tdi == 3
        if isempty(tide_file_pattern)
            error("Tide file pattern is required for auto-generation")
        end
        f = replace(tide_file_pattern, [
            "yyyy" => lpad(string(yy), 4, '0'),
            "yy"   => lpad(string(mod(yy, 100)), 2, '0'),
            "MM"   => lpad(string(mm), 2, '0'),
            "dd"   => lpad(string(dd), 2, '0')
        ])
        if !isfile(f)
            error("Tide file $f not found")
        end
        for bath in baths
            new_depth = tidecorrectDay(bath.depth, bath.time, f)
            bath.depth = new_depth
        end

    else
        error("Invalid tide data input method (tdi)")
    end

    println("Tide correction applied to bathymetric data")
    return baths
end

# --- Helper parsers ---
function parseYYYYMMDD(nme::AbstractString)
    yy = parse(Int, nme[1:4])
    mm = parse(Int, nme[6:7])
    dd = parse(Int, nme[9:10])
    return (yy, mm, dd)
end

function parseDDMMYYYY(nme::AbstractString)
    yy = parse(Int, nme[7:10])
    mm = parse(Int, nme[4:5])
    dd = parse(Int, nme[1:2])
    return (yy, mm, dd)
end