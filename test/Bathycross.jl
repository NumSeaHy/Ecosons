using EcoSons

# write this if you want to test it individually, if not, just Pkg.test()
using Test, JSON

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

    # Create TransectCross object
    TRANSECTCROSS, useUTM = computeCrosses(baths;
     point_subsampling = config["bathycross"]["point_subsampling"], use_utm = config["bathycross"]["useUTM"])

    # Plot 
    plot_bathycross(TRANSECTCROSS, useUTM)

    # Export
    export_file =  joinpath(@__DIR__, config["bathycross"]["export_file"])
    export_bathycross(TRANSECTCROSS, export_file)

end

