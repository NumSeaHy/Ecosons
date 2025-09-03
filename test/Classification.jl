using Ecosons
using CairoMakie
using Test
using JSON

# sampling every npings pings
# previous and following dnpings pings
# depthInf maximum depth
# depthRef reference depth

json_path = joinpath(@__DIR__, "../config/params.json")
config = JSON.parsefile(json_path)
#transect = config["transect"]
dir = joinpath(@__DIR__, config["data_dir"])
files = filter(f -> endswith(f, ".raw"), readdir(dir))
lsRAW = joinpath.(dir, files)

ping_distance = ping_distance1a
ping_average = ping_average1

jld2dir = joinpath(@__DIR__, "$(config["JLD2_dir"]["data"])_classification")
classif_args = Dict(Symbol(k) => v for (k, v) in config["classification"] if k != "export_file") 
transectNo, pingFromNo, pingToNo, PS0, PS, PS20, PS2, Rbins, depthS, latS, lonS = test_class_load(
    lsRAW, ping_distance, ping_average; jld2_path = jld2dir, classif_args...)

nchan = config["classification"]["nchan"]
depthInf = config["classification"]["depthInf"]
depthRef = config["classification"]["depthRef"]

if nchan == 1
    test_title = "38kHz 5.0m $(string(nameof(ping_distance)))"
else 
    test_title = "200kHz 5.0m $(string(nameof(ping_distance)))"
end    

CLASSIFICATION = test_class_class(PS, PS0, PS20, PS2, lonS, latS, depthS, length(lsRAW), depthInf,
    depthRef, nchan, transectNo, pingFromNo, pingToNo, ping_distance, ping_average) 

name = joinpath(@__DIR__, config["classification"]["export_file"])
test_class_Es(CLASSIFICATION, name)

# Convert lat/lon to UTM XY
Xp, Yp = latlon2utmxy(-1, CLASSIFICATION.latS, CLASSIFICATION.lonS)

# Interpolate bathymetry grid
dxy = 10
bathy, xmin, xmax, ymin, ymax, = mrinterp(Xp, Yp, CLASSIFICATION.depthS, dxy, 1)
#= bathy, _, av, se, xmin, xmax, ymin, ymax = trinterpmap(CLASSIFICATION.latS,
    CLASSIFICATION.lonS, CLASSIFICATION.depthS, wRm, cellSz) =#
fig = Figure(size = (800, 600))

ax = Axis(fig[1, 1];
        xlabel = "X (m)", ylabel = "Y (m)",
        title = "$(test_title))",
        aspect = 1.0)  # axis("square") equivalent

# Coordinate vectors for pixel edges (size + 1)
xs = LinRange(xmin, xmax, size(bathy, 1) + 1)
ys = LinRange(ymin, ymax, size(bathy, 2) + 1)

# Note: imagesc in Octave plots from top to bottom, so flip bathy vertically and negate
# In Makie, y-axis by default increases upward, so to match 'set(gca, "YDir", "normal")',
# just use ys as-is (no need to reverse ys). Flip bathy vertically.
hm = heatmap!(ax, xs, ys, reverse(-bathy, dims=1),
        colormap = :viridis,
        colorrange = (-40, 0))

Colorbar(fig[1, 2], hm)  # Add colorbar next to heatmap

# Overlay classification points on top
clsplot(CLASSIFICATION.tCLASS, CLASSIFICATION.cCs, Xp, Yp; ax=ax)

display(fig)

plot_class_map(CLASSIFICATION.tCLASS, CLASSIFICATION.cCs, CLASSIFICATION.lonS, CLASSIFICATION.latS)

plot_mean_std(CLASSIFICATION.tCLASS, CLASSIFICATION.cCs, CLASSIFICATION.PS, CLASSIFICATION.cPINGS)

plot_median_range(CLASSIFICATION.tCLASS, CLASSIFICATION.cCs, CLASSIFICATION.PS, CLASSIFICATION.cPINGS)

plot_min_max(CLASSIFICATION.tCLASS, CLASSIFICATION.cCs, CLASSIFICATION.PS, CLASSIFICATION.cPINGS)