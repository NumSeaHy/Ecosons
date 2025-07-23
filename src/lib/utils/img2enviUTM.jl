"""
Export a 2D or 3D image array to ENVI format with UTM georeferencing.

# Arguments
- `filename::String`: Base name (without extension) for the output ENVI files. The `.hdr` and binary file will be created with this name.
- `I::Array{<:Real}`: Input image array. Can be 2D (height × width) or 3D (bands × height × width).
- `gX_min::Float64`, `gX_max::Float64`: Minimum and maximum X (easting) coordinates in UTM.
- `gY_min::Float64`, `gY_max::Float64`: Minimum and maximum Y (northing) coordinates in UTM.
- `utmZ::Int`: UTM zone number.
- `Idesc::Vector{String}` (optional): Band names to include in the ENVI header.

# Notes
- The image is written in Band Sequential (`bsq`) format.
- The header includes `map info` for proper georeferencing in GIS software.
- Pixel values of `NaN` (for floating-point arrays) are preserved or replaced with a standard nodata value (e.g., 255 for `Bool`, `NaN32` for `Float32`).
- Coordinates are assumed to be in meters and referenced to WGS-84.

# Errors
Throws an error if the input array is not 2D or 3D, or if its element type is not supported (`Bool` or `AbstractFloat`).
"""
function img2enviUTM(filename::String, I::Array{<:Real}, 
                     gX_min::Float64, gX_max::Float64, 
                     gY_min::Float64, gY_max::Float64,
                     utmZ::Int, Idesc::Vector{String}=String[])

    # Convert 2D to 3D if needed
    if ndims(I) == 2
        I = reshape(I, 1, size(I)...)
    elseif ndims(I) != 3
        error("Input image must be 2D or 3D array")
    end

    nbands, height, width = size(I)

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

    dx = (gX_max - gX_min) / width
    dy = (gY_max - gY_min) / height

    utmH = gY_min > 0 ? "N" : "S"

    # Write .hdr file
    open(filename * ".hdr", "w") do f
        println(f, "ENVI")
        println(f, "description = {\n  Julia ENVI export }")
        println(f, "samples = $width")
        println(f, "lines = $height")
        println(f, "bands = $nbands")
        println(f, "header offset = 0")
        println(f, "file type = ENVI Standard")
        println(f, "data type = $dtype")
        println(f, "interleave = bsq")
        println(f, "sensor type = Unknown")
        println(f, "byte order = 0")
        println(f, "x start = 1")
        println(f, "y start = 1")
        println(f, "map info = {UTM, 1.0, 1.0, $(round(gX_min, digits=3)), $(round(gY_max, digits=3)), $(round(dx, digits=3)), $(round(dy, digits=3)), $utmZ, $utmH, WGS-84, units=Meters}")
        println(f, "wavelength units = Unknown")
        if !isempty(Idesc)
            println(f, "band names = {", join(Idesc, ", "), "}")
        end
    end
    println("File $(filename).hdr created!")

    # Write binary image file
    open(filename, "w") do f
        for b in 1:nbands
            band_data = I[b, :, :]             # No vertical flip
            band_data_clean = replace(band_data, NaN => nanval)
            write(f, reinterpret(stype, vec(transpose(band_data_clean))))
        end
    end
    println("Binary file created!")

end
