"""
Exports bathymetry crossing data to a tab-delimited text file.

# Arguments
- `TRANSECTCROSS::TransectCross`: The bathymetry crossing data structure containing transect identifiers,
  ping numbers, coordinates, and depth differences.
- `export_dir::String`: Directory path where the output file will be saved. If the directory
  does not exist, it will be created.
- `export_file::String`: Name of the output file (e.g., "bathycross.dat").
- `utmCoords::Bool`: (optional, default=false) If true, exports coordinates in UTM
  format (with zone number in header). Otherwise, exports geographic coordinates (latitude and longitude).

# Behavior
- Checks if `TRANSECTCROSS` data is available; errors if missing.
- Creates `export_dir` if it does not exist.
- Writes a header line appropriate for coordinate type.
- Writes one line per data point with the following columns:
  - ID (index)
  - Transect number 1 and ping number 1
  - Transect number 2 and ping number 2
  - Coordinates (UTM X and Y or Latitude and Longitude)
  - Depth difference (`ErrZ`) rounded to three decimal places
- Prints a success message upon completion.
- Catches and prints errors if file writing fails.
"""
function export_bathycross(
    TRANSECTCROSS::TransectCross,
    export_file::String;
    utmCoords::Bool = false,
    )

    # Check input validity
    if isnothing(TRANSECTCROSS)
        error("No BATHYMETRY data available")
    end


    try
        open(export_file, "w") do fout
            # Write headers
            if utmCoords
                println(fout, "#ID\tT_NUM1\tP_NUM1\tT_NUM2\tP_NUM2\tUTM-X($(TRANSECTCROSS.utmZN))\tUTM-Y\tErrZ")
            else
                println(fout, "#ID\tT_NUM1\tP_NUM1\tT_NUM2\tP_NUM2\tLAT\tLON\tErrZ")
            end

            npoints = length(TRANSECTCROSS.ddepth)
            for n in 1:npoints
                line = string(
                    n, '\t',
                    TRANSECTCROSS.transect1[n], '\t',
                    TRANSECTCROSS.nping1[n], '\t',
                    TRANSECTCROSS.transect2[n], '\t',
                    TRANSECTCROSS.nping2[n]
                )

                if utmCoords
                    x = round(TRANSECTCROSS.utmX1[n], digits=2)
                    y = round(TRANSECTCROSS.utmY1[n], digits=2)
                    line *= "\t$x\t$y"
                else
                    lat = round(TRANSECTCROSS.lat1[n], digits=6)
                    lon = round(TRANSECTCROSS.lon1[n], digits=6)
                    line *= "\t$lat\t$lon"
                end

                line *= "\t$(round(TRANSECTCROSS.ddepth[n], digits=3))"
                println(fout, line)
            end
        end
        println("File $(export_file) created!")
    catch e
        println("File $export_file could not be opened for writing: $(e)")
    end

end
