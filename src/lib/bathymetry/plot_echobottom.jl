"""
Plots an echogram from sonar backscatter data and optionally overlays the detected bottom.

# Abinsuments
- `data`: A SonarDataRAW object
- `pings`: (Optional) A range or vector of row indices (bins) to plot from `data.P`. Defaults to the full bin range.
- `bins`: (Optional) A range or vector of column indices (pings) to plot from `data.P`. Defaults to the full ping range.

# Behavior
- If `bins` or `pings` are not specified, the entire echogram matrix is used.
- The function plots the echogram using `CairoMakie`, with intensity in decibels shown as a heatmap.
- If bottom data `R` exists in `data`, it overlays the bottom line in red.
- The vertical axis (`bins`) is reversed so that deeper values appear lower on the plot.
"""
function plot_echobottom(
    data:: SonarDataRAW;
    pings::Union{AbstractVector{Int}, Nothing} = nothing,
    bins::Union{AbstractVector{Int}, Nothing} = nothing,
    )
    if isnothing(pings)
        pings = 1:size(data.P, 1)
    end
    
    if isnothing(bins)
        bins = 1:size(data.P, 2)
    end

    # Validate data.P exists and is a matrix
    if !hasfield(typeof(data), :P)
        error("SonarDataRAW object missing field 'P'")
    end

    println("Plotting echogram...")

    # Plot echogram using CairoMakie
    fig = Figure()
    ax = Axis(fig[1, 1], xlabel="Pings", ylabel="Bins", yreversed=true)
    hm = heatmap!(ax, data.P[pings, bins], colormap=:viridis, colorrange=(-125, 0))
    Colorbar(fig[1, 2], hm, label = L"I\,[\mathrm{dB}]")

    # Overlay bottom detection line if available
    if hasproperty(data, :R) && !isnothing(data.R) && !isempty(data.R)
        lines!(ax, pings, data.R[pings] .- minimum(bins), color=:red)
    end

    display(fig)
    return "Echogram plotted!"
end

