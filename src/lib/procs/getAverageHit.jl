include("../utils/nnsum.jl")
"""
Estimate the average first hit (target echo) for each ping in an array of sonar pings.

This function processes a matrix of pings and returns the estimated position of the first
acoustic return per ping. The estimate is refined by computing a weighted average of echo strengths,
with adjustments based on a near-field compensation range.

# Arguments
- `P::Matrix{Float64}`: A 2D array where each row represents a single ping's intensity profile (typically in dB).
- `Q::Vector{Any}`: Metadata corresponding to each ping in `P`. Each element must support the fields `soundVelocity`
 and `sampleInterval`.
- `nearF::Float64`: Near-field reverberation offset (in meters), typically used to suppress returns from the transducer's 
own excitation. 

# Returns
- `hit::Vector{Int}`: An array of estimated first hit sample indices (one per ping), corrected for near-field range and rounded to integers.
"""
function getAverageHit(P::Matrix{Float64}, Q::Vector{Sample}, nearF::Float64)
    # Input checks
    n_pings = size(P, 1)
    if length(Q) != n_pings
        throw(ArgumentError("Length of Q ($(length(Q))) must match number of rows in P ($n_pings)"))
    end
    if n_pings == 0 || size(P, 2) == 0
        throw(ArgumentError("Input matrix P must not be empty"))
    end
    if nearF < 0
        throw(ArgumentError("nearF (near-field offset) must be non-negative"))
    end

    # Threshold index (no depth shallower than nearF)
    knf = 2 * floor(Int, nearF / (Q[1].soundVelocity * Q[1].sampleInterval))
    lgt = size(P, 2)

    hit = fill(NaN, n_pings)

    # First pass: rough estimate
    for k in 1:n_pings
        p_row = P[k, knf:lgt]
        pPk = 10 .^ (p_row ./ 10)
        indices = collect(1:length(pPk))
        pPkr = pPk .* indices
        s1 = nnsum(pPkr)
        s2 = nnsum(pPk)
        hit[k] = isnan(s1) || isnan(s2) ? 0 : s1 / s2
    end
    
    # Refinement: use 50%-150% of estimate
    for k in 1:n_pings
        if isnan(hit[k])
            hit[k] = 0.0
            continue
        end
        pPk = 10 .^ (P[k, knf:lgt] ./ 10)
        rel_hit = hit[k]  # still relative to `knf` start
        lk = min(round(Int, 1.5 * rel_hit), length(pPk))
        # llk = max(1, floor(Int, 0.5 * rel_hit))  # unused in Octave
        if lk > 0
            idxs = 1:lk
            pPkr = pPk[1:lk] .* idxs
            s1 = nnsum(pPkr)
            s2 = nnsum(pPk)
            hit[k] = s1 / s2
        end
    end
    hit .+= (knf - 1)
    return round.(Float64, hit)
end
