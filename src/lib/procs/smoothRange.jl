"""
Smooths out a signal and returns an (inverse) reliability measure.
The larger this measure is for a given bin, the more this bin departs from the smoothed signal.
# Arguments
- `sH`: the signal to smooth out.
- `ll`: the window radius of the averaging filter.
- `ff`: the number of sigmas the signal is dismissed when it departs from the averaged value.
# Returns
- `sH`: smoothed signal.
- `rl`: inverse reliability.

Note: the signal is robustly interpolated in the given interval around each point, and from
this approximation, the standard deviation is computed.
"""
function smoothRange(sH::AbstractVector{<:Real}, ll::Int, ff::Real)
    npts = length(sH)
    ssH = copy(sH)
    rl = zeros(Float64, npts)
    for n in 1:npts
        rg_start = max(1, n - ll)
        rg_end = min(n + ll, npts)
        rg = rg_start:rg_end
        lr = length(rg)
        Δx = rg .- n
        
        # Initial uniform weights
        w = ones(Float64, lr) ./ lr

        # Iteratively update weights
        for iter in 1:19
            sx = sum(w .* Δx)
            sy = sum(w .* sH[rg])
            sxx = dot(w .* Δx, Δx)
            sxy = dot(w .* Δx, sH[rg])

            denom = sxx - sx * sx
            global mr = denom != 0 ? (sxy - sx * sy) / denom : 0.0
            global avg = sy - mr * sx

            global resid = sH[rg] .- (mr .* Δx .+ avg)
            w = 1.0 ./ (1 .+ resid.^2)
            w ./= sum(w)
        end

        resid = sH[rg] .- (mr .* Δx .+ avg)
        std = sqrt(dot(resid.^2, w))

        rl[n] = std > 0 ? abs(avg - sH[n]) / std : 100.0

        if rl[n] > ff
            ssH[n] = round(avg)
        end
    end

    return ssH, rl
end
