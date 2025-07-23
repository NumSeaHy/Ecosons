"""
Extracts a unique identifier from a file path based on its parent folder and filename.

# Arguments
- `filepath::String`: The full path to a file.
- `remove_extension::Bool`: Whether to remove the file extension from the filename (default: `true`).

# Behavior
- Splits the path using both forward (`/`) and backward (`\\`) slashes to support cross-platform compatibility.
- Extracts the **immediate parent folder** and **filename**.
- Optionally removes the file extension from the filename.
- Returns a string in the format `parent_folder\\filename` (regardless of input separator style).

# Returns
- A `String` identifier in the form of `"parent_folder\\filename"` (extension removed if specified).
- Returns an empty string `""` if the path doesn't contain at least two components.
"""
function extract_identifier(
    filepath::String;
    remove_extension::Bool = true
    )
    # Normalize path separators (for cross-platform use)
    parts = split(filepath, ['\\', '/'])

    # Get the last two parts before the file extension
    if length(parts) >= 2
        folder = parts[end - 1]
        filename = parts[end]

        if remove_extension
            filename = split(filename, ".")[1]
        end

        return join([folder, filename], "\\")
    else
        return ""
    end
end
