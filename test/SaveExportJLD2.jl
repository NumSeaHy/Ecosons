using Ecosons
using JSON

# === Load config from JSON ===
json_path = joinpath(@__DIR__, "../config/params.json")
config = JSON.parsefile(json_path)

dir = joinpath(@__DIR__, config["data_dir"])
files = filter(f -> endswith(f, ".raw"), readdir(dir))
full_paths = joinpath.(dir, files)
channel = config["channel"]
jld2dir = joinpath(@__DIR__, config["JLD2_dir"]["data"])

#= # === Load data ===
data, dim = load_sonar_data(channel, full_paths);

# Select the transect
transect = config["transect"]
# transect = select_data(data, (30.2, -0.8)) #Filter Sonar Data by lat/lon

# === Bottom detection parameters ===
bottom_args = Dict(Symbol(k) => v for (k, v) in config["bottom_detection"])
data = compute_bottom(data; bottom_args...)   # Splat kwargs

saveJLD2("$(jld2dir)", data)

# Compute bathymetry
baths = compute_bathymetry(data)

JLD2_path = joinpath(@__DIR__, config["JLD2_dir"]["bath"])

# Save bathymetry object as .jld2
saveJLD2(JLD2_path, baths) =#

sonar_array = []

for (nraw, raw_name) in enumerate(full_paths)
    try
        P, Q, G = simradRAW(raw_name)
        println("Loaded: $(raw_name)")
        push!(sonar_array, [raw_name, P, Q, G])
    catch e
        if isa(e, EOFError)
            println("EOFError encountered for file: ", raw_name, ". Skipping this file.")
        else
            # Re-throw the exception if it's not an EOFError
            rethrow()
        end
    end
end

saveJLD2("$(jld2dir)", sonar_array)
