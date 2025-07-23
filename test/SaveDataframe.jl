using EcoSons
using DataFrames, Serialization, CSV, JSON
using Test

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

    transect = config["transect"]

    # Update the data, adding its bottom range (non-smoothed and smoothed)
    # Use deepcopy to pass on data because data_ns and data_s won't be independent otherwise
    data_ns = compute_bottom(deepcopy(data); do_smoothing = false) 
    data_s = compute_bottom(deepcopy(data); do_smoothing = true, smoothR = 6, smoothS = 3)

    baths_ns = compute_bathymetry(data_ns)
    baths_s = compute_bathymetry(data_s)

    depth_ns = baths_ns[transect].depth
    depth_s = baths_s[transect].depth


    # Apply tide correction to smoothed bathymetry
    dir_tide = joinpath(@__DIR__, "..", "data", "tide.dat")
    tideCorrection!(baths_s, dir_tide)

    # Create the DataFrame with only the fields you care about
    df = DataFrame(
        baths = depth_ns,
        baths_smoothed = depth_s,
        tide_correction = baths_s[transect].depth
    )


    println(last(df, 10))

    path = joinpath(@__DIR__, "..", "data", "df_controlados_murcia.bin")

    open(path, "w") do io
        serialize(io, df)
    end

    df = deserialize(open(joinpath(@__DIR__, "..", "data", "df_controlados_murcia.bin")))

    CSV.write(joinpath(@__DIR__, "..", "data", "df_controlados_murcia.csv"), df)

    # Find index positions where bathymetry values differ
    diff_indices = findall(i -> df.baths[i] != df.baths_smoothed[i], 1:nrow(df))

    # Show mismatched rows
    if !isempty(diff_indices)
        for idx in diff_indices
            println("Row $idx: baths = $(df.baths[idx]), smoothed = $(df.baths_smoothed[idx])")
        end
    else
        println("All the rows match!")
    end

end