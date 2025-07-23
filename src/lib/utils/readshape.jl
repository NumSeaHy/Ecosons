# reading shapefile binary data
function readshape(fname::String)
    xyzs = Matrix{Float64}(undef, 0, 4)  # allow for up to 4D
    shns = Int[]

    open(fname, "r") do io
        mgk = reinterpret(UInt32, read(io, 4))[1]
        seek(io, position(io) + 5*4)
        fsz = 2 * reinterpret(UInt32, read(io, 4))[1]
        vsn = reinterpret(UInt32, read(io, 4))[1]
        shp = reinterpret(UInt32, read(io, 4))[1]

        xmin = reinterpret(Float64, read(io, 8))[1]
        xmax = reinterpret(Float64, read(io, 8))[1]
        ymin = reinterpret(Float64, read(io, 8))[1]
        ymax = reinterpret(Float64, read(io, 8))[1]
        seek(io, position(io) + 4*8)

        while position(io) < fsz
            shn = reinterpret(UInt32, read(io, 4))[1]
            lgt = reinterpret(UInt32, read(io, 4))[1]
            sty = reinterpret(UInt32, read(io, 4))[1]
            xyz = Float64[]

            if sty == 0  # Null
                xyz = [0.0 0.0 0.0]
            elseif sty == 1  # Point
                xyz = reshape(reinterpret(Float64, read(io, 16)), 1, :)
            elseif sty in (3, 5)  # PolyLine / Polygon
                read(io, 8*4)
                ne = reinterpret(UInt32, read(io, 4))[1]
                np = reinterpret(UInt32, read(io, 4))[1]
                i0s = reinterpret(UInt32, read(io, 4 * ne))
                xy = reshape(reinterpret(Float64, read(io, 8 * np)), 2, np)'
                xyz = insert_nans(xy, i0s)
            elseif sty == 8  # MultiPoint
                read(io, 8*4)
                np = reinterpret(UInt32, read(io, 4))[1]
                xyz = reshape(reinterpret(Float64, read(io, 8 * np)), 2, np)'
            elseif sty == 11  # PointZ
                xyz = reshape(reinterpret(Float64, read(io, 32)), 1, :)
            elseif sty in (13, 15)  # PolyLineZ / PolygonZ
                read(io, 8*4)
                ne = reinterpret(UInt32, read(io, 4))[1]
                np = reinterpret(UInt32, read(io, 4))[1]
                i0s = reinterpret(UInt32, read(io, 4 * ne))
                xy = reshape(reinterpret(Float64, read(io, 8 * np)), 2, np)'
                bz = reinterpret(Float64, read(io, 8 * 2))
                z = reinterpret(Float64, read(io, 8 * np))
                xyz = hcat(xy, z)
                rem = 2*lgt - 4 - 4*(2*4+1+1+ne+2*2*np+2*2+np)
                if rem > 0
                    bm = reinterpret(Float64, read(io, 8 * 2))
                    m = reinterpret(Float64, read(io, 8 * np))
                    xyz = hcat(xyz, m)
                end
                xyz = insert_nans(xyz, i0s)
            elseif sty == 18  # MultiPointZ
                read(io, 8*4)
                np = reinterpret(UInt32, read(io, 4))[1]
                xy = reshape(reinterpret(Float64, read(io, 8 * np)), 2, np)'
                bz = reinterpret(Float64, read(io, 8 * 2))
                z = reinterpret(Float64, read(io, 8 * np))
                xyz = hcat(xy, z)
                rem = 2*lgt - 4 - 4*(2*4+1+2*2*np+2*2+np)
                if rem > 0
                    bm = reinterpret(Float64, read(io, 8 * 2))
                    m = reinterpret(Float64, read(io, 8 * np))
                    xyz = hcat(xyz, m)
                end
            elseif sty in (21, 25)  # PolyLineM / PolygonM
                read(io, 8*4)
                ne = reinterpret(UInt32, read(io, 4))[1]
                np = reinterpret(UInt32, read(io, 4))[1]
                i0s = reinterpret(UInt32, read(io, 4 * ne))
                xy = reshape(reinterpret(Float64, read(io, 8 * np)), 2, np)'
                bm = reinterpret(Float64, read(io, 8 * 2))
                m = reinterpret(Float64, read(io, 8 * np))
                xyz = hcat(xy, m)
                xyz = insert_nans(xyz, i0s)
            else
                @warn "Unsupported shape type $sty, skipping $lgt words"
                seek(io, position(io) + 4 * (2 * lgt - 4))
                continue
            end

            # Expand xyz to 4 columns if needed
            if size(xyz, 2) < 4
                xyz = hcat(xyz, fill(NaN, size(xyz, 1), 4 - size(xyz, 2)))
            end

            xyzs = vcat(xyzs, xyz)
            append!(shns, fill(Int(shn), size(xyz, 1)))
        end
    end

    return xyzs, shns
end

function insert_nans(xyz::Matrix{Float64}, i0s::Vector{UInt32})
    xyz_out = copy(xyz)
    offset = 0
    for idx in i0s[2:end]
        i = Int(idx) + offset
        xyz_out = vcat(xyz_out[1:i-1, :], fill(NaN, 1, size(xyz, 2)), xyz_out[i:end, :])
        offset += 1
    end
    return xyz_out
end
