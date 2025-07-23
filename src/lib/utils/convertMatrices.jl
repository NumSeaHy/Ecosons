"""
Writes a PNM (PGM or PPM) header to an I/O stream.

# Arguments
- `io`: Output stream to write the header.
- `magic::String`: Magic number (e.g., `"P5"` for PGM or `"P6"` for PPM).
- `width::Int`: Image width (number of columns).
- `height::Int`: Image height (number of rows).
- `maxGray::Int`: Maximum grayscale value (typically 255).
- `min_v`: Minimum data value mapped to intensity 1.
- `max_v`: Maximum data value mapped to intensity `maxGray`.

# Notes
Includes a comment line that shows the mapping of min/max values and notes that NaNs are set to 0.
"""
function write_pnm_header(io, magic::String, width::Int, height::Int, maxGray::Int, min_v, max_v)
    println(io, magic)
    println(io, "#min_v=$min_v -> 1, max_v=$maxGray, NaN set to 0")
    println(io, "$width $height")
    println(io, "$maxGray")
end


"""
Scales and encodes a matrix of real values into an 8-bit grayscale format.

# Arguments
- `M::AbstractMatrix`: Input matrix of real values.
- `min_v`: Minimum value to map to intensity 1.
- `max_v`: Maximum value to map to `maxGray`.
- `maxGray::Int`: Maximum grayscale value (e.g., 255).

# Returns
- `Matrix{UInt8}`: Scaled and transposed matrix encoded to grayscale values.
  - NaN values are set to 0.
"""
function scale_and_encode(M::AbstractMatrix, min_v, max_v, maxGray::Int)
    M = clamp.(M, min_v, max_v)
    M = permutedims(M)
    mnan = isnan.(M)
    scaled = floor.(UInt8, 1 .+ (maxGray - 1) .* (M .- min_v) ./ (max_v - min_v))
    scaled[mnan] .= 0
    return scaled
end

"""
Generates a custom RGB colormap of length `maxGray`.

# Arguments
- `maxGray::Int`: Maximum color value (typically 255).

# Returns
- `(cmR, cmG, cmB)`: Tuple of RGB component vectors. Each vector is of length `maxGray + 1`.

# Notes
This color scheme is designed for use with false-color images (e.g., visualizing scalar fields).
"""
function generate_colormap(maxGray::Int)
    mg4 = fld(maxGray, 4)
    mg2 = fld(maxGray, 2)

    cmR = clamp.(vcat(0, zeros(Int, mg2), 2 .* (1:(maxGray - mg2))), 0, maxGray)
    cmG = clamp.(vcat(0,
                      zeros(Int, mg4),
                      4 .* (1:mg4),
                      4 .* ((maxGray - 3 * mg4):-1:1),
                      zeros(Int, mg4)), 0, maxGray)
    cmB = clamp.(vcat(0, 2 .* (mg2:-1:1), zeros(Int, maxGray - mg2)), 0, maxGray)

    return cmR, cmG, cmB
end

"""
Writes a 2D matrix to a grayscale PGM image file.

# Arguments
- `M::AbstractMatrix`: Input matrix of real values.
- `imgF::String`: Output file path.
- `min_v`: Minimum value for scaling.
- `max_v`: Maximum value for scaling.

# Notes
- Values are scaled between 1 and 255.
- NaN values are mapped to 0 (black).
- Image is transposed before writing to match conventional image orientation.
"""
function matrix2PGM(M::AbstractMatrix, imgF::String, min_v, max_v)
    maxGray = 255
    data = scale_and_encode(M, min_v, max_v, maxGray)

    open(imgF, "w") do f
        write_pnm_header(f, "P5", size(M, 2), size(M, 1), maxGray, min_v, max_v)
        write(f, data)
    end
end

"""
Writes three matrices (R, G, B channels) to a binary color PPM image.

# Arguments
- `Mr`, `Mg`, `Mb`: Red, Green, and Blue channel matrices.
- `imgF::String`: Output file path.
- `min_v`: Minimum value for scaling.
- `max_v`: Maximum value for scaling.

# Notes
- Each matrix is independently scaled to 8-bit format.
- NaN values are encoded as black.
"""
function matrix2PPM_RGB(Mr::AbstractMatrix, Mg::AbstractMatrix, Mb::AbstractMatrix, imgF::String, min_v, max_v)
    maxGray = 255
    R = vec(scale_and_encode(Mr, min_v, max_v, maxGray))
    G = vec(scale_and_encode(Mg, min_v, max_v, maxGray))
    B = vec(scale_and_encode(Mb, min_v, max_v, maxGray))

    pnmArray = Vector{UInt8}(undef, 3 * length(R))
    pnmArray[1:3:end] .= R
    pnmArray[2:3:end] .= G
    pnmArray[3:3:end] .= B

    open(imgF, "w") do f
        write_pnm_header(f, "P6", size(Mr, 2), size(Mr, 1), maxGray, min_v, max_v)
        write(f, pnmArray)
    end
end

"""
Writes a 2D matrix to a false-color RGB PPM image using a custom colormap.

# Arguments
- `M::AbstractMatrix`: Input matrix of real values.
- `imgF::String`: Output PPM file path.
- `min_v::Real`: Minimum value for color mapping.
- `max_v::Real`: Maximum value for color mapping.

# Notes
- Uses `generate_colormap()` to create a custom RGB mapping.
- NaN values are set to black.
- Matrix is transposed for conventional image orientation.
"""
function matrix2PPM(M::AbstractMatrix, imgF::AbstractString, min_v::Real, max_v::Real)
    maxGray = 255
    cmR, cmG, cmB = generate_colormap(maxGray)

    M = clamp.(M, min_v, max_v)
    M = permutedims(M)
    scale = (maxGray - 1) / (max_v - min_v)
    idxs = floor.(Int, 1 .+ scale .* (M .- min_v))
    mnan = isnan.(M)
    idxs[mnan] .= 1

    R = cmR[idxs]
    G = cmG[idxs]
    B = cmB[idxs]

    R[mnan] .= 0
    G[mnan] .= 0
    B[mnan] .= 0

    # Interleave RGB
    data = reshape(vcat(R[:], G[:], B[:]), :, 3)
    interleaved = vec(reinterpret(UInt8, permutedims(data)))

    open(imgF, "w") do io
        write_pnm_header(io, "P6", size(M, 2), size(M, 1), maxGray, min_v, max_v)
        write(io, interleaved)
    end
end
