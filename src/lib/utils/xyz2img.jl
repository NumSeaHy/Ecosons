"""
Interpolates scattered 3D point data (X, Y, Z) onto a regular 2D grid to produce an image-like matrix.

# Arguments
- `X::Vector{<:Real}`: X-coordinates of input points.
- `Y::Vector{<:Real}`: Y-coordinates of input points.
- `Z::Vector{<:Real}`: Scalar values at (X, Y) locations (e.g., intensity or depth).
- `dxy::Real`: Grid resolution (spacing in X and Y).
- `method::AbstractString`: Interpolation method:
  - `"mean"`: Grid values are local averages of nearby Zs.
  - `"idw"`: Inverse Distance Weighted interpolation using power `pw`.
- `fr::Real`: Radius of influence in physical units (same as X/Y), determines filter radius.
- `pw=1.0`: (Optional) Power parameter for IDW interpolation.

# Returns
- `I::Matrix{Float64}`: Interpolated image matrix.
- `x_min::Float64`, `x_max::Float64`: X-coordinate extent of the image.
- `y_min::Float64`, `y_max::Float64`: Y-coordinate extent of the image.
- `dxy::Float64`: Grid resolution (same as input).

# Notes
- The output matrix `I` has origin at the bottom-left (Y increases upward).
- Values with no supporting data are set to `NaN`.
- The `fr` value controls the size of the smoothing kernel.
- Uses a helper `conv2` for 2D convolution (with zero-padding).

# Example
"""
function xyz2img(X::Vector{<:Real}, Y::Vector{<:Real},
     Z::Vector{<:Real}, dxy::Real, method::AbstractString, fr::Real; pw=1.0)
    x_min, x_max = minimum(X), maximum(X)
    y_min, y_max = minimum(Y), maximum(Y)

    h = 1 + floor(Int, (y_max - y_min) / dxy)
    y_min = max(y_min, y_max - h * dxy)
    w = 1 + floor(Int, (x_max - x_min) / dxy)
    x_max = min(x_max, x_min + w * dxy)

    i = 1 .+ floor.(Int, (y_max .- Y) ./ dxy)
    j = 1 .+ floor.(Int, (X .- x_min) ./ dxy)
    dd = round(Int, fr / dxy)
    di, dj = [k for k in -dd:dd], [k for k in -dd:dd]
    # Create 2D meshgrid arrays
    DI = repeat(di', length(dj), 1)
    DJ = repeat(dj, 1, length(di))

    if lowercase(method) == "mean"
        BZ = zeros(h, w)
        BZc = zeros(h, w)

        # Accumulate sums and counts for each grid cell
        for n in eachindex(X)
            in_ = i[n]
            jn = j[n]
            BZ[in_, jn] += Z[n]
            BZc[in_, jn] += 1
        end

        # Create kernel mask (circle of radius dd)
        avK = map((x,y) -> sqrt(x^2 + y^2) <= dd ? 1.0 : 0.0, DI, DJ)

        # Convolve sums and counts with kernel
        BZ = conv(avK, BZ)
        BZc = conv(avK, BZc)

        m = BZc .> 0
        BZ[m] ./= BZc[m]
        BZ[.!m] .= NaN

        I = BZ[(1+dd):(end-dd), (1+dd):(end-dd)]
        return I, x_min, x_max, y_min, y_max, dxy

    elseif lowercase(method) == "idw"
        BZ = zeros(h, w)
        BZc = zeros(h, w)

        r = map((x,y) -> sqrt(x^2 + y^2), DI, DJ)
        m = r .<= dd
        r[dd+1, dd+1] = 0.5  # avoid division by zero
        idw = r .^ (-pw) .- dd^(-pw)
        idw[.!m] .= 0

        for n in eachindex(X)
            in_ = i[n]
            jn = j[n]
            wZ = Z[n] * idw
            iaa = in_ - dd; ia = max(1, iaa)
            ibb = in_ + dd; ib = min(h, ibb)
            jaa = jn - dd; ja = max(1, jaa)
            jbb = jn + dd; jb = min(w, jbb)

            BZ[ia:ib, ja:jb] .+= wZ[(1 + ia - iaa):(end - (ibb - ib)), (1 + ja - jaa):(end - (jbb - jb))]
            BZc[ia:ib, ja:jb] .+= idw[(1 + ia - iaa):(end - (ibb - ib)), (1 + ja - jaa):(end - (jbb - jb))]
        end

        m = BZc .> 0
        BZ[m] ./= BZc[m]
        BZ[.!m] .= NaN
        I = BZ

        return I, x_min, x_max, y_min, y_max, dxy

    else
        error("Method must be either 'mean' or 'idw'")
    end
end
