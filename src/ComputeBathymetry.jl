module ComputeBathymetry

export getFirstHit, getAverageHit, smoothRange!, processBathymetries, Bathymetry

mutable struct Bathymetry
    name::String
    time::Vector{Float64}
    latitude::Vector{Float64}
    longitude::Vector{Float64}
    depth::Vector{Float64}
end

function processBathymetries(data, dim::Int, bathymetryCalcMethod::Function)::Vector{Bathymetry}
    baths = Vector{Bathymetry}(undef, dim)
    for i in 1:dim
        aux = size(data[i].P, 1)
        idx = filter(j -> data[i].G[j].time > 0, 1:aux)
        local_P = data[i].P[idx,:]
        local_Q = data[i].Q[idx]
        
        # Apply the bathymetry calculation method passed as an argument
        bath = bathymetryCalcMethod(local_P, local_Q, 5)
        smoothRange!(bath, 15, 3)
        
        baths[i] = Bathymetry(
            data[i].name,
            [data[i].G[j].time for j in idx],
            [data[i].G[j].latitude for j in idx],
            [data[i].G[j].longitude for j in idx],
            bath
        )
    end
    return baths
end

"""
    getPingFirstHits(P, Q, ndB, nndB) -> FirstHits

Gets the first hits of an array of pings on a per-ping basis (no ping comparison is performed).

# Arguments
- `P`: Matrix holding one ping per row.
- `Q`: Acquisition data corresponding to the pings in `P`.
- `nearF`: Depreciated berveration measurements due to the own excitation of the transducer.
- `ndB`: Boundary limit of the main lobe (below 5 m depth).
- `nndB`: Background noise limit.

# Returns
- `FirstHits`: Description of what is being returned, adjust based on your function's actual output.

Note: `ndB` is approximately 30dB, according to the directivity function main/secondary lobe criterion; `nndB` is approximately 60dB.
"""
function getFirstHit(P, Q, nearF, ndB=30, nndB=60)
    # near field index
    knf = 2 * floor(Int, nearF / (Q[1].soundVelocity * Q[1].sampleInterval))
    pP = P[:, knf:end]

    # Initialize hits array
    hit = zeros(Int, size(P, 1))

    for p in 1:size(P, 1)
        maxP = maximum(pP[p, :])
        hit[p] = argmax(pP[p, :])
        # hit[p] = hit[p] !== nothing ? hit[p] : 0

        # Search for the first hit
        for k in reverse(1:hit[p])
            if pP[p, k] >= maxP - ndB
                hit[p] = k
            elseif pP[p, k] < maxP - nndB
                break
            end
        end
    end

    return hit .+ (knf - 1)  # Correct index with near field index
end

"""
getAverageHit(P, Q, nearF) -> getAverageHit

Gets the first hits of an array of pings on a per-ping basis (no ping comparison is performed).

# Arguments
- `P`: Matrix holding one ping per row.
- `Q`: Acquisition data corresponding to the pings in `P`.
- `nearF`: Depreciated berveration measurements due to the own excitation of the transducer.

# Returns
- `hit`: Description of the return value (adjust based on actual output).

Note: The `ndB` and `nndB` parameters are based on acoustic principles relevant to sonar operation. The `ndB` value is associated with the main lobe's boundary limit, and `nndB` refers to the acceptable level of background noise.
"""
function getAverageHit(P, Q, nearF)
    # Calculate the near-field index (no depth shallower than nearF)
    knf = 2 * floor(Int, nearF / (Q[1].soundVelocity * Q[1].sampleInterval))
    lgt = size(P, 2)

    hit = fill(NaN, size(P, 1))

    for k in eachindex(P, 1)
        pPk = 10 .^ (P[k, knf:lgt] / 10)
        pPkr = pPk .* collect(1:(lgt - knf + 1))
        hit[k] = sum(skipmissing(pPkr)) / sum(skipmissing(pPk))
        if isnan(hit[k])
            hit[k] = 0
        end
    end

    for k in eachindex(P, 1)
        pPk = 10 .^ (P[k, knf:lgt] / 10)
        lk = min(round(Int, 1.5 * hit[k]), length(pPk))
        llk = max(knf, floor(Int, 0.5 * hit[k]))
        if lk > 0
            pPkr = pPk[1:lk] .* collect(1:lk)
            hit[k] = sum(skipmissing(pPkr)) / sum(skipmissing(pPk[1:lk]))
            if isnan(hit[k])
                hit[k] = 0
            end
        end
    end

    hit .+= (knf - 1)
    hit = round.(hit)
    return hit
end

"""
    smoothRange(sH, ll, ff) -> (ssH, rl)

Smooths out a signal and returns an (inverse) reliability measure.
The larger this measure is for a given bin, the more this bin departs from the smoothed signal.

# Arguments
- `sH`: the signal to smooth out.
- `ll`: the window radius of the averaging filter.
- `ff`: the number of sigmas the signal is dismissed when it departs from the averaged value.

# Returns
- `ssH`: smoothed signal.
- `rl`: inverse reliability.

Note: the signal is robustly interpolated in the given interval around each point, and from this approximation, the standard deviation is computed.
"""
function smoothRange!(sH, ll, ff)
    
    rl = zeros(length(sH))

    for n in eachindex(sH)
        rg = max(1, n-ll):min(n+ll, length(sH))
        lr = length(rg)
        w = ones(lr) ./ lr
        
        # Initialize mr (and any other variables) before the loop
        mr = 0.0
        avg = 0.0

        for iter in 1:20
            sx = sum(w .* (rg .- n))
            sy = sum(w .* sH[rg])
            sxx = sum(w .* (rg .- n) .* (rg .- n))
            sxy = sum(w .* (rg .- n) .* sH[rg])

            mr = (sxy - (sx * sy)) / (sxx - (sx * sx))
            avg = (sy - mr * sx)

            w = 1.0 ./ (1.0 .+ ((sH[rg] .- (mr .* (rg .- n) .+ avg)) .^ 2))
            w = w ./ sum(w)
        end

        std = sqrt(sum(((sH[rg] .- (mr .* (rg .- n) .+ avg)) .^ 2) .* w))
        
        if std > 0
            rl[n] = abs(avg - sH[n]) / std
        else
            rl[n] = 100
        end
        
        if rl[n] > ff
            sH[n] = round(Int, avg)
        end
    end

    return sH # Corrected to return the modified signal
end


end