using Ecosons
using Test
using JSON
using DelimitedFiles

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

    # Compute bathymetry
    baths = compute_bathymetry(data)

    dir_tide = joinpath(@__DIR__, "..", "data", "tide.dat")

    # Select the transect and its bathymetry
    transect = config["transect"]

    bath = baths[transect]

    # Plot the bathymetry and see some anomalous points
    plot_bathymetry_line(1:length(bath.depth), -bath.depth)

    println(baths[transect].depth[1:5])

    # Tide correction
    tideCorrection!(baths, dir_tide)
    bath = baths[transect]

    println(baths[transect].depth[1:5])


    plot_bathymetry_line(1:length(bath.depth), -bath.depth) 

    # Prepare the data to export/plot
    ntr, utmCoords, xCoord, yCoord, znCoord, depth, time = preproc_transects(
            baths, data; sel = config["transects"]["sel"], use_utm = config["transects"]["use_utm"])
            
    bathymetry_path = joinpath(@__DIR__, config["bathymetry"]["output_file"])
    export_bathymetry(ntr, utmCoords, xCoord, yCoord, znCoord, depth, time, bathymetry_path)

    data_file = readdlm(bathymetry_path)  
    x = Float64.(data_file[2:end, 4])
    y = Float64.(data_file[2:end, 5])
    z = Float64.(data_file[2:end, 6])

    plot_bathymetry(x, y)

end