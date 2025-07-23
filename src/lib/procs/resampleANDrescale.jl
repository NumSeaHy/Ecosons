"""
Resamples and optionally rescales rows of a matrix `P` over a specified range using either
"copy" or "linear" interpolation methods.

# Arguments
- `P::AbstractMatrix{<:Real}`: Input matrix where each row contains a time or spatial signal.
- `nfr::Vector{Int}`: Starting indices (per row) of the interval to resample.
- `nto::Vector{Int}`: Ending indices (per row) of the interval to resample.
- `lgt::Int`: Target number of output points per row after resampling.
- `method::String`: Resampling method to use. Options are:
    - `"copy"`: Directly maps original values to new positions with simple index remapping.
    - `"linear"`: Performs linear interpolation between adjacent samples.

# Returns
- `rP::Matrix{Float64}`: Resampled (and possibly rescaled) matrix of shape `(size(P, 1), lgt)`.

# Notes
- Input values are interpreted as being in decibels (dB); internally, power conversion
  (`10^(dB/10)`) is used for energy-preserving interpolation.
- The `"linear"` method uses a power-domain interpolation, then converts back to dB.
- Any `NaN` values in `P` are excluded during power sum calculations to avoid skewing the results.
- If an invalid method is passed, an empty array of size `(0, 0)` is returned.

# Example
```julia
P = rand(5, 100) .* 30 .- 20  # 5 signals of 100 samples in dB
nfr = [10, 20, 15, 30, 25]
nto = [60, 70, 65, 80, 75]
resampled = resampleANDrescale(P, nfr, nto, 50, "linear")
"""
function resampleANDrescale(P, nfr, nto, lgt, method)::Array{Float64}
    nrows = size(P, 1)
    rP = fill(NaN, nrows, lgt)  # initialize with NaN

    if method == "copy"
        for n in 1:nrows
            # old equivalences for new positions
            rhit = floor.(Int, nfr[n] .+ (0:(lgt - 1)) .* (nto[n] - nfr[n] + 1) / lgt)

            Pnfr = P[n, nfr[n]:nto[n]]
            Pnfr = Pnfr[.!isnan.(Pnfr)]

            Prhit = P[n, rhit]
            Prhit = Prhit[.!isnan.(Prhit)]

            sP = sum(10 .^(Pnfr ./ 10))
            ssP = sum(10 .^(Prhit ./ 10))

            if ssP != 0
                # rP[n, :] = 10 * log10(sP / ssP) .+ P[n, rhit]  # commented out in original
                rP[n, :] = P[n, rhit]
            else
                rP[n, :] = P[n, rhit]
            end
        end

    elseif method == "linear"
        for n in 1:nrows
            rhit = nfr[n] .+ (0:(lgt - 1)) .* (nto[n] - nfr[n] + 1) / lgt

            nhit = min.(floor.(Int, rhit), size(P, 2))
            mhit = min.(floor.(Int, rhit .+ 1), size(P, 2))

            whit = mhit .- rhit

            Pnfr = P[n, nfr[n]:nto[n]]

            sP = sum(10 .^(Pnfr ./ 10))

            pwrn = whit .* 10 .^(P[n, nhit] ./ 10) .+ (1 .- whit) .* 10 .^(P[n, mhit] ./ 10)

            ssP = sum(pwrn)

            if ssP != 0
                # rP[n, :] = 10 * log10.( (sP / ssP) .* pwrn )  # commented out in original
                rP[n, :] = 10 .* log10.(pwrn)
            else
                rP[n, :] = 10 .* log10.(pwrn)
            end
        end

    else
        rP = Array{Float64}(undef, 0, 0)
    end

    return rP
end
