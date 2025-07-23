"""
Export a 2D or 3D image array to ENVI raster format with approximate UTM georeferencing inferred from latitude and longitude bounds.

# Arguments
- `filename::String`: Base output file name (without extension). Produces a `.hdr` metadata file and binary raster file.
- `I::Array{<:Real}`: Input image array (2D or 3D). A 2D array is treated as a single-band image.
- `lat_min::Float64`, `lat_max::Float64`: Latitude bounds of the image (degrees).
- `lon_min::Float64`, `lon_max::Float64`: Longitude bounds of the image (degrees).
- `Idesc::Vector{String}` (optional): Names of image bands for inclusion in the ENVI header.

# Behavior
- Converts input lat/lon bounds to UTM coordinates using `latlon2utm.jl`.
- Calculates pixel resolution (`dx`, `dy`) based on geospatial extent.
- Vertically flips each band to match ENVI's row ordering.
- Supports `Bool` and `Float32` types. NaN values are replaced with `NaN32` or 255 depending on type.

# Errors
- Throws an error if the input array is not 2D or 3D, or if its element type is unsupported.
"""
function img2envi(filename::String, I::Array{<:Real}, 
                  lat_min::Float64, lat_max::Float64, 
                  lon_min::Float64, lon_max::Float64, 
                  Idesc::Vector{String}=String[])

    # If 2D input, wrap it into a 3D array with one band
    if ndims(I) == 2
        I = reshape(I, 1, size(I)...)
    elseif ndims(I) != 3
        error("Input image must be 2D or 3D array")
    end

    bands, height, width = size(I)

    # Determine ENVI data type code
    if eltype(I) <: Bool
        dtype = 1
        stype = UInt8
        nanval = UInt8(255)
    elseif eltype(I) <: AbstractFloat
        dtype = 4
        stype = Float32
        nanval = NaN32
    else
        error("Unsupported image data type: $(eltype(I))")
    end

    # Compute UTM bounding box
    utmX1, _, utmZ, utmH = latlon2utm(lat_min, lon_min)
    utmX2, utmY2, _, _  = latlon2utm(lat_max, lon_max)

    dx = (utmX2 - utmX1) / width
    dy = (utmY2 - utmY2) / height  # Double-check lat_max != lat_min

    utmX = utmX1
    utmY = utmY2

    # Write .hdr
    open(filename * ".hdr", "w") do f
        println(f, "ENVI")
        println(f, "description = {\n  Julia ENVI export }")
        println(f, "samples = $width")
        println(f, "lines = $height")
        println(f, "bands = $bands")
        println(f, "header offset = 0")
        println(f, "file type = ENVI Standard")
        println(f, "data type = $dtype")
        println(f, "interleave = bsq")
        println(f, "sensor type = Unknown")
        println(f, "byte order = 0")
        println(f, "x start = 1")
        println(f, "y start = 1")
        println(f, "map info = {UTM, 1.0, 1.0, $(round(utmX, digits=3)), $(round(utmY, digits=3)), $(round(dx, digits=3)), $(round(dy, digits=3)), $utmZ, $utmH, WGS-84, units=Meters}")
        println(f, "wavelength units = Unknown")
        if !isempty(Idesc)
            println(f, "band names = {", join(Idesc, ", "), "}")
        end
    end
    println("File $(filename).hdr created!")

    # Write binary image file
    open(filename, "w") do f
        for b in 1:bands
            band_data = reverse(I[b, :, :], dims=1)  # flip vertically
            band_data_clean = replace(band_data, NaN => nanval)
            write(f, reinterpret(stype, vec(transpose(band_data_clean))))
        end
    end
    println("Binary file created!")

end
