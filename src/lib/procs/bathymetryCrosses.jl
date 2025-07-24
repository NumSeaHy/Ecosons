using LinearAlgebra

struct Segment
    transect::Int
    start_idx::Int
    bbox::Tuple{Float64, Float64, Float64, Float64}  # (xmin, xmax, ymin, ymax)
end

function create_segments(baths, dp)
    segments = Segment[]
    for (dsn, bath) in enumerate(baths)
        lat = bath.latitude
        lon = bath.longitude
        for n in 1:dp:(length(lat) - dp)
            xmin = min(lat[n], lat[n+dp])
            xmax = max(lat[n], lat[n+dp])
            ymin = min(lon[n], lon[n+dp])
            ymax = max(lon[n], lon[n+dp])
            push!(segments, Segment(dsn, n, (xmin, xmax, ymin, ymax)))
        end
    end
    return segments
end

function build_grid_index(segments, cell_size)
    # Compute global bounding box of all segments
    all_xmin = minimum([s.bbox[1] for s in segments])
    all_xmax = maximum([s.bbox[2] for s in segments])
    all_ymin = minimum([s.bbox[3] for s in segments])
    all_ymax = maximum([s.bbox[4] for s in segments])

    x_cells = ceil(Int, (all_xmax - all_xmin) / cell_size)
    y_cells = ceil(Int, (all_ymax - all_ymin) / cell_size)

    grid = Dict{Tuple{Int,Int}, Vector{Int}}()

    cell_coords(x, y) = (
        clamp(floor(Int, (x - all_xmin) / cell_size) + 1, 1, x_cells),
        clamp(floor(Int, (y - all_ymin) / cell_size) + 1, 1, y_cells),
    )

    for (i, seg) in enumerate(segments)
        (xmin_s, xmax_s, ymin_s, ymax_s) = seg.bbox
        (x1, y1) = cell_coords(xmin_s, ymin_s)
        (x2, y2) = cell_coords(xmax_s, ymax_s)

        for cx in x1:x2, cy in y1:y2
            if !haskey(grid, (cx, cy))
                grid[(cx, cy)] = Int[]
            end
            push!(grid[(cx, cy)], i)
        end
    end

    return grid, all_xmin, all_ymin, cell_size, x_cells, y_cells
end

function query_grid(grid, xmin, ymin, cell_size, x_cells, y_cells, bbox)
    (xmin_q, xmax_q, ymin_q, ymax_q) = bbox
    cell_coords(x, y) = (
        clamp(floor(Int, (x - xmin) / cell_size) + 1, 1, x_cells),
        clamp(floor(Int, (y - ymin) / cell_size) + 1, 1, y_cells)
    )
    (x1, y1) = cell_coords(xmin_q, ymin_q)
    (x2, y2) = cell_coords(xmax_q, ymax_q)

    candidates = Int[]
    for cx in x1:x2, cy in y1:y2
        if haskey(grid, (cx, cy))
            append!(candidates, grid[(cx, cy)])
        end
    end

    return unique(candidates)
end

"""
Detects and returns intersection points between bathymetric transects by identifying where line segments cross in 2D space.

This function processes a set of bathymetry transects, subdivides each into segments of length `dp` pings, and identifies
spatial crossings between segments from different transects. A uniform spatial grid is used to speed up candidate selection
for intersection testing.

# Arguments
- `baths::Vector{Bathymetry}`: A vector of `Bathymetry` structs, each containing at least fields:
    - `latitude::Vector{Float64}`
    - `longitude::Vector{Float64}`
    - `depth::Vector{Float64}`

- `dp::Int`: Number of pings to skip between start and end of a segment. 
Each transect is broken into line segments of this step size.

- `cell_size::Float64=0.01`: Size of spatial grid cells in degrees (longitude/latitude). Affects speed of
 intersection search; smaller values may increase accuracy but reduce performance.

# Returns
- `TRANSECTCROSS::TransectCross`: A struct containing all detected intersection points between transects:
    - `lon1`, `lat1`: Intersection points interpolated along first segment.
    - `lon2`, `lat2`: Intersection points interpolated along second segment.
    - `transect1`, `transect2`: Transect indices for each crossing.
    - `nping1`, `nping2`: Ping indices along the respective transects.
    - `ddepth`: Depth difference between intersecting segments at the crossing point.

# Details
- Each transect is broken into line segments of length `dp`, and bounding boxes are computed.
- A uniform grid is constructed and segments are indexed to cells they span.
- For each segment, only candidate segments from other transects within overlapping grid cells are tested for intersection.
- A simple dot-product-based test is used to detect 2D intersection.
- The function allocates arrays dynamically and doubles their size when needed to store results.

# Performance Notes
- Can be made faster by threading the outer loop over segments. You can replace the segment loop with 
`Threads.@threads` if desired.
- Currently optimized for moderate transect counts and segment densities. For very large datasets, 
consider tuning `cell_size` or  using spatial indexing libraries.
"""
function bathymetryCrosses(baths::Vector{Bathymetry}, dp::Int64; cell_size=0.01)
    segments = create_segments(baths, dp)
    grid, xmin, ymin, cell_size, x_cells, y_cells = build_grid_index(segments, cell_size)

    max_crossings = 10_000  # adjust as needed, will resize if needed
    Ccount = 0
    C1lat = Vector{Float64}(undef, max_crossings)
    C1lon = Vector{Float64}(undef, max_crossings)
    C2lat = Vector{Float64}(undef, max_crossings)
    C2lon = Vector{Float64}(undef, max_crossings)
    C1ntrsc = Vector{Int}(undef, max_crossings)
    C2ntrsc = Vector{Int}(undef, max_crossings)
    C1nping = Vector{Int}(undef, max_crossings)
    C2nping = Vector{Int}(undef, max_crossings)
    C12dz = Vector{Float64}(undef, max_crossings)

    for (i, seg1) in enumerate(segments)
        dsn = seg1.transect
        n = seg1.start_idx
        bath1 = baths[dsn]
        lat1 = bath1.latitude
        lon1 = bath1.longitude
        depth1 = bath1.depth

        # Segment 1 endpoints
        p1_lat = lat1[n]
        p1_lon = lon1[n]
        p2_lat = lat1[n+dp]
        p2_lon = lon1[n+dp]

        # Projected points for dot products
        p1p_x = p1_lon
        p1p_y = -p1_lat
        p2p_x = p2_lon
        p2p_y = -p2_lat

        p_diff_lat = p2_lat - p1_lat
        p_diff_lon = p2_lon - p1_lon
        p_diff_p_x = p2p_x - p1p_x
        p_diff_p_y = p2p_y - p1p_y

        candidate_indices = query_grid(grid, xmin, ymin, cell_size, x_cells, y_cells, seg1.bbox)

        for j in candidate_indices
            if j <= i
                continue
            end

            seg2 = segments[j]
            dsm = seg2.transect
            m = seg2.start_idx
            if dsm <= dsn
                continue
            end

            bath2 = baths[dsm]
            lat2 = bath2.latitude
            lon2 = bath2.longitude
            depth2 = bath2.depth

            q1_lat = lat2[m]
            q1_lon = lon2[m]
            q2_lat = lat2[m+dp]
            q2_lon = lon2[m+dp]

            q1p_x = q1_lon
            q1p_y = -q1_lat
            q2p_x = q2_lon
            q2p_y = -q2_lat

            q_diff_lat = q2_lat - q1_lat
            q_diff_lon = q2_lon - q1_lon
            q_diff_p_x = q2p_x - q1p_x
            q_diff_p_y = q2p_y - q1p_y

            # Manual dot products
            rb = p_diff_lat * q_diff_p_x + p_diff_lon * q_diff_p_y
            sb = q_diff_lat * p_diff_p_x + q_diff_lon * p_diff_p_y

            if rb != 0 && sb != 0
                ra = (q1_lat - p1_lat) * q_diff_p_x + (q1_lon - p1_lon) * q_diff_p_y
                sa = (p1_lat - q1_lat) * p_diff_p_x + (p1_lon - q1_lon) * p_diff_p_y

                r = ra / rb
                s = sa / sb

                if 0 < r < 1 && 0 < s < 1
                    Ccount += 1
                    if Ccount > length(C1lat)
                        newsize = length(C1lat) * 2
                        resize!(C1lat, newsize)
                        resize!(C1lon, newsize)
                        resize!(C2lat, newsize)
                        resize!(C2lon, newsize)
                        resize!(C1ntrsc, newsize)
                        resize!(C2ntrsc, newsize)
                        resize!(C1nping, newsize)
                        resize!(C2nping, newsize)
                        resize!(C12dz, newsize)
                    end

                    C1lat[Ccount] = (1 - r) * p1_lat + r * p2_lat
                    C1lon[Ccount] = (1 - r) * p1_lon + r * p2_lon
                    C2lat[Ccount] = (1 - s) * q1_lat + s * q2_lat
                    C2lon[Ccount] = (1 - s) * q1_lon + s * q2_lon
                    C1ntrsc[Ccount] = dsn
                    C2ntrsc[Ccount] = dsm
                    C1nping[Ccount] = n
                    C2nping[Ccount] = m

                    dz1 = (1 - r) * depth1[n] + r * depth1[n+dp]
                    dz2 = (1 - s) * depth2[m] + s * depth2[m+dp]
                    C12dz[Ccount] = dz1 - dz2
                end
            end
        end
    end

    resize!(C1lat, Ccount)
    resize!(C1lon, Ccount)
    resize!(C2lat, Ccount)
    resize!(C2lon, Ccount)
    resize!(C1ntrsc, Ccount)
    resize!(C2ntrsc, Ccount)
    resize!(C1nping, Ccount)
    resize!(C2nping, Ccount)
    resize!(C12dz, Ccount)

    TRANSECTCROSS = TransectCross()

    if Ccount > 0
        TRANSECTCROSS.lon1 = C1lon
        TRANSECTCROSS.lat1 = C1lat
        TRANSECTCROSS.lon2 = C2lon
        TRANSECTCROSS.lat2 = C2lat
        TRANSECTCROSS.transect1 = C1ntrsc
        TRANSECTCROSS.transect2 = C2ntrsc
        TRANSECTCROSS.nping1 = C1nping
        TRANSECTCROSS.nping2 = C2nping
        TRANSECTCROSS.ddepth = C12dz
    end

    return TRANSECTCROSS
end
