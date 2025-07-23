"""
Performs a minimum square trigonometric interpolation.

# Arguments
- `t`: Independent variable ("time").
- `x`: Values evaluated at `t`.
- `tp`: Interpolation abscissae.
- `T`: Interpolation period (optional; default is calculated based on `t`).

# Returns
- `xp`: Interpolated values at `tp`.
"""
function triginterp(t::Vector{Float64}, x::Vector{Float64}, tp::Vector{Float64}, T::Union{Float64,Nothing}=nothing)
    _eps = 1e-10
    # Ensure data are vectors (Julia's default so this step might be redundant unless working with matrix)

    # Remove NaNs
    sel = .!isnan.(t) .& .!isnan.(x)
    t, x = t[sel], x[sel]

    # Default period
    if T === nothing
        T = length(t) * (maximum(t) - minimum(t)) / (length(t) - 1)
    end

    # Average and residue
    A0 = mean(x)
    rx = x .- A0

    An = zeros(Float64, length(t))
    Bn = zeros(Float64, length(t))

    for n in 1:length(t)
        # Harmonic frequencies
        wfr = 2 * π * n / T
        cs = cos.(wfr .* t)
        sn = sin.(wfr .* t)

        # Trigonometric regression sums
        Scx = sum(rx .* cs)
        Ssx = sum(rx .* sn)
        Sc2 = sum(cs .^ 2)
        Ss2 = sum(sn .^ 2)
        Ssc = sum(sn .* cs)

        # Regression coefficients
        An[n] = (Ssc * Ssx - Ss2 * Scx) / (Ssc^2 - Sc2 * Ss2 + _eps)
        Bn[n] = (Ssc * Scx - Sc2 * Ssx) / (Ssc^2 - Sc2 * Ss2 + _eps)

        # Residue
        rx .-= An[n] .* cos.(wfr .* t) .+ Bn[n] .* sin.(wfr .* t)
    end

    # Interpolation formula
    xp = fill(A0, length(tp))
    for n in 1:length(t)
        wfr = 2 * π * n / T
        xp .+= An[n] .* cos.(wfr .* tp) .+ Bn[n] .* sin.(wfr .* tp)
    end

    return xp
end
