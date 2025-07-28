using CairoMakie

"""
Plot classified points on a 2D or 3D scatter plot using CairoMakie, with automatic coloring
and marker assignment for different classes.
"""
function clsplot(cCLASS::AbstractVector{<:Integer}, cCs::AbstractVector{<:Integer},
                 X::AbstractVector, Y::AbstractVector; ax=nothing, Z=nothing, charP=nothing)

    # Default marker shapes
    default_markers = [:circle, :cross, :x, :star5, :triangle, :utriangle]
    plPt = charP === nothing ? default_markers : [Symbol(charP)]

    # 3D mode if Z is provided and non-empty
    set3D = Z !== nothing && !isempty(Z)

    # Create figure and axis if not provided
    fig = nothing
    if ax === nothing
        fig = Figure()
        ax = set3D ? Axis3(fig[1, 1]) : Axis(fig[1, 1])
    end

    # Auto-detect unique classes if cCs not provided
    if isempty(cCs)
        cCs = unique(filter(>(0), cCLASS))
    end

    # Background: all valid pings in light gray
    inds_all = findall(cCLASS .> 0)
    if set3D
        scatter!(ax, X[inds_all], Y[inds_all], Z[inds_all];
                 markersize = 4, color = (:gray, 0.3), marker = :circle)
    else
        scatter!(ax, X[inds_all], Y[inds_all];
                 markersize = 4, color = (:gray, 0.3), marker = :circle)
    end

    # Class-based coloring and shapes
    class_colors = try
        Makie.wong_colors()
    catch
        distinguishable_colors(length(cCs))
    end

    max_markers = length(default_markers) * length(plPt)
    nc = 0

    for (i, c) in enumerate(cCs)
        nc += 1
        if nc > max_markers
            break
        end

        pt_index = clamp(1 + fld(nc - 1, 6), 1, length(plPt))
        marker_shape = plPt[pt_index]
        color_index = mod1(nc, length(class_colors))
        class_color = class_colors[color_index]

        inds = findall(==(c), cCLASS)
        if isempty(inds)
            continue
        end

        if set3D
            scatter!(ax, X[inds], Y[inds], Z[inds];
                     markersize = 10, marker = marker_shape, color = class_color,
                     strokecolor = :black, strokewidth = 0.5)
        else
            scatter!(ax, X[inds], Y[inds];
                     markersize = 10, marker = marker_shape, color = class_color,
                     strokecolor = :black, strokewidth = 0.5)
        end
    end

    if !set3D
        xmin, xmax = extrema(X)
        ymin, ymax = extrema(Y)
        xpad = (xmax - xmin) * 0.05
        ypad = (ymax - ymin) * 0.05
        limits!(ax, xmin, xmax, ymin, ymax)
    end
    
    if fig !== nothing
        display(fig)
    end
    
    #limits!(ax, minimum(X), maximum(X), minimum(Y), maximum(Y))

    return ax
end
