"""Extracts a date (year, month, day) from a filename string (nm)
by matching known date patterns (yyyy, mm, dd) inside a pattern string (patt)
that represents the filename format."""
function parseFnameDate(nm::AbstractString, patt::AbstractString)
    # If filename and pattern are not the same length, parsing cannot work reliably
    if length(nm) != length(patt)
        return missing, missing, missing  # Use `missing` to indicate failure
    end

    # Helper function to find the index of a substring from a list of options
    # e.g., look for "yyyy" or "YYYY" and return the first character index
    function findindex(str, substrs)
        for sub in substrs
            idx = findfirst(sub, str)  # Returns a range if found, e.g., 8:11
            if idx !== nothing
                return first(idx)      # Extract starting index (e.g., 8)
            end
        end
        return 0  # If no match found, return 0 as a sentinel
    end

    # Find starting index of each date component in the pattern string
    iy = findindex(patt, ["yyyy", "YYYY"])  # Year
    im = findindex(patt, ["mm", "MM"])      # Month
    id = findindex(patt, ["dd", "DD"])      # Day

    # Extract and parse each part from the filename string using known lengths
    # Year is 4 digits (e.g., 2025)
    yy = iy > 0 ? parse(Int, nm[iy:iy+3]) : missing

    # Month is 2 digits (e.g., 06)
    mm = im > 0 ? parse(Int, nm[im:im+1]) : missing

    # Day is 2 digits (e.g., 06)
    dd = id > 0 ? parse(Int, nm[id:id+1]) : missing

    # Return a tuple of (year, month, day) — may include `missing` if not found
    return yy, mm, dd
end