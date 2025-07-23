"""
Returns the seawater attenuation coefficient `alpha` in dB/km.

# Arguments
- `f`: frequency in Hz
- `T`: temperature in Celsius
- `S`: salinity in PSU (e.g. 35)
- `D`: depth in meters (will be converted to km)
- `pH`: acidity level

# Reference
Ainslie & McColm, J. Acoust. Soc. Am., Vol. 103, No. 3, March 1998.
"""
function alphaAinslieMcColm(f, T, S, D, pH)
    f_kHz = f ./ 1000     # frequency in kHz
    D_km = D ./ 1000      # depth in km

    # Boric acid contribution
    A1 = 0.106 .* exp((pH - 8) ./ 0.56)
    P1 = 1.0
    f1 = 0.78 .* sqrt(S ./ 35) .* exp(T ./ 26)
    boric = (A1 .* P1 .* f1 .* f_kHz.^2) ./ (f_kHz.^2 .+ f1.^2)

    # MgSO4 contribution
    A2 = 0.52 .* (S ./ 35) .* (1 .+ T ./ 43)
    P2 = exp(-D_km ./ 6)
    f2 = 42 .* exp(T ./ 17)
    mgso4 = (A2 .* P2 .* f2 .* f_kHz.^2) ./ (f_kHz.^2 .+ f2.^2)

    # Pure water contribution
    A3 = 0.00049 .* exp(-(T ./ 27 .+ D_km ./ 17))
    P3 = 1.0
    h2o = A3 .* P3 .* f_kHz.^2

    return boric .+ mgso4 .+ h2o
end