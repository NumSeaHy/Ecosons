"""
    pingCorrect(P, d, d0, dmx; alpha=0.0, algn_dB=30.0)

Corrects a sonar ping `P` based on depth information and signal attenuation.

# Arguments
- `P::AbstractVector`: the original ping (in dB).
- `d::Real`: actual ping depth.
- `d0::Real`: reference depth.
- `dmx::Real`: maximum depth to stretch to.
- `alpha::Real`: attenuation coefficient (in dB/meter), optional (default 0).
- `algn_dB::Real`: dB below max to align ping to, optional (default 30 dB).

# Returns
- `PP::Vector{Float64}`: the corrected ping (in dB).
"""
function pingCorrect(P::Vector{Float64}, d::Union{Float64, Int64}, d0::Float64, dmx::Float64, 
    alpha::Union{Vector{Float64}, Float64}, algn_dB::Int64)

    if d >= d0
        n = length(P)
        isvalid = .!isnan.(P)
        idx_valid = findall(isvalid)

        if isempty(idx_valid) || d < d0
            return fill(NaN, n)
        end

        Pclean = P[isvalid]
        PP = Pclean .+ 30 * log10(d / d0)

        if alpha != 0 && length(alpha) == 1
            attenuation = 2 * alpha .* d .* (1 .+ (0:length(PP)-1) ./ length(PP))
            PP .+= attenuation
        end

        if dmx > d && d > d0
            lp = 4 * dmx / d
            lp0 = 4 * dmx / d0
            dlp = 1 + (lp0 - lp)

            ckern = vcat(ones(floor(Int, dlp)), dlp - floor(dlp))
            # Convert from dB to linear, convolve, then back to dB
            convP = conv10dB(PP, ckern) ./ dlp
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
    else
        PP = fill(NaN, size(P))
    end
    return PP
end

# Utility: convolution on power scale (dB → linear)
function conv10dB(P::AbstractVector, kernel::AbstractVector)
    return conv(10 .^ (0.1 .* P), kernel)
end
