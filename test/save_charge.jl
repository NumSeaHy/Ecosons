using JLD2

using Revise

# Load modules
includet("../src/EA400Load.jl")
includet("../src/ComputeBathymetry.jl")

using .EA400Load
using .ComputeBathymetry


file_pattern = "./data/*raw"
channel = 1

# Load all the files
data, dim = load(channel, file_pattern);

baths = processBathymetries(data, dim, getFirstHit)

@save "./baths.jld2" baths