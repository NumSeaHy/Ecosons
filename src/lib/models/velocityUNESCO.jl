"""
Returns the speed of sound in sea water (m/s) according to UNESCO equation.
Ref: G.S.K. Wong and S. Zhu, J. Acoust. Soc. Am. 97(3) (1995), 1732-1736.

Arguments:
- T: Temperature in °C
- S: Salinity in PSU
- D: Depth in meters (used to estimate pressure)
- Optional: pH and frequency (f), but currently unused

Returns:
- cs: Speed of sound in m/s
"""
function velocityUNESCO(T::Float64, S::Float64, D::Float64; pH = nothing, f = nothing)  
    # Convert depth to pressure (in bar)
    P = 1.013 + 1e-5 * (1023.6 * 9.80665 * D)

    # Polynomial coefficient definitions
    C0 = (C05=3.1419e-9, C04=-1.47797e-6, C03=3.3432e-4, C02=-5.81090e-2, C01=5.03830, C00=1402.388)
    C1 = (C14=-6.1260e-10, C13=1.3632e-7, C12=-8.1829e-6, C11=6.8999e-4, C10=0.153563)
    C2 = (C24=1.0415e-12, C23=-2.5353e-10, C22=2.5986e-8, C21=-1.7111e-6, C20=3.1260e-5)
    C3 = (C32=-2.3654e-12, C31=3.8513e-10, C30=-9.7729e-9)

    A0 = (A04=-3.21e-8, A03=2.008e-6, A02=7.166e-5, A01=-1.262e-2, A00=1.389)
    A1 = (A14=-2.0142e-10, A13=1.0515e-8, A12=-6.4928e-8, A11=-1.2583e-5, A10=9.4742e-5)
    A2 = (A23=7.994e-12, A22=-1.6009e-10, A21=9.1061e-9, A20=-3.9064e-7)
    A3 = (A32=-3.391e-13, A31=6.651e-12, A30=1.100e-10)

    B0 = (-4.42e-5, -1.922e-2)  # B01, B00
    B1 = (1.7950e-7, 7.3637e-5) # B11, B10
    D0 = (D10=-7.9836e-6, D00=1.727e-3)

    # General Horner evaluation for arbitrary degree
    function horner(coeffs::NamedTuple, T)
        c = collect(values(coeffs))
        result = c[1]
        for i in 2:length(c)
            result = result * T + c[i]
        end
        return result
    end

    # Compute powers of pressure
    P2 = P * P
    P3 = P2 * P

    # Evaluate each component
    Cw = horner(C0, T) + horner(C1, T) * P + horner(C2, T) * P2 + horner(C3, T) * P3
    A  = horner(A0, T) + horner(A1, T) * P + horner(A2, T) * P2 + horner(A3, T) * P3
    B  = B0[2] + B0[1]*T + (B1[2] + B1[1]*T) * P
    Df = D0[2] + D0[1]*P

    # Final sound speed
    cs = Cw + A*S + B*S^(1.5) + Df*S^2
    return cs
end
