






function phaseAngle(W, bt)
    sW = size(W)
    L = prod(sW[1:end-1])
    paAt = reshape(zeros(L), sW[1:end-1]...)
    paAl = reshape(zeros(L), sW[1:end-1]...)

    if bt == 1  # Transducers having four sectors: Starboard Aft, Port Aft, Port Fore, Starboard Fore
        paAl .= angle.(conj.(W[:,1] .+ W[:,2]) .* (W[:,3] .+ W[:,4]))
        paAt .= angle.(conj.(W[:,2] .+ W[:,3]) .* (W[:,1] .+ W[:,4]))
    elseif bt == 17  # Transducers having three sectors: Starboard Aft, Port Aft, Forward
        paAl .= (angle.(conj.(W[:,1]) .* W[:,3]) .+ angle.(conj.(W[:,2]) .* W[:,3])) ./ sqrt(3)
        paAt .= (angle.(conj.(W[:,2]) .* W[:,3]) .- angle.(conj.(W[:,1]) .* W[:,3]))
    elseif bt in [49, 65, 81]  # Transducers having three sectors and a centre element: Starboard Aft, Port Aft, Forward, Centre
        paAl .= (angle.(conj.(W[:,1] .+ W[:,4]) .* (W[:,3] .+ W[:,4])) .+ angle.(conj.(W[:,2] .+ W[:,4]) .* (W[:,3] .+ W[:,4]))) ./ sqrt(3)
        paAt .= (angle.(conj.(W[:,2] .+ W[:,4]) .* (W[:,3] .+ W[:,4])) .- angle.(conj.(W[:,1] .+ W[:,4]) .* (W[:,3] .+ W[:,4])))
    elseif bt == 97  # Transducers having four sectors: Fore Starboard, Aft Port, Aft starboard, Fore Port
        paAt .= angle.(conj.(W[:,2]) .* W[:,1])
        paAl .= angle.(conj.(W[:,4]) .* W[:,3])
    end

    return paAt, paAl
end


# Sound attenuation calculation in Julia
function alphaAinslieMcColm(f, T, S, D, pH)
    # Convert units to standard used in formula
    f = f / 1000  # Convert frequency to kHz
    D = D / 1000  # Convert depth to km

    # Boric acid contribution
    A1 = 0.106 * exp((pH - 8) / 0.56)
    P1 = 1
    f1 = 0.78 * sqrt(S / 35) * exp(T / 26)
    Boric = (A1 * P1 * f1 * f^2) / (f^2 + f1^2)

    # MgSO4 contribution
    A2 = 0.52 * (S / 35) * (1 + T / 43)
    P2 = exp(-D / 6)
    f2 = 42 * exp(T / 17)
    MgSO4 = (A2 * P2 * f2 * f^2) / (f^2 + f2^2)

    # Pure water contribution
    A3 = 0.00049 * exp(-(T / 27 + D / 17))
    P3 = 1
    H2O = A3 * P3 * f^2

    # Total absorption (dB/km)
    alpha = Boric + MgSO4 + H2O

    return alpha
end
