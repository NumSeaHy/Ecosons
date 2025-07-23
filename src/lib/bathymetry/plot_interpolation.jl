"""
Visualizes a 2D bathymetric interpolation matrix using different types of plots.

# Arguments
- `Is`: 2D matrix of interpolated bathymetric values (e.g., depths), indexed as `[y, x]`.
- `utmCoords`: `true` if spatial coordinates are in UTM, `false` if in geographic (longitude/latitude).
- `gX_min`, `gX_max`: Minimum and maximum X coordinates (longitude or UTM-X).
- `gY_min`, `gY_max`: Minimum and maximum Y coordinates (latitude or UTM-Y).
- `znCoord`: UTM zone number if using UTM coordinates; can be `nothing` if `utmCoords == false`.
- `sel`: (Optional) Selector for the type of plot to generate:
    - `1`: Colored 2D heatmap
    - `2`: 3D surface plot
    - `3`: Contour map
    - `4`: Quit (throws an error)
- `bathLinesDepth`: (Optional) Comma-separated string of contour depths (e.g., `"5,10,15"`). Only used when `sel == 3`.

# Behavior
- Generates appropriate grid axes based on input extents and array dimensions.
- Axis labels and units are adjusted according to the coordinate system (`utmCoords`).
- If `sel == 3`, contour levels are parsed from `bathLinesDepth` or generated automatically in 5m steps.
- Throws an error for invalid selections or if the matrix contains only NaNs.

# Errors
- Throws `error("Quit selected...")` if `sel == 4`.
- Throws `error("Invalid selection...")` for `sel < 1 || sel > 4`.
- Throws `error("Interpolated depth data contains only NaNs.")` if contour plot is selected and `Is` has no valid data.
"""
function plot_interpolation(
    Is::AbstractMatrix{<:Real},
    utmCoords::Bool,
    gX_min::Real,
    gX_max::Real,
    gY_min::Real,
    gY_max::Real,
    znCoord::Union{Int, Nothing};
    sel::Int = 1,
    bathLinesDepth::Union{Nothing, String} = nothing
    )    

    if sel == 4
        error("Quit selected. Exiting plot_interpolation.")
    elseif sel < 1 || sel > 4
        error("Invalid selection $sel. Choose between 1 and 4.")
    end

    # Generate grid coordinates
    meshX = size(Is, 2) == 1 ? [gX_min] : range(gX_min, gX_max, length=size(Is, 2))
    meshY = size(Is, 1) == 1 ? [gY_min] : range(gY_min, gY_max, length=size(Is, 1))  
    fig = nothing  # to store figure if created
    ax = nothing   # to store Axis if created

    if sel == 1
        println("Colored map representation")
        # Plot
        fig = Figure()
        ax =  Axis(fig[1, 1], yreversed = true)

        # Mimics Octave's imagesc
        hm = heatmap!(ax, meshX, meshY, reverse(-Is', dims=2), colormap=:viridis)
        Colorbar(fig[1, 2], hm, label="Depth (m)")

        display(fig)

    elseif sel == 2
        println("3-D elevation map")
        # 3D surface
        fig = Figure(size = (1000, 800))
        ax = Axis3(fig[1, 1], yreversed = true)
        meshXX = repeat(collect(meshX)', size(Is,1), 1)
        meshYY = repeat(collect(meshY), 1, size(Is,2))
        surface!(ax, meshXX, meshYY, -Is)

    elseif sel == 3
        println("Contour map")
        # Clean NaNs
        Is_clean = filter(!isnan, vec(Is))
        if isempty(Is_clean)
            error("Interpolated depth data contains only NaNs.")
        end

        d_min = minimum(Is_clean)
        d_max = maximum(Is_clean)
        d_min = d_min > 0 ? d_min : 0.0
        n_levels = 10

        println("Interpolation depths range from $d_min m to $d_max m")
        println("Input depths of bathymetric lines (comma separated, default: steps of 5 m): $bathLinesDepth")

        bathylines = isnothing(bathLinesDepth) ?
            bathylines = collect(range(dmin, dmax, n_levels)) :
            parse.(Float64, split(bathLinesDepth, ","))

        # Plot
        fig = Figure(size = (1000, 800))
        ax = Axis(fig[1, 1], aspect = 1.0)
        contour!(ax, meshX, meshY, reverse(-Is', dims=2); 
            levels = bathylines, 
            colormap = :viridis, 
            )
    end

    if utmCoords
        println("UTM-zone: $znCoord")
        if sel == 2 && ax isa Axis3
            ax.xlabel = "UTM-X (m)"
            ax.ylabel = "UTM-Y (m)"
            ax.zlabel = "Depth (m)"
        elseif ax !== nothing
            ax.xlabel = "UTM-X (m)"
            ax.ylabel = "UTM-Y (m)"
        end
    else
        if sel == 2 && ax isa Axis3
            ax.xlabel = "Longitude (°)"
            ax.ylabel = "Latitude (°)"
            ax.zlabel = "Depth (m)"
        elseif ax !== nothing
            ax.xlabel = "Longitude (°)"
            ax.ylabel = "Latitude (°)"
        end
    end

    display(fig)

    println("Interpolation data plotted!")
end
