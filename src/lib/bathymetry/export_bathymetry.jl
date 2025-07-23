"""
Export bathymetry data to a tab-delimited ASCII text file.

# Arguments
- `ntr::Vector{Int}`: Transect or ping number identifiers.
- `utmCoords::Bool`: If `true`, assumes coordinates are UTM (easting, northing); otherwise, assumes geographic (latitude, longitude).
- `xCoord::Vector{Float64}`: X coordinates (either UTM-X or longitude).
- `yCoord::Vector{Float64}`: Y coordinates (either UTM-Y or latitude).
- `znCoord::Float64`: UTM zone number (used in header only).
- `depth::Vector{Float64}`: Depth values (in meters).
- `bTime::Vector{Float64}`: Timestamp values (e.g., Julian or UNIX time).
- `export_file::String`: Path to the output file to write.
- `n_step::Int = 1`: Subsampling interval. For example, `n_step=2` writes every second data point.
- `e_time::Bool = true`: Whether to include time information in the export.

# Output
- A tab-delimited ASCII file at `export_file` location. Columns include:
    - `ID`: Sequential index of the exported point.
    - `T_NUM`: Transect number.
    - `TIME`: Timestamp (if `e_time == true`).
    - Coordinates: `UTM-X` and `UTM-Y` or `LAT` and `LON`.
    - `depth`: Depth in meters.
"""
function export_bathymetry(
    ntr::Vector{Int}, 
    utmCoords::Bool, 
    xCoord::Vector{Float64}, 
    yCoord::Vector{Float64}, 
    znCoord::Float64, 
    depth::Vector{Float64}, 
    bTime::Vector{Float64},
    export_file::String;
    n_step::Int = 1, 
    e_time::Bool = true
    )    

    # If no input data provided, return message
    if isempty(ntr)
        return error("No bathymetry data available")
    end

    # Try to open the output file for writing, catch any errors if it fails
    fout = try
        println("Opening file $(export_file)...")
        open(export_file, "w")
    catch e
        err = 2
        println("File $export_file could not be opened for writing")
        return err
    end

    # Write header line depending on coordinate type and whether time is exported
    if utmCoords
        if e_time
            println(fout, "#ID\tT_NUM\tTIME\tUTM-X($(znCoord))\tUTM-Y\tdepth")
        else
            println(fout, "#ID\tT_NUM\tUTM-X($(znCoord))\tUTM-Y\tdepth")
        end
    else
        if e_time
            println(fout, "#ID\tT_NUM\tTIME\tLAT\tLON\tdepth")
        else
            println(fout, "#ID\tT_NUM\tLAT\tLON\tdepth")
        end
    end

    # Loop through data points with subsampling (step n_step)
    for n in 1:n_step:length(ntr)
        print(fout, n, '\t', ntr[n])
        if e_time
            print(fout, '\t', bTime[n])
        end
        if utmCoords
            print(fout, '\t', xCoord[n], '\t', yCoord[n])
        else
            print(fout, '\t', yCoord[n], '\t', xCoord[n])
        end
        println(fout, '\t', depth[n])
    end
    close(fout)
    println("File $(export_file) created!")
end
