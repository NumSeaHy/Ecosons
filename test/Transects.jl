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

        # Compute bathymetry
        baths = compute_bathymetry(data)
        
        # Prepare the data to export/plot
        ntr, utmCoords, xCoord, yCoord, znCoord, depth, _ = preproc_transects(
                baths, data; sel = config["transects"]["sel"], use_utm = config["transects"]["use_utm"]) 

        # Plot transects (still images) withouth the depth
        transect_args = Dict(Symbol(k) => v for (k, v) in config["transects"]["plot"])
        transect_args[:save_dir] = joinpath(@__DIR__, transect_args[:save_dir] )
        #plot_transects(ntr, utmCoords, xCoord, yCoord; znCoord = znCoord, save_dir = save_dir_transects, is3d = false)
        plot_transects(ntr, utmCoords, xCoord, yCoord; depth = depth, znCoord = znCoord, transect_args...)

        # Plot transects (gifs) withouth the depth
        #= plot_transects(ntr, utmCoords, xCoord, yCoord; znCoord = znCoord, save_dir = save_dir_transects,
        is3d = false, make_gif = true, framerate = 15) =#
       
        #= ntr, utmCoords, xCoord, yCoord, znCoord, depth, _ = preproc_transects(
                baths, data; sel = 2) #sel has to be 2 here!
                
        # Plot transects 3D with the depth (still images)
        plot_transects(ntr, utmCoords, xCoord, yCoord; depth = depth,
        znCoord = znCoord, save_dir = save_dir_transects, is3d = true)

        # Plot transects 3D with the depth (GIFs)
        plot_transects(ntr, utmCoords, xCoord, yCoord; depth = depth,
        znCoord = znCoord, save_dir = save_dir_transects, is3d = true, make_gif = true) =#

        # Export 
        export_dir =  joinpath(@__DIR__, config["transects"]["export"]["file"])
        n_step = config["transects"]["export"]["n_step"]
        export_transects(ntr, utmCoords, xCoord, yCoord, znCoord, export_dir; n_step = n_step)
end