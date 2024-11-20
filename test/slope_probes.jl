using Revise

using JLD2
using Statistics
includet("../src/Slopes.jl")
includet("../src/Geo.jl")
includet("../src/ComputeBathymetry.jl")
includet("../src/Resampling.jl")
using .Slopes
using .Geo
using .ComputeBathymetry
using .Resampling

@load "./baths.jld2" baths

baths

slopes = slopesFromBathymetry(baths, 15.)

new_bath = resampleBathymetry(baths, slopes, 15., 10)

new_bath[1].latitude
new_bath[1].depth

