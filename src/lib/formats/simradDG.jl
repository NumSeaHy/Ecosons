include("readDGTelegram.jl")

function ifthel(a::Dict, b::Symbol, c)
    return haskey(a, b) ? a[b] : c
end

function simradDG(fname::String; ops::Union{HSInfo, Nothing}=nothing)
    # Initialize
    max_channels = 1
    P = Vector{Matrix{Float64}}(undef, max_channels)
    At = Vector{Matrix{Float64}}(undef, max_channels)
    Al = Vector{Matrix{Float64}}(undef, max_channels)
    HS = Vector{Vector{HSInfo}}(undef, max_channels)
    PS = Vector{Vector{GPSDataDG}}(undef, max_channels)

    function sonarSettings(ops)
        pulseLength = ops === nothing ? 0.3e-3 : ops.pulseLength
        sampleInterval = ops === nothing ? pulseLength / 4 : ops.sampleInterval
        return HSInfo(
            1, 0.0, 0.0, 0.0, 0.0,
            ops === nothing ? 200_000 : ops.frequency,
            ops === nothing ? 125.0 : ops.transmitPower,
            pulseLength,
            ops === nothing ? NaN : ops.bandWidth,
            sampleInterval,
            ops === nothing ? 1500.0 : ops.soundVelocity,
            ops === nothing ? 10.0 : ops.absorptionCoefficient,
            ops === nothing ? NaN : ops.temperature,
            0, 0
        )
    end

    lHS = sonarSettings(ops)
    lPS = GPSDataDG(-1.0, NaN, NaN)

    request_As = true
    max_counts = [0]
    nPings = zeros(Int, max_channels)
    nPingsA = zeros(Int, max_channels)

    sonarFile = open(fname, "r")
    pass = 0
    while pass < 2
        pass += 1
        seek(sonarFile, 0)
        while !eof(sonarFile)
            dgrm = readDGTelegram(sonarFile)
            println("Received telegram of type: ", typeof(dgrm))

            if !(dgrm isa DGTelegram)
                println("→ Skipping unknown telegram type: ", typeof(dgrm))
                continue
            end

            ttype = dgrm.type
            println("→ DGTelegram subtype: ", ttype)

            if pass == 1
                if ttype == "W1"
                    println("→ PASS 1 — W1 telegram (", typeof(dgrm), "), data keys: ", keys(dgrm.data))
                    ch = 1
                    nPings[ch] += 1
                    l = length(dgrm.data[:power])
                    println("→ W1 length: ", l)
                    if l > max_counts[ch]
                        max_counts[ch] = l
                        if !isnothing(ops) && haskey(ops, :maxDepth)
                            sv = get(ops, :soundVelocity, 1500.0)
                            lHS.sampleInterval = ops[:maxDepth] / (l * sv)
                            if !haskey(ops, :pulseLength)
                                lHS.pulseLength = 4 * lHS.sampleInterval
                            end
                            println("→ Updated sampleInterval: ", lHS.sampleInterval)
                        end
                    end
                end
            else
                if ttype == "GL"
                    println("→ PASS 2 — GL telegram (", typeof(dgrm), ")")
                    println("→ GPS lat=$(dgrm.data[:latitude]), lon=$(dgrm.data[:longitude])")
                    lPS = GPSDataDG(dgrm.time, dgrm.data[:latitude], dgrm.data[:longitude])
                    println("→ Created GPSDataDG: ", lPS)
                elseif ttype == "W1"
                    println("→ PASS 2 — W1 telegram (", typeof(dgrm), "), inserting into echo matrix")
                    ch = 1
                    l = length(dgrm.data[:power])
                    P[ch][nPings[ch], 1:l] = dgrm.data[:power]
                    lHS.offset = 0
                    lHS.count = l
                    HS[ch][nPings[ch]] = lHS
                    PS[ch][nPings[ch]] = GPSDataDG(dgrm.time, lPS.latitude, lPS.longitude)
                    println("→ Echo power stored, count=", l)
                elseif ttype == "B1"
                    println("→ PASS 2 — B1 telegram (", typeof(dgrm), "), processing angles")
                    ch = 1
                    nPingsA[ch] += 1
                    if request_As
                        l = length(dgrm.data[:angleAlongship])
                        Al[ch][nPingsA[ch], 1:l] = dgrm.data[:angleAlongship]
                        At[ch][nPingsA[ch], 1:l] = dgrm.data[:angleAthwartship]
                        println("→ Angles stored: length=", l)
                    end
                else
                    println("→ PASS 2 — Unhandled telegram type: ", ttype)
                end
            end
        end

        if pass == 1
            for ch in 1:max_channels
                rows = nPings[ch]
                cols = max_counts[ch]
                P[ch] = fill(NaN, rows, cols)
                if request_As
                    Al[ch] = fill(NaN, rows, cols)
                    At[ch] = fill(NaN, rows, cols)
                end
                HS[ch] = Vector{HSInfo}(undef, rows)
                PS[ch] = Vector{GPSDataDG}(undef, rows)
                println("→ Initialized matrices for ch=$ch: rows=$rows, cols=$cols")
            end
        end
    end

    close(sonarFile)
    println("Final PS: ", PS)
    println(PS[1])
    return P, At, Al, HS, PS
end
