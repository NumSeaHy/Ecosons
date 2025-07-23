include("parseCSVline.jl")
"""
Reads a delimited text file (e.g., CSV) and returns its contents as column-major data along with headers.

# Arguments
- `fname::String`: Path to the file to read.
- `hdr::Bool = true`: Whether the file includes a header row. If `true`, the first row is returned as a vector
of column names (as `String`). Otherwise, numeric column indices are used as headers.
- `csvsep::Char = ','`: The delimiter character to use (default is comma `','`). Can be set to tab (`'\t'`) or 
other delimiters as needed.

# Returns
- `cols::Vector{Any}`: A vector of columns, where each column is either a vector of parsed `Float64`s or `String`s,
depending on the column content.
- `headers::Vector{String}` or `Vector{Int}`: A vector of column names (if `hdr=true`) or numeric indices (if `hdr=false`).

# Behavior
- Skips empty lines and trims whitespace.
- Attempts to parse each column as `Float64`. If parsing fails, it leaves the column as a `Vector{String}`.
- Replaces empty cells with `"NaN"`.

# Errors
- Throws an error if the file does not exist.
"""
function csvreadcols(
    fname::String;
    hdr::Bool = true,
    csvsep::Char = ',')
    if !isfile(fname)
    error("File not found: $fname")
    end
    println("Computing space needed...")
    ssswd = Int[]
    ncmx = 0
    nr = 0

    lines = readlines(fname)
    filtered_lines = String[]
    for line in lines
        line = String(strip(line))
        isempty(line) && continue
        push!(filtered_lines, line)

        row = parseCSVline(line, csvsep)
        ncmx = max(ncmx, length(row))

        for (i, cell) in enumerate(row)
            len_cell = length(cell)
            if i <= length(ssswd)
                ssswd[i] = max(ssswd[i], len_cell)
            else
                push!(ssswd, len_cell)
            end
        end
    end

    nr = length(filtered_lines)
    sss = [fill(" ", nr) for _ in 1:ncmx]

    println("Loading CSV $nr records...")
    for (i, line) in enumerate(filtered_lines)
        row = parseCSVline(line, csvsep)
        for (j, val) in enumerate(row)
            sss[j][i] = isempty(val) ? "NaN" : val
        end
    end

    if hdr
        headers = [String(strip(ss[1])) for ss in sss]
        sss = [ss[2:end] for ss in sss]
    else
        headers = collect(1:ncmx)
    end

    println("Extracting rows...")
    cols = Vector{Any}(undef, ncmx)
    for (i, col_data) in enumerate(sss)
        try
            cols[i] = parse.(Float64, col_data)
        catch
            cols[i] = col_data
        end
    end

    return cols, headers
end
