using EcoSons
using Test
using CairoMakie
using JSON

@testset begin
    # === Load config from JSON ===
    json_path = joinpath(@__DIR__, "../config/params.json")
    config = JSON.parsefile(json_path)

    channel = config["channel"]

    # === Load data ===
    JLD2_path_data = joinpath(@__DIR__, config["JLD2_dir"]["data"])
    data =  loadJLD2(JLD2_path_data; isdata = true)

    # Update the data, adding its bottom range
    data = compute_bottom(data)

    # Compute bathymetries
    baths = compute_bathymetry(data)

    # Compute slopes
    slopes = slopesFromBathymetry(baths)

    # Export 
    export_file =  joinpath(@__DIR__, config["slopes"]["export_file"])
    
    export_slopes(baths, slopes, export_file)

    # TEST rangeSlope

    # Modify sX as you want 
    sX = 1:100
    sH = 0.05 .* sX .+ randn(100) .* 0.5
    sH[40:60] .+= 0.5 .* (sX[40:60] .- 50)
    sX = 1:length(sH)

    trend = 0.1 .* sX  # Linear trend with slope 0.05
    sH = sH .+ trend  # Signal with trend

    # Estimate local slope
    ssl = rangeSlope(sH, sX, 5)

    # Create figure and axes
    f = Figure(size = (800, 400))
    ax = Axis(f[1, 1], xlabel = "X", ylabel = "Value or Slope", title = "Local Slope Estimation")

    # Plot signal and slope
    lines!(ax, sX, sH, label = "Signal", color = :blue)
    lines!(ax, sX, ssl, label = "Local Slope", color = :red)
    axislegend(ax, position = :rb)
    display(f)
end