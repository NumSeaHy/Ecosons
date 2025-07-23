using CSV, LinearAlgebra


# Load data from CSV, skip first row header, convert to real if needed
Dat = CSV.read("datos_Es-chan12.csv", header=false) |> Matrix{Float64}

# Extract columns, note Julia indices start at 1
lat = Dat[2:end, 2]'  # transpose to row vector
lon = Dat[2:end, 3]'

depth38 = Dat[2:end, 4]'
depth200 = Dat[2:end, 14]'  # 10+4=14 column

Es = Dat[2:end, vcat(5:10, 15:20)]  # columns 5 to 10 and 15 to 20

# ES distance function
function es_distance(Pa::AbstractVector, Pb::AbstractVector)
    return maximum(abs.(Pa .- Pb))
end

# ES average function
function es_average(Ps::AbstractMatrix, ds, cs)
    P = mean(Ps; dims=1)
    d = maximum(ds)
    return vec(P), d
end

# Classify using ping_class2f, empty arrays replaced with nothing or empty vectors
cCLASS, nCLASS, cPINGS, cDEPTHS = ping_class2f(Es, 10, 0.90, nothing, nothing, es_distance, es_average)

# Sort by descending nCLASS
idx = sortperm(nCLASS, rev=true)
nCLASS = nCLASS[idx]
cCLASS = cCLASS[idx]
cPINGS = cPINGS[idx, :]  # assuming cPINGS is a matrix
cDEPTHS = cDEPTHS[idx]
lat = lat[idx]
lon = lon[idx]
depth38 = depth38[idx]
depth200 = depth200[idx]
Es = Es[idx, :]
