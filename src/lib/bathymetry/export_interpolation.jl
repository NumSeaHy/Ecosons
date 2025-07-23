include("../utils/img2enviUTM.jl")
include("../utils/img2envi.jl")
include("../utils/img2esriascii.jl")
"""
Exports a 2D bathymetric interpolation matrix `Is` to a geospatial raster format 
(either ENVI or ESRI ASCII) with appropriate spatial referencing.

# Arguments
- `Is`: 2D matrix of interpolated bathymetric values (e.g., depths).
- `utmCoords`: If `true`, coordinates are interpreted as UTM; otherwise, geographic (lon/lat).
- `gX_min`, `gX_max`: Minimum and maximum X-coordinate bounds (longitude or UTM-X).
- `gY_min`, `gY_max`: Minimum and maximum Y-coordinate bounds (latitude or UTM-Y).
- `znCoord`: UTM zone number (required when `utmCoords == true`). Pass `nothing` if not applicable.
- `export_dir`: Directory path where output file will be saved. Created if it doesn't exist.
- `export_file`: File name (without extension) to save the exported raster under.
- `sel`: Raster format selection:
    - `1`: ENVI format (default)
    - `2`: ESRI ASCII format
    - `3`: Not implemented (function will exit with warning)

# Behavior
- If the specified output directory doesn't exist, it will be created.
- Depending on `sel`, this function exports:
    - ENVI raster via `img2enviUTM()` or `img2envi()` depending on `utmCoords`.
    - ArcMap ESRI ASCII `.grd` format via `img2esriascii()`.
- Output file will be saved under `export_dir/export_file`.

# Notes
- If `sel == 3`, the function exits early and returns an error code.
"""
function export_interpolation(
    Is::AbstractMatrix{<:Real},    
    utmCoords::Bool,              
    gX_min::Real,                
    gX_max::Real,                 
    gY_min::Real,                 
    gY_max::Real,                
    znCoord::Union{Int,Nothing},
    export_dir::String,
    export_file::String;  
    sel::Int = 1,                    
    )
    if !isdir(export_dir)
        println("Directory $export_dir does not exist, creating it...")
        mkpath(export_dir)
        println("$(export_file) generated")
    end

    file = joinpath(export_dir, export_file )


    println("Export format:")

    if sel == 3
        err = -1
        return err, err_desc
    end

    if sel == 1
        println("ENVI format")
        # ENVI format
        println("Output ENVI base file name: $(export_file)")

        if utmCoords
            img2enviUTM(file, Is, gX_min, gX_max, gY_min, gY_max, znCoord, ["Bathymetry"])
            
        else
            # lon: X, lat: Y
            img2envi(file, Is, gY_min, gY_max, gX_min, gX_max, ["Bathymetry"])
        end

    elseif sel == 2
        println("ArcMap ESRI ASCII format")
        # ArcMap ESRI ASCII format
        println("Output ESRI-ASCII file name: $(export_file).grd")
        img2esriascii(file, Is, gX_min, gX_max, gY_min, gY_max)
    end

end
