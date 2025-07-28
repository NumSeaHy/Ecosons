# Ping distance functions

#= facer un submuestreo dos pings do RAW
npings=10; #coller un de cada 10 pings
dnpings=10; #mirar nos 10 previos e 10 posteriores =#

# Simple max absolute difference over first 80%
function ping_distance1(Pa::Vector{Float64}, Pb::Vector{Float64})::Float64
    N = floor(Int, 0.8 * min(length(Pa), length(Pb)))
    return maximum(abs.(Pa[1:N] .- Pb[1:N]))
end

# Mean-normalized max absolute difference
function ping_distance2(Pa::Vector{Float64}, Pb::Vector{Float64})::Float64
    N = floor(Int, 0.8 * min(length(Pa), length(Pb)))
    ma = nnmean(Pa[1:N])
    mb = nnmean(Pb[1:N])
    return maximum(abs.((Pa[1:N] .- ma) .- (Pb[1:N] .- mb)))
end

# Min-max normalized difference
function ping_distance3(Pa::Vector{Float64}, Pb::Vector{Float64})::Float64
    N = floor(Int, 0.8 * min(length(Pa), length(Pb)))
    A = Pa[1:N]
    B = Pb[1:N]
    mna, mxa = minimum(A), maximum(A)
    mnb, mxb = minimum(B), maximum(B)
    normA = (A .- mna) ./ (mxa - mna + eps())  # eps to avoid division by 0
    normB = (B .- mnb) ./ (mxb - mnb + eps())
    return maximum(abs.(normA .- normB))
end

# 60% versions
function ping_distance1a(Pa::Vector{Float64}, Pb::Vector{Float64})::Float64
    N = floor(Int, 0.6 * min(length(Pa), length(Pb)))
    return maximum(abs.(Pa[1:N] .- Pb[1:N]))
end

function ping_distance2a(Pa::Vector{Float64}, Pb::Vector{Float64})::Float64
    N = floor(Int, 0.6 * min(length(Pa), length(Pb)))
    ma = nnmean(Pa[1:N])
    mb = nnmean(Pb[1:N])
    return maximum(abs.((Pa[1:N] .- ma) .- (Pb[1:N] .- mb)))
end


# Ping averaging functions

# Linear (arithmetic) average
function ping_average0(Ps::Matrix{Float64}, ds::Vector{Float64}, cs::Vector{Int64})
    if !isempty(ds)
        cs = cs .* ds
        d = dot(cs, ds) / sum(cs)
    else
        d = NaN
    end
    P = (cs' * Ps) ./ sum(cs)
    return vec(P), d
end

# Logarithmic (dB power-weighted) average
function ping_average1(Ps::Matrix{Float64}, ds::Vector{Float64}, cs::Vector{Int64})
    if !isempty(ds)
        cs = cs .* ds
        d = dot(cs, ds) / sum(cs)
    else
        d = NaN
    end
    P = 10 * log10.( (cs' * @. 10^(0.1 * Ps)) ./ sum(cs) )
    return vec(P), d
end
