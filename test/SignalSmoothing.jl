using CairoMakie
using Statistics
using JSON
using Ecosons

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

# TEST smoothSeqEcho
# Choose ping to smooth
n = 1
data_selected = data[transect]
signal = copy(data_selected.P)
# Apply smoothSeqEcho
smoothed_ping, window_size, snr_val = smoothSeqEcho(signal, n; mmax =  10, snrObj = 1.0)

# Apply smoothRange on original ping row n
smoothed_range, reliability = smoothRange(signal[n, :], 5, 2)

# --- Plotting ---
x = 1:size(data_selected.P, 2)
y_original = data_selected.P[n, :]

fig = Figure(size = (800, 500))
ax = Axis(fig[1, 1], xlabel = "Bin index", ylabel = "Signal amplitude", title = "Signal smoothing comparison")

lines!(ax, x, y_original, label = "Original Ping $n", linewidth = 2)
lines!(ax, x, smoothed_range, label = "smoothRange (robust local fit)", linewidth = 2, linestyle = :dot)
lines!(ax, x, smoothed_ping, label = "smoothSeqEcho (median over pings)", linewidth = 2, linestyle = :dash)

axislegend(ax, position = :lt)

display(fig)