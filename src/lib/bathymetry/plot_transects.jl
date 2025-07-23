using Printf

"""
Plots transect lines (2D or 3D). Optionally creates animated GIFs.

# Arguments
- `ntr::Vector{Int}`: Transect identifiers.
- `utmCoords::Bool`: If true, uses UTM coordinates; else geographic.
- `xCoord::Vector{Float64}`, `yCoord::Vector{Float64}`: Spatial coordinates.
- `depth::Union{Vector{Float64}, Nothing}`: Required for 3D plotting.
- `znCoord::Union{String, Real}`: UTM zone or label string for axis.
- `save_dir::String`: Output directory for plot images or gifs.
- `is3d::Bool=false`: If true, plots in 3D with `depth`.
- `make_gif::Bool=false`: If true, generates animated GIFs; else static images.
- `framerate::Int=15`: Frame rate (frames per second) for GIF animations.
"""
function plot_transects(
    ntr::Vector{Int},
    utmCoords::Bool,
    xCoord::Vector{Float64},
    yCoord::Vector{Float64};
    depth::Union{Vector{Float64}, Nothing} = nothing,
    znCoord::Union{String, Real} = "",
    save_dir::String = "",
    is3d::Bool = false,
    make_gif::Bool = false,
    framerate::Int = 15
)
    if isempty(ntr)
        error("No valid transect data")
    end

    unique_tr = sort(unique(ntr))
    println("Found $(length(unique_tr)) transects")

    if !isdir(save_dir)
        error("Directory $save_dir not found!")
    end

    for cat in unique_tr
        mask = ntr .== cat
        x = xCoord[mask]
        y = yCoord[mask]

        if is3d
            if depth === nothing
                error("Depth data required for 3D plotting")
            end
            z = -depth[mask]

            fig = Figure(size=(800, 600))
            ax = Axis3(fig[1, 1])
            ax.xlabel = utmCoords ? "UTM-X ($znCoord)" : "Longitude"
            ax.ylabel = utmCoords ? "UTM-Y" : "Latitude"
            ax.zlabel = "Height"

            if !(utmCoords)
                ax.xtickformat = xs -> [@sprintf("%.5f", v) for v in xs]
                ax.ytickformat = ys -> [@sprintf("%.5f", v) for v in ys]
            end

            if make_gif
                step = Int(ceil(length(x)/100)) #You can adjust this
                zmin, zmax = extrema(z)

                if zmin == zmax
                    zmin -= 1.0
                    zmax += 1.0
                end
                limits!(ax,
                    (minimum(x), maximum(x)),
                    (minimum(y), maximum(y)),
                    (zmin, zmax)
                )
                gif_path = joinpath(save_dir, "transect_3d_$(cat).gif")
                lineplot = lines!(ax, Point3f[], color=:blue, label="Transect $cat")
                axislegend(ax)
                record(fig, gif_path, 1:step:length(x); framerate=framerate) do i
                    lineplot[1][] = Point3f.(x[1:i], y[1:i], z[1:i])
                end
                println("Saved 3D animation: $gif_path")
            else
                scatter!(ax, x, y, z, label="Transect $cat")
                axislegend(ax)
                png_path = joinpath(save_dir, "transect_3d_$(cat).png")
                save(png_path, fig)
                println("Saved 3D image: $png_path")
            end
        else
            if length(x) < 2
                @warn "Transect $cat has fewer than 2 points, skipping..."
                continue
            end

            fig = Figure(size=(800, 600))
            ax = Axis(fig[1, 1])
            ax.xlabel = utmCoords ? "UTM-X ($znCoord)" : "Longitude"
            ax.ylabel = utmCoords ? "UTM-Y" : "Latitude"

            if !(utmCoords)
                ax.xtickformat = xs -> [@sprintf("%.5f", v) for v in xs]
                ax.ytickformat = ys -> [@sprintf("%.5f", v) for v in ys]
            end
            if make_gif
                step = Int(ceil(length(x)/100)) #You can adjust this
                limits!(ax, (minimum(x), maximum(x)), (minimum(y), maximum(y)))
                gif_path = joinpath(save_dir, "transect_$(cat).gif")
                lineplot = lines!(ax, Point2f[], color=:blue, label="Transect $cat")
                axislegend(ax)
                record(fig, gif_path, 1:step:length(x); framerate=framerate) do i
                    lineplot[1][] = Point2f.(x[1:i], y[1:i])
                end

                println("Saved 2D animation: $gif_path")
            else
                scatter!(ax, x, y, label="Transect $cat")
                axislegend(ax)
                png_path = joinpath(save_dir, "transect_$(cat).png")
                save(png_path, fig)
                println("Saved 2D image: $png_path")
            end
        end
    end

    println("Transect plots complete.")
end
