"""
Reads tab-separated values (TSV) from a text file and organizes the data column-wise.

# Example
```julia
cols, headers = tsvreadcols("data.tsv", hdr=true)
println(headers)  # ["Longitude", "Latitude", "Depth"]
println(cols[1])  # [12.5, 13.0, 14.2]
"""
function tsvreadcols(fname::String; hdr::Bool=true)
    # Open file for reading
    open(fname, "r") do io
        sss = Vector{Vector{String}}()  # to hold columns as vectors of strings
        nr = 0  # row counter
        ncmx = 0  # max columns
        
        for line in eachline(io)
            nr += 1
            ss = split(line, '\t')
            nc = length(ss)
            # Resize sss to have enough columns
            while length(sss) < nc
                push!(sss, String[])  # add new empty column
            end
            # Append each cell to its column
            for n in 1:nc
                push!(sss[n], ss[n])
            end
            # Update max columns
            ncmx = max(ncmx, nc)
        end

        # Extract headers
        headers = Vector{Union{String, Int}}(undef, ncmx)
        if hdr
            for n in 1:ncmx
                headers[n] = String(strip(sss[n][1]))
                sss[n] = sss[n][2:end]  # remove header row from data
            end
        else
            for n in 1:ncmx
                headers[n] = n
            end
        end

        # Convert columns to numbers where possible, else keep strings
        cols = Vector{Any}(undef, ncmx)
        for n in 1:ncmx
            col = sss[n]
            nums = tryparse.(Float64, col)
            if all(x -> x !== nothing, nums)
                cols[n] = Float64[]
                for x in nums
                    push!(cols[n], x === nothing ? NaN : x)
                end
            else
                cols[n] = col
            end
        end

        return cols, headers
    end
end
