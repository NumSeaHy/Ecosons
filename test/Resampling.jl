using Ecosons
using Test
using JSON
@testset begin
    # === Load config from JSON ===
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

    # Compute bathymetries
    baths = compute_bathymetry(data)

    println(baths[1].depth[1:15])

    # Compute slopes
    slopes = slopesFromBathymetry(baths, config["slopes"]["krad"])
    slopes = computeSlopes(baths, slopes)

    # Compute new bathymetries after resampling
    new_baths = resampleBathymetry(baths, slopes, config["slopes"]["srad"], config["slopes"]["nrsp"] )

    export_file =  joinpath(@__DIR__, config["slopes"]["export_file"])
    export_slopes(baths, slopes, export_file)

    println(new_baths[1].depth[1:15])

end