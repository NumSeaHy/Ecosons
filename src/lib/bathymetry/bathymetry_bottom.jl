include("../procs/getAverageHit.jl")    # Detects bottom using averaged echo method
include("../procs/getFirstHit.jl")      # Detects bottom using first strong echo with thresholding
using ..SignalProcessing:smoothRange   # Applies smoothing to the detected bottom range

"""
Computes bottom detection and adds it to each SonarDataRAW object in the array.

# Arguments:
- Either `data`: An array of `SonarDataRAW` objects, each containing sonar backscatter data,
or `P` and `Q`: A matrix of backscatter data and a vector of sample metadata.
- `sel`: Algorithm selection (1 = average echo, 2 = threshold, 3 = quit).
- `nF`: Near-field approximation depth (to avoid surface reverberation).
- `smoothR`: Smoothing radius in number of pings.
- `smoothS`: Smoothing sigma for Gaussian smoothing.
- `ndB`: First threshold in dB (for threshold method).
- `nndB`: Second threshold in dB (for threshold method).
- `do_smoothing`: If `true`, apply smoothing to result.

# Returns:
- Modified `data` array with bottom detection (`R`) updated or just `R`
"""
function compute_bottom(
    data::Array{SonarDataRAW};
    sel::Int = 2,
    nF::Float64 = 5.0,
    smoothR::Int = 6,
    smoothS::Int = 3,
    ndB::Int = 30,
    nndB::Int = 60,
    do_smoothing::Bool = true
    )::Array{SonarDataRAW}

    # Validate input types and values
    if isempty(data)
        throw(ArgumentError("`data` array is empty. No echograms defined"))
    end

    if !(sel in (1, 2, 3))
        throw(ArgumentError("Invalid `sel` value: $sel. Must be 1, 2, or 3"))
    end

    if nF < 0
        throw(ArgumentError("`nF` (near-field depth) must be non-negative, got $nF"))
    end

    if smoothR <= 0
        throw(ArgumentError("`smoothR` (smoothing radius) must be positive, got $smoothR"))
    end

    if smoothS <= 0
        throw(ArgumentError("`smoothS` (smoothing sigma) must be positive, got $smoothS"))
    end

    if ndB < 0
        throw(ArgumentError("`ndB` (first threshold) must be non-negative, got $ndB"))
    end

    if nndB < 0
        throw(ArgumentError("`nndB` (second threshold) must be non-negative, got $nndB"))
    end

    if ndB >= nndB
        throw(ArgumentError("`ndB` must be less than `nndB` (ndB = $ndB, nndB = $nndB)"))
    end

    # Early exit on quit selection
    if sel == 3
        println("Quit")
        return data
    end

    # Bottom detection algorithms
    if sel == 1
        println("1. Averaged bounced echo method")
        for i in eachindex(data)
            data[i].R = getAverageHit(data[i].P, data[i].Q, nF)
        end
    elseif sel == 2
        println("2. Max+threshold method")
        println("First threshold: $(ndB) dB")
        println("Second threshold: $(nndB) dB")
        for i in eachindex(data)
            data[i].R = getFirstHit(data[i].P, data[i].Q, nF, ndB, nndB)
        end
    end

    println("Near-field approximation depth: $(nF) m")
    # Optional smoothing
    if do_smoothing
        println("Smoothing radius (pings): $(smoothR)")
        println("Smoothing sigma: $(smoothS)")
        for i in eachindex(data)
            data[i].R = Float64.(data[i].R)
            data[i].R, _ = smoothRange(data[i].R, smoothR, smoothS)
        end
    end

    return data
end


function compute_bottom(
    P::Matrix{Float64},
    Q::Vector{Sample};
    sel::Int = 2,
    nF::Float64 = 5.0,
    smoothR::Int = 6,
    smoothS::Int = 3,
    ndB::Int = 30,
    nndB::Int = 60,
    do_smoothing::Bool = true
    )

    # Validate input types and values
    if !(sel in (1, 2, 3))
        throw(ArgumentError("Invalid `sel` value: $sel. Must be 1, 2, or 3"))
    end

    if nF < 0
        throw(ArgumentError("`nF` (near-field depth) must be non-negative, got $nF"))
    end

    if smoothR <= 0
        throw(ArgumentError("`smoothR` (smoothing radius) must be positive, got $smoothR"))
    end

    if smoothS <= 0
        throw(ArgumentError("`smoothS` (smoothing sigma) must be positive, got $smoothS"))
    end

    if ndB < 0
        throw(ArgumentError("`ndB` (first threshold) must be non-negative, got $ndB"))
    end

    if nndB < 0
        throw(ArgumentError("`nndB` (second threshold) must be non-negative, got $nndB"))
    end

    if ndB >= nndB
        throw(ArgumentError("`ndB` must be less than `nndB` (ndB = $ndB, nndB = $nndB)"))
    end

    # Early exit on quit selection
    if sel == 3
        println("Quit")
        return 
    end

    # Bottom detection algorithms
    if sel == 1
        R = getAverageHit(P, Q, nF)
        
    elseif sel == 2
        R = getFirstHit(P, Q, nF, ndB, nndB)
    end

    # Optional smoothing
    if do_smoothing
        R, _ = smoothRange(R, smoothR, smoothS)
    end

    return R
end