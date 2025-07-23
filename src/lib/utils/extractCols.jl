"""This function extracts specific columns from the CSV data based on either header names or column indices."""
function extractCols(hdrs::Vector, cols::Vector, args...)
    ecols = []
    for arg in args
        for (i, hdr) in enumerate(hdrs)
            if (isa(arg, Number) && arg == hdr) || (isa(arg, AbstractString) && arg == hdr)
                push!(ecols, cols[i])
                break
            end
        end
    end
    return ecols
end