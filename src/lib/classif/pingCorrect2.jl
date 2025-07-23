using DSP

"""
Applies two-way distance-based correction to a ping signal `P`.

# Arguments
- `P`: Input signal (ping) as a vector of real values (e.g., amplitude or dB).
- `d`: Distance (one-way) from transducer to target.
- `d0`: Reference distance for normalization.
- `dmx`: Maximum distance expected for correction (used in alignment and smoothing).
- `alpha`: Absorption coefficient (dB/m), default is `0.0`.
- `algn_dB`: dB threshold for aligning the ping maximum, default is `30`.

# Returns
- Corrected and optionally smoothed/realigned ping signal as a vector.

# Notes
- Applies a **30·log10(2·d/d₀)** spreading loss correction for round-trip path.
- Applies **two-way absorption** correction scaled across the ping.
- Performs convolutional smoothing and alignment based on ping maximum.

Use this if your signal model assumes **two-way propagation**, which is standard for sonar echo returns.
"""
function pingCorrect2(P::Vector{Float64}, d::Union{Float64, Int64}, d0::Real, dmx::Real, 
    alpha::Union{Vector{Float64}, Float64, Vector{Float32}, Float32}, algn_dB::Real)

    n = length(P)
    isvalid = .!isnan.(P)
    idx_valid = findall(isvalid)

    if isempty(idx_valid) || d < d0
        return fill(NaN, n)
    end

    Pclean = P[isvalid]
    PP = Pclean .+ 30 * log10(2 * d / d0)

    if alpha != 0 && length(alpha) == 1
        attenuation = 2 * alpha .* d .* (2 .+ (0:length(PP)-1) ./ length(PP))
        PP .+= attenuation
    end

    if dmx > d && 2d > d0
        lp = 4 * dmx / d
        lp0 = 4 * dmx / d0
        dlp = 1 + (lp0 - lp)

        ckern = vcat(ones(floor(Int, dlp)), dlp - floor(dlp))
        convP = DSP.conv(10 .^ (0.1 .* PP), ckern)
        convP ./= dlp
        PP = 10 .* log10.(convP)

        # Align ping to algn_dB below max
        PPmx, mx_idx = findmax(PP)
        p0 = mx_idx
        while p0 > 1 && PPmx - PP[p0 - 1] < algn_dB
            p0 -= 1
        end

        ping_len = length(Pclean)
        tail_len = max(0, ping_len + p0 - 1 - length(PP))
        PP = vcat(PP[p0:min(end, ping_len + p0 - 1)], fill(NaN, tail_len))
    end

    # Pad back to original length with NaNs at invalid positions
    PPfull = fill(NaN, n)
    insert_len = min(length(PP), length(idx_valid))
    PPfull[idx_valid[1:insert_len]] .= PP[1:insert_len]

    return PPfull
end

