"""
Exports slope analysis results alongside bathymetric metadata to a tab-delimited text file.

# Arguments
- `baths::Array{Bathymetry}`: Array of `Bathymetry` structs, each containing latitude, longitude, and depth arrays.
- `slopes::Array{Slope}`: Array of `Slope` structs, each containing slope magnitude, transect direction, and cosine angle arrays.
- `export_dir::String`: Output directory where the file will be written.
- `export_file::String`: Name of the output text file (e.g. `"slopes.txt"`).

# Behavior
- Creates `export_dir` if it does not exist.
- For each paired `Bathymetry` and `Slope` entry, exports each point as a row with the following columns:
  - `ID`: Global sequential identifier
  - `lat`: Latitude (7 decimal places)
  - `lon`: Longitude (7 decimal places)
  - `depth`: Depth (2 decimal places)
  - `slope`: Slope magnitude (4 decimal places)
  - `transect_direction`: Direction of transect in degrees (2 decimal places)
  - `cosine`: Cosine of the angle between slope vector and transect (4 decimal places)
- Outputs a header row and all data in tab-separated format.
- Returns a tuple `(0, "")` on success.
"""
function export_slopes(
    baths::Array{Bathymetry},
    slopes::Array{Slope},
    export_file::String;
    )

    open(export_file, "w") do io
        println(io, "ID\tlat\tlon\tdepth\tslope\ttransect_direction\tcosine")
        id = 0
        for i in eachindex(baths)
            slope = slopes[i]
            bath = baths[i]
            n_points = length(slope.slope)
            for n in 1:n_points
                id += 1
                line = string(
                    id, " ",
                    round(bath.latitude[n], digits=7), " ",
                    round(bath.longitude[n], digits=7), " ",
                    round(bath.depth[n], digits=2), " ",
                    round(slope.slope[n], digits=4), " ",
                    round(slope.trans_dir[n], digits=2), " ",
                    round(slope.cang[n], digits=4)
                )
                println(io, line)
            end
        end
    end

    println("File $(export_file) created!")

    return 0, ""
end
