"""
Plots bathymetry crossing data categorized by depth difference ranges.

# Arguments
- `TRANSECTCROSS::TransectCross`: A struct containing bathymetry crossing data,
  including depth differences and coordinate information.
- `use_utm::Bool`: If `true`, plots use UTM coordinates; if `false`, plots use geographic coordinates (longitude, latitude).

# Behavior
- Computes absolute depth differences (`ddepth`) and categorizes points into four bins based on these differences:
  - 0.25 < diff < 0.50
  - 0.50 < diff < 1.00
  - 1.00 < diff < 2.00
  - diff > 2.00
- For each category, creates a scatter plot of the points with their coordinates.
- The x- and y-axis labels adjust based on the coordinate system (`UTM` or `Lon/Lat`).
- Displays a legend and shows the figure.
- Prints a confirmation message when done.

# Notes
- Uses `CairoMakie` for plotting.
- Assumes `TransectCross` contains the following fields:
  - `ddepth`: Vector of depth differences.
  - `utmX1`, `utmY1`: Vectors of UTM X and Y coordinates.
  - `lon1`, `lat1`: Vectors of longitude and latitude coordinates.
"""
function plot_bathycross(
    TRANSECTCROSS:: TransectCross,
    use_utm:: Bool
    )   

    adh = abs.(TRANSECTCROSS.ddepth)
    masks = Dict(
        "dz_025_050" => (adh .> 0.25) .& (adh .< 0.50),
        "dz_050_100" => (adh .> 0.50) .& (adh .< 1.00),
        "dz_100_200" => (adh .> 1.00) .& (adh .< 2.00),
        "dz_gt_200"  => (adh .> 2.00)
    )

    for (label, mask) in pairs(masks)
        fig = CairoMakie.Figure(size = (800, 600))
        ax = CairoMakie.Axis(fig[1, 1],
            xlabel = use_utm ? "X (UTM)" : "Longitude",
            ylabel = use_utm ? "Y (UTM)" : "Latitude",
            title = label
        )

        if use_utm
            CairoMakie.scatter!(ax, TRANSECTCROSS.utmX1[mask], TRANSECTCROSS.utmY1[mask], label = label, marker = :circle, color = :blue)
        else
            CairoMakie.scatter!(ax, TRANSECTCROSS.lon1[mask], TRANSECTCROSS.lat1[mask], label = label, marker = :circle, color = :blue)
        end

    CairoMakie.axislegend(ax)
    CairoMakie.display(fig)
    end

    println("Bathymetry crossing data plotted!")
end
