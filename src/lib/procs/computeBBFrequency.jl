using FFTW, DSP
using LinearAlgebra
using Base.Threads
using Dierckx

"""
Compute broadband frequency-resolved waveforms from sonar data using matched filtering.

This function performs FFT-based convolution of the sonar waveform with a representative chirp to obtain
frequency-resolved backscatter data. It supports optional calibration correction and returns the
frequency-domain representation as well as power estimates.

# Arguments
- `HS::Vector{Sample}`: Sonar header structures. Only `HS[1]` is used for parameters such as frequency, sample interval,
 pulse length, and sound velocity.
- `W::Array{Float64, 3}`: Raw waveform matrix of size `(npings, nsamples, nrepeats)`, with coherent transmit replicates
 for each ping.

# Keyword Arguments
- `f_rep::Union{Vector{Float64}, Nothing}`: Optional frequency vector to override automatic frequency selection.
- `useWtemplate::Bool`: If `true`, use a simulated chirp template instead of extracted one (not implemented).
- `withCorrections::Union{Nothing, Number}`: Apply range-dependent and calibration-based power correction if set
 (e.g., `40` for TVG-like gain). Use `nothing` to skip.
- `calXML::Union{Nothing, Dict}`: Parsed calibration XML dictionary. If `nothing`, default parameters are used.
- `returnPower::Bool`: If `true`, return power spectra per frequency.
- `returnPmf::Bool`: If `true`, return matched filter power profile.

# Returns
One of the following tuples depending on `returnPower` and `returnPmf`:
- `(fW, f_sel)` : Only frequency-domain representation per frequency.
- `(fW, f_sel, P)` : Also return calibrated power in dB for each selected frequency.
- `(fW, f_sel, P, Pmf)` : Also return matched filter power profile in dB.

# Outputs
- `fW::Array{ComplexF64, 3}`: Complex frequency-resolved waveform data of size `(nfreqs, npings, nsamples)`.
- `f_sel::Vector{Float64}`: Selected center frequencies (in Hz).
- `P::Vector{Matrix{Float64}}`: Power (in dB) for each frequency and ping.
- `Pmf::Matrix{Float64}`: Matched filter power profile (in dB) for each ping.

# Details
- The matched filter is constructed by averaging ping templates and estimating chirp alignment.
- Frequency-domain transformation uses a Hann windowed complex exponential kernel for each frequency.
- Power corrections include source level, range spreading loss, impedance, and beam pattern effects.
- Calibration values are taken from `calXML` if provided, or from a standard default.
"""
function computeBBFrequency(
    HS:: Vector{Sample},
    W::Array{ComplexF64,3};
    f_rep = nothing,
    useWtemplate::Bool = false,
    withCorrections:: Real = 40, 
    calXML = nothing,
    returnPower::Bool = true,
    returnPmf:: Bool = true)

    dts = HS[1].sampleInterval
    dT = HS[1].pulseLength
    ndT = round(Int, dT / dts)

    if useWtemplate == true
        error("Use of simulated template is not implemented")
    end

    if isempty(W)
        error("W is empty! Check your data...")
    end

    hchirp0 = mean(W[1, 1:3ndT, :], dims=3)[:]
    pchirp0 = abs2.(hchirp0)
    n_c = floor(Int, sum(pchirp0 .* (1:length(pchirp0))) / sum(pchirp0))
    rchirp = filter(x -> x > 0, (n_c-ndT):(n_c+ndT))
    hchirp = mean(W[1, rchirp, :], dims=3)[:]

    hchirp_acr = fftconv_same(hchirp, conj(reverse(hchirp)))
    pow_scale = norm(hchirp) / norm(hchirp_acr)
    hchirp_acr .*= pow_scale

    cc = fftconv_same(hchirp0, conj(reverse(hchirp)))
    _, n_cc = findmax(abs.(cc))

    t_chirp = (collect(1:length(hchirp)) .- mean(1:length(hchirp))) .* dts
    hsignal = dropdims(mean(W, dims=3); dims=3)

    hsignal_uconv = fftconv2_same(hsignal, conj(reverse(hchirp))) .* pow_scale

    if f_rep === nothing || isempty(f_rep)
        f_sel = HS[1].frequency[1]:1000:HS[1].frequency[2]
    else
        f_sel = filter(f -> HS[1].frequency[1] <= f <= HS[1].frequency[2], f_rep)
    end

    f_mean = mean(HS[1].frequency)
    cw = HS[1].soundVelocity
    pwEm = HS[1].transmitPower

    if calXML !== nothing
        g_sel, z_sel, ea_sel, r_load = parse_calibration(calXML, f_sel, f_mean)
    else
        g_sel = fill(10^(20/10), length(f_sel))
        z_sel = fill(75.0, length(f_sel))
        ea_sel = 10 .* log10.(2 .* 17.3^2 .* (38000.0 ./ f_sel))
        r_load = 5400.0
    end

    g_mean = mean(g_sel)
    z_mean = mean(z_sel)
    ea_mean = mean(ea_sel)

    wHann = DSP.hann(length(hchirp))
    fW = Array{ComplexF64}(undef, length(f_sel), size(hsignal_uconv)...)

    for (nf, f) in enumerate(f_sel)
        w_f = wHann .* exp.(-2im * π * f .* t_chirp)
        fC = dot(hchirp_acr, w_f)
        fWnf = fftconv2_same(hsignal_uconv, w_f) ./ fC
        fW[nf, :, :] .= (r_load + z_sel[nf]) / ((1000 + 75) * r_load) .* fWnf
    end

    fW = fW[:, :, n_cc+1:end]

    if returnPower
        P = []
        if !isnothing(withCorrections)
            pW = 0.5 * size(W, 3) .* abs2.(fW) ./ reshape(z_sel .* g_sel.^2, :, 1, 1)
            for nf in eachindex(f_sel)
                range_log = log10.(0.5 .* (1:size(pW, 3)) .* cw .* dts)
                range_log = reshape(range_log, 1, :)   
                Pw = 10 .* log10.(pW[nf, :, :]) .- 10 * log10(pwEm * (cw / (4π * f_sel[nf]))^2) .+
                    withCorrections .* range_log .- ea_sel[nf]
                push!(P, Pw)
            end
        end
    end

    if returnPmf
        hsu_slice = hsignal_uconv[:, n_cc+1:end]
        range_log = log10.(0.5 * (1:size(fW, 3)) .* cw * dts)
        range_log = reshape(range_log, 1, :)   
        Pmf = 10*log10.(0.5 * abs.(hsu_slice).^2 ./ (z_mean * g_mean^2)) .-
              10*log10(pwEm * (cw / (4 * π * f_mean))^2) .+
              withCorrections * range_log .-  ea_mean
    end

    if returnPower && returnPmf
        return fW, f_sel, P, Pmf
    elseif returnPower
        return fW, f_sel, P
    else
        return fW, f_sel
    end

    return fW, f_sel, P, Pmf
end

function parse_calibration(calXML, f_sel, f_mean)
    Ffc = parse.(Float64, split(replace(calXML["Root"]["Calibration"]["CalibrationResults"]["Frequency"]["__content"], ';' => ','), ','))
    Gfc = parse.(Float64, split(replace(calXML["Root"]["Calibration"]["CalibrationResults"]["Gain"]["__content"], ';' => ','), ','))
    Zfc = parse.(Float64, split(replace(calXML["Root"]["Calibration"]["CalibrationResults"]["Impedance"]["__content"], ';' => ','), ','))
    EqBA = 10 .* log10.(2 .* parse.(Float64, split(replace(calXML["Root"]["Calibration"]["CalibrationResults"]["BeamWidthAlongship"]["__content"], ';' => ','), ',')) .*
                           parse.(Float64, split(replace(calXML["Root"]["Calibration"]["CalibrationResults"]["BeamWidthAthwartship"]["__content"], ';' => ','), ',')))

    r_load = parse(Float64, calXML["Root"]["Calibration"]["Common"]["Transceiver"]["Impedance"]["__content"])

    if minimum(Ffc) <= f_mean <= maximum(Ffc)
        # Create spline interpolants
        spline_Gfc = Spline1D(Ffc, Gfc, k=3)   # cubic spline
        spline_Zfc = Spline1D(Ffc, Zfc, k=3)
        spline_EqBA = Spline1D(Ffc, EqBA, k=3)

        # Interpolate at selected frequencies
        g_sel = 10 .^ (spline_Gfc(f_sel) ./ 10)
        z_sel = spline_Zfc(f_sel)
        ea_sel = spline_EqBA(f_sel)
    else
        g_sel = fill(10^(20/10), length(f_sel))
        z_sel = fill(75.0, length(f_sel))
        ea_sel = 10 .* log10.(2 .* 17.3^2 .* (38000.0 ./ f_sel))
    end

    return g_sel, z_sel, ea_sel, r_load
end


function fftconv_same(x::AbstractVector, h::AbstractVector)
    y = conv(x, h)                      # Full convolution: length(x) + length(h) - 1
    n = length(x)
    m = length(h)
    start = fld(m, 2) + 1              # Center-aligned output start index
    return y[start:start + n - 1]      # Slice to match input length
end

function fftconv2_same(X::AbstractMatrix, H::AbstractVector)
    sizeX = size(X)
    Y = similar(X, sizeX)
    for i in 1:sizeX[1]
        Y[i, :] = fftconv_same(X[i, :], H)
    end
    return Y
end

