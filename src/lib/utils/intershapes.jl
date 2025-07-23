"""
Interpolates a set of 2D or 3D line segments into evenly spaced points.

# Arguments
- `xyzs`: An `NxD` matrix of coordinates, where each row represents a point in 2D or 3D space (typically `D = 2` or `3`).
- `shns`: A vector of shape/group identifiers (`N` elements), grouping the rows of `xyzs` into distinct shapes.
- `dl`: Desired spacing between interpolated points.

# Returns
- A matrix of interpolated points (`MxD`), where `M ≥ N`. All input shapes are processed independently, and points are interpolated along each segment at approximately uniform spacing `dl`.

# Notes
- Segments within a shape are interpolated linearly.
- NaNs in `xyzs` are treated as breakpoints and skipped.
- The first point of each shape is always preserved.
"""
function intershapes(xyzs::Array{<:Real,2}, shns::AbstractVector{<:Integer}, dl::Real):: Matrix{Float64}
    np = 0
    xyzp = zeros(Float64, 0, size(xyzs, 2))  # output points, start empty

    for s in unique(shns)
        xyz = xyzs[shns .== s, :]
        xya = xyz[1, :]
        np += 1
        xyzp = vcat(xyzp, reshape(xya, 1, :))
        n = 2
        while n <= size(xyz, 1)
            if isnan(xyz[n, 1])
                if n + 1 <= size(xyz, 1)
                    xya = xyz[n + 1, :]
                    n += 1
                end
                n += 1
                continue
            end
            dxy = xyz[n, 1:2] - xya[1:2]
            mm = round(Int, norm(dxy) / dl)
            for m in 1:mm
                np += 1
                point = (xyz[n, :] * m + xya * (mm - m)) / mm
                xyzp = vcat(xyzp, reshape(point, 1, :))
            end
            xya = xyz[n, :]
            n += 1
        end
    end

    return xyzp
end 