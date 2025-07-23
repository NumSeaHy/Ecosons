"""
Detects the first strong echo (bottom hit) in a series of acoustic pings using a double-threshold method.

Each row in `P` represents a single acoustic ping. This function searches for the first sample within each ping
where the signal strength remains above a primary threshold (`ndB`) and does not fall below a secondary
threshold (`nndB`) too early. A near-field offset (`nearF`) is used to exclude initial transducer reverberations.

# Arguments
- `P::Matrix{Float64}`: 2D matrix where each row is an acoustic ping and columns are intensity samples.
- `Q:: Metadata associated with each ping, including sound velocity and sampling interval.
- `nearF::Float64`: Near-field exclusion zone in meters to ignore transducer ringdown and reverberation.
- `ndB::Int`: Primary threshold (in dB) defining the main lobe echo boundary.
- `nndB::Int`: Secondary threshold (in dB) to define the background noise floor.

# Returns
- `hit::Vector{Int}`: Indices of the first significant echo for each ping after applying near-field and threshold filters.

# Notes
- The near-field index (`knf`) is calculated to skip initial samples where transducer effects dominate.
- `ndB` and `nndB` should satisfy `ndB < nndB` for proper operation.
- Default values of 30 dB and 60 dB are based on sonar main/side lobe criteria.
"""
function getFirstHit(
    P::Matrix{Float64},
    Q::Vector{Sample},
    nearF::Float64,
    ndB::Int,
    nndB::Int
    )::Vector{Int}

    # Input validation
    n_pings, n_bins = size(P)

    if length(Q) != n_pings
        throw(ArgumentError("Length of Q ($(length(Q))) must match number of rows in P ($n_pings)"))
    end
    if nearF < 0
        throw(ArgumentError("nearF (near-field offset) must be non-negative"))
    end
    if ndB < 0 || nndB < 0
        throw(ArgumentError("Thresholds ndB and nndB must be non-negative"))
    end
    if ndB >= nndB
        throw(ArgumentError("ndB must be less than nndB (ndB=$ndB, nndB=$nndB)"))
    end

    for q in Q
        if isnothing(q.soundVelocity) || isnothing(q.sampleInterval)
            throw(ArgumentError("Elements of $q must have soundVelocity and sampleInterval"))
        end
    end

    # Filter out NaN values in P
    P = replace(P, NaN => -Inf)

    knf = 2 * floor(Int, nearF / (Q[1].soundVelocity * Q[1].sampleInterval))
    pP = P[:, knf:end]

    # Initialize hits array
    hit = zeros(Int64, n_pings)

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

  