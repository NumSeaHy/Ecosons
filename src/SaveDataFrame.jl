using Revise
using DataFrames, Serialization


includet("./EA400Load.jl")
includet("./ComputeBathymetry.jl")
includet("./Tides.jl")

using .EA400Load
using .ComputeBathymetry
using .Tides

file_pattern = "./data/*raw"
channel = 1

data, dim = load(channel, file_pattern);

baths = processBathymetries(data, dim, getFirstHit)

for i in 1:dim
    baths[i].depth = 0.5 * baths[i].depth * data[i].Q[1].sampleInterval * data[i].Q[1].soundVelocity
end


df = DataFrame(Name=String[], P=Vector{Matrix{Float64}}(), Q=Vector{Vector{Sample}}(), G=Vector{Vector{GPSData}}())

for i in 1:dim
    push!(df, (data[i].name, data[i].P, data[i].Q, data[i].G))
end

# Bathymetrys without smoothing 
ns_baths = [getFirstHit(data[i].P, data[i].Q, 5) for i in 1:dim]

ns_baths = [0.5 * data[i].Q[1].sampleInterval * data[i].Q[1].soundVelocity * ns_baths[i] for i in 1:dim]

df.ns_bath = ns_baths


aux = deepcopy(ns_baths)
# Smooth the bathymetry to avoid anomalous points
for i in 1:dim
    smoothRange!(aux[i], 6, 3)
end


df.s_bath = aux


# Generate a tide correction from the bathymetry
fname = "./data/tide.dat"
baths = processBathymetries(data, dim, getFirstHit)

for i in 1:dim
    baths[i].depth = 0.5 * baths[i].depth * data[i].Q[1].sampleInterval * data[i].Q[1].soundVelocity
end


tides_corr = [tidecorrectDay!(baths[i], "./data/tide.dat") for i in 1:dim]

df.tide_bath = tides_corr

df.Group = zeros(Int, nrow(df))  # Initialize the group column with zeros or any default value

# Assign group values based on transect numbers
for i in 1:nrow(df)
    if i <= 7
        df.Group[i] = 1
    elseif i >= 8 && i <= 25
        df.Group[i] = 2
    elseif i >= 26 && i <= 35
        df.Group[i] = 3
    end
end

df

open("./data/df_controlados_murcia.bin", "w") do io
    serialize(io, df)
end


