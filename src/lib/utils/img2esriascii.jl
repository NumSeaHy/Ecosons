"""
Export a 2D image (gridded data) to an ESRI ASCII raster file.

# Arguments
- `fn::String`: Output file path (including `.asc` extension).
- `I::Matrix{<:Real}`: 2D array of raster data values.
- `x_min::Float64`: Minimum X (left/east) coordinate of the raster extent.
- `x_max::Float64`: Maximum X (right/west) coordinate of the raster extent.
- `y_min::Float64`: Minimum Y (bottom/south) coordinate of the raster extent.
- `y_max::Float64`: Maximum Y (top/north) coordinate of the raster extent.

# Behavior
- Computes uniform cell size from `x_max - x_min` and number of columns.
- Replaces `NaN` values with `-9999` (standard NoData marker).
- Ensures the output directory exists.
- Writes data row by row in top-down order (first row = top of grid).

# Output
Creates an ESRI ASCII raster file with the `.asc` extension compatible with most GIS tools.

"""
function img2esriascii(fn::String, I::Matrix{<:Real},
                       x_min::Float64, x_max::Float64,
                       y_min::Float64, y_max::Float64)

    height, width = size(I)
    cellsize = (x_max - x_min) / width
    nodata = -9999

    # Replace NaN with NoData value
    I_clean = copy(I)
    I_clean[isnan.(I_clean)] .= nodata

    # Ensure directory exists
    dir = dirname(fn)
    if !isdir(dir)
        mkpath(dir)
    end

    # Write ESRI ASCII file
    open(fn, "w") do f
        println(f, "NCOLS $width")
        println(f, "NROWS $height")
        println(f, "XLLCORNER $x_min")
        println(f, "YLLCORNER $y_min")
        println(f, "CELLSIZE $cellsize")
        println(f, "NODATA_VALUE $nodata")
        for row in 1:height
            println(f, join(I_clean[row, :], " "))
        end
    end
    println("Binary file created!")
end
