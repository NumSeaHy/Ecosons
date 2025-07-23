"""Parses a single line of a CSV-like string using the specified field separator."""
function parseCSVline(s::String, csvsep::Char)
    result = String[]                    # Initialize an empty array of strings to store parsed fields
    ss = split(s, csvsep)                # Split the input line by the separator (',' or ';')

    for item in ss
        item = strip(item)               # Remove leading and trailing whitespace

        # Handle quoted fields
        if startswith(item, '"') && endswith(item, '"')
            # If field starts and ends with double quotes, remove the quotes
            push!(result, strip(item[2:end-1]))
        elseif startswith(item, '"')
            # If field starts with a quote but does not end with one (incomplete)
            # Remove the starting quote only
            push!(result, strip(item[2:end]))
        else
            # Otherwise, just push the trimmed field as is
            push!(result, item)
        end
    end

    return result  # Return the array of cleaned fields (strings)
end
