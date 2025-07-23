using EcoSons
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

    # Select the transect
    transect = config["transect"]
    # transect = select_data(data, (30.2, -0.8)) #Filter Sonar Data by lat/lon

    # === Bottom detection parameters ===
    bottom_args = Dict(Symbol(k) => v for (k, v) in config["bottom_detection"])
    data = compute_bottom(data; bottom_args...)  # Splat kwargs

    jld2dir = joinpath(@__DIR__, config["JLD2_dir"]["data"])
    saveJLD2("$(jld2dir)_$(channel)", data)
    
    # TEST change of soundVelocity
    #set_sound_velocity!(data; velocity = velocityUNESCO(20.0, 35.0, 10.0))

    data_selected = data[transect]
    # Plot the echogram
    plot_echobottom(data_selected)

    ping = 1

    plot_ping(1:length(data[transect].P[ping,:]),data[transect].P[ping,:])

    #Export the data
    export_name = "echobottom.dat"
    export_dir = joinpath(@__DIR__, "..", "data", export_name)
    export_echobottom(data_selected, transect, export_dir)
end