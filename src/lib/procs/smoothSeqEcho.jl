"""
Apply a vertical smoothing operation on a matrix `P` centered at row `n`, expanding adaptively until
the estimated signal-to-noise ratio (SNR) falls below a specified threshold `snrObj`, or until a 
maximum window size `mmax` is reached.

# Arguments
- `P::AbstractMatrix`: 2D array representing sequential echo data, where each row is a profile or time step.
- `n::Int`: Index of the central row around which smoothing begins.
- `mmax::Int`: Maximum allowed half-window size (smoothing can expand up to `n ± mmax`).
- `snrObj::Real`: Desired SNR threshold; smoothing continues until the average absolute difference between
  adjacent non-NaN values in the smoothed row is less than or equal to this threshold.

# Returns
- `sP::Vector`: Smoothed 1D profile (median over rows `na:nb` for each column).
- `m::Int`: Final number of rows used in the smoothing window.
- `snr::Real`: Final computed SNR (mean absolute difference between adjacent non-NaN values in `sP`).

# Behavior
The function starts with a window of one row (just row `n`) and increases the window size symmetrically
(`na` to `nb`) by one row on each side until:
- the smoothed profile's SNR ≤ `snrObj`, or
- the window size reaches the maximum `mmax`.
"""
function smoothSeqEcho(P::Matrix{Float64}, n::Int64; mmax::Int64 = 10, snrObj::Real = 1.0)
    m = 0
    na = n
    nb = n
    sP = copy(P[n, :])
    valid_vals = filter(!isnan, sP)
    snr = mean(abs.(diff(valid_vals)))
    
    while snr > snrObj && m < mmax
        m += 1
        na = max(1, n - m)
        nb = min(size(P, 1), n + m)
        # Median over rows na:nb, for each column
        sP = mapslices(median, P[na:nb, :], dims=1)[:]
        valid_vals = filter(!isnan, sP)
        snr = mean(abs.(diff(valid_vals)))
    end
    
    m = nb - na + 1
    return sP, m, snr
end
