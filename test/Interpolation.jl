using Ecosons
using CairoMakie, Random
import Distributions
using Test
using JSON

@testset begin
    json_path = joinpath(@__DIR__, "../config/params.json")
    config = JSON.parsefile(json_path)

    dir = joinpath(@__DIR__, config["data_dir"])
    files = filter(f -> endswith(f, ".raw"), readdir(dir))
    full_paths = joinpath.(dir, files)
    channel = config["channel"]

    # === Load data ===
    JLD2_path = joinpath(@__DIR__, config["JLD2_dir"]["data"])
    data, dim = load_sonar_data(channel, full_paths; jld2_path = JLD2_path);

    # === Bottom detection parameters ===
    bottom_args = Dict(Symbol(k) => v for (k, v) in config["bottom_detection"])
    data = compute_bottom(data; bottom_args...)  # Splat kwargs

    # Compute bathymetry
    baths = compute_bathymetry(data)
    bath = [baths[1]]
    #= JLD2_path_data = joinpath(@__DIR__, config["JLD2_dir"]["data"])
    JLD2_path_bath = joinpath(@__DIR__, config["JLD2_dir"]["bath"])
    data =  loadJLD2(JLD2_path_data; isdata = true)
    baths = loadJLD2(JLD2_path_bath; isbath = true) =#
    # Prepare the data to export/plot
    Is, utmCoords, gX_min, gX_max, gY_min, gY_max, znCoord = preproc_interpolation(bath)

    # Plot 
    plot_interpolation(Is, utmCoords, gX_min, gX_max, gY_min, gY_max, znCoord; sel = 1)

    # Export 
    export_dir =  joinpath(@__DIR__, "..", "data")
    export_file = "interpolation"
    export_interpolation(Is, utmCoords, gX_min, gX_max, gY_min, gY_max, znCoord, export_dir, export_file)

    PS = copy(data[1].G)
    interpPS!(PS)

    for p in PS
        println("lat: $(p.latitude), lon: $(p.longitude)")
    end

    # TEST xyz2img
    # Grid interpolation
    dxy = 1e-5
    fr  = 4 * dxy
    method = "mean"  # or "idw"

    I, x_min, x_max, y_min, y_max, dxy = xyz2img(
        baths[1].latitude, baths[1].longitude, baths[1].depth, dxy, "mean", fr)
    @show sum(.!isnan.(I))  # should be > 0 now
    # Plot with CairoMakie
    f = Figure(size = (800, 600))
    ax = Axis(f[1, 1], xlabel = "X", ylabel = "Y", title = "Interpolated Z (mean)")
    println("min/max I: ", minimum(I), " / ", maximum(I))
    hm = heatmap!(ax, I; colormap = :viridis)
    Colorbar(f[1, 2], hm)

    display(f)

    # TEST intershapes
    # Input points: two shapes, first is a diagonal line, second is a horizontal line
    xyzs = [
        0.0 0.0;
        1.0 1.0;
        NaN NaN;       # NaN marks separation within shape 1
        0.0 2.0;
        2.0 2.0
    ]

    shns = [1, 1, 1, 2, 2]  # Shape identifiers
    dl = 0.25               # Desired interpolation spacing

    # Run interpolation
    xyzp = intershapes(xyzs, shns, dl)

    # Visualize result
    f = Figure()
    ax = Axis(f[1, 1], xlabel="X", ylabel="Y", title="Interpolated Shapes")
    scatter!(ax, xyzs[:, 1], xyzs[:, 2], color=:red, markersize=10, label="Original")
    lines!(ax, xyzp[:, 1], xyzp[:, 2], color=:blue, label="Interpolated")
    axislegend(ax)
    display(f)




end