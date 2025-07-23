include("gpsRead.jl")
include("readRawDatagram.jl")
include("phaseAngle.jl")
using ..Models:alphaAinslieMcColm
using Statistics

"""
Read and decode a Simrad `.raw` echosounder file.

This function performs a two-pass parsing of a Simrad `.raw` file. It extracts sample power data, waveforms, angles, transducer metadata, and GPS position from sonar datagrams, storing them in structured outputs.

# Arguments
- `fname::String`: Path to a Simrad `.raw` file.

# Returns
A named tuple with the following fields:
- `P::Vector{Matrix{Float64}}`: Power data for each channel, one matrix per channel (ping × sample).
- `W::Vector{Array{ComplexF64,3}}`: Complex waveform data for each channel, if available (ping × sample × waveform component).
- `At::Vector{Matrix{Float64}}`: Angle athwartship, one matrix per channel.
- `Al::Vector{Matrix{Float64}}`: Angle alongship, one matrix per channel.
- `HS::Vector{Vector{Sample}}`: List of `Sample` structures per channel, one per ping.
- `PS::Vector{Vector{GPSDataRAW}}`: GPS data associated with each ping, per channel.
- `lHS::Vector{Dict{Symbol, Any}}`: Metadata for each channel including frequency, bandwidth, sound velocity, transducer depth, etc.
- `lChIds::Vector{String}`: List of channel identifiers as found in the configuration.

# Notes
- The function performs a **first pass** over the file to count pings, identify channels, and determine data structure sizes.
- It then allocates memory for outputs and performs a **second pass** to populate the data structures.
- GPS positions are read from NMEA (`NME0`) datagrams using `gpsRead`.
- Metadata from `XML0`, `MRU0`, and `CON0` datagrams is parsed into dictionaries in `lHS`.
- Supports both narrowband and broadband (waveform) pings, and handles optional angle data if present.

# Dependencies
- `readRawDatagram`: Reads individual sonar telegrams.
- `gpsRead`: Parses NMEA strings into structured GPS data.
- `phaseAngle`: May be used downstream to compute angular data from waveforms.
- `alphaAinslieMcColm`: Computes sound absorption from environmental conditions and frequency.
"""
function simradRAW(fname::String)
    sonarFile = open(fname, "r")

    # First pass variables
    max_channels = 0
    max_counts = Int[]
    nPings = Int[]
    lChIds = String[]
    chTrcvZ = Float64[]
    request_Wf = Int[]
    request_As = BitVector()

    # Temporary holders, allocated later
    W = Vector{Array{ComplexF64,3}}()
    At = Vector{Matrix{Float64}}()
    Al = Vector{Matrix{Float64}}()
    HS = Vector{Vector{Sample}}()
    PS = Vector{Vector{GPSDataRAW}}()
    lPS = gpsRead("")

    # --- First pass ---
    seekstart(sonarFile)
    while !eof(sonarFile)
        dgrm = readRawDatagram(sonarFile)
        if dgrm === nothing
            continue

        elseif isa(dgrm, XML0) && !isnothing(dgrm.configuration)
            tcvs = dgrm.configuration["Transceivers"]["Transceiver"]
            channels = get(tcvs["Channels"], "Channel", [])
            lChIds = [ch["_ChannelID"] for ch in channels]

        elseif isa(dgrm, RAW0) || isa(dgrm, RAW3)
            lH = dgrm.sample
            if !isnothing(lH.channelId)
                ch = findall(x -> x == lH.channelId, lChIds)[1]
                # Optional: you might want to store this in lH.channel or use ch as needed
            else
                ch = dgrm.sample.channel
            end


            while length(max_counts) < ch
                push!(max_counts, 0)
                push!(nPings, 0)
                push!(lChIds, "")
                push!(chTrcvZ, NaN)
                push!(request_Wf, 0)
                push!(request_As, false)
                push!(W, Array{Float64,3}(undef, 0, 0, 0))
                push!(At, Matrix{Float64}(undef, 0, 0))
                push!(Al, Matrix{Float64}(undef, 0, 0))
                push!(HS, Vector{Sample}())
                push!(PS, Vector{GPSDataRAW}())
            end
            max_channels = max(max_channels, ch)
            if !isnothing(dgrm.data)
                if hasfield(typeof(dgrm.data), :waveform) && !isnothing(dgrm.data.waveform)
                    request_Wf[ch] = size(dgrm.data.waveform, 2)
                end
                if !isnothing(dgrm.data.angleAthwartship)
                    request_As[ch] = true
                end
            end 
            nPings[ch] += 1
            max_counts[ch] = max(max_counts[ch], dgrm.sample.count)
            #println(ch)
        end
    end


    # --- Allocate with NaN padding ---
    P = [fill(NaN, nPings[i], max_counts[i]) for i in 1:max_channels]
    #W = [fill(NaN + 0im, nPings[i], max_counts[i], 1) for i in 1:max_channels]
    At = [fill(NaN, nPings[i], max_counts[i]) for i in 1:max_channels]
    Al = [fill(NaN, nPings[i], max_counts[i]) for i in 1:max_channels]

    for ch in 1:max_channels
        resize!(HS[ch], nPings[ch])
        resize!(PS[ch], nPings[ch])
    end

    for ch in 1:max_channels
        if request_Wf[ch] != 0
            P[ch] = fill(NaN, nPings[ch], max_counts[ch])
            W[ch] = fill(NaN + 0im, nPings[ch], max_counts[ch], request_Wf[ch])
        else
            P[ch] = fill(NaN, nPings[ch], max_counts[ch])
        end

        if request_As[ch]
            Al[ch] = fill(NaN, nPings[ch], max_counts[ch])
            At[ch] = fill(NaN, nPings[ch], max_counts[ch])
        end
    end


    nPings2 = zeros(Int, max_channels)
    
    lHS = [Dict{Symbol, Any}() for _ in 1:length(lChIds)]

    # --- Second pass: fill data ---
    seekstart(sonarFile)
    while !eof(sonarFile)
        dgrm = readRawDatagram(sonarFile)
        if dgrm === nothing
            continue
        elseif isa(dgrm, NME0)
            llPS = gpsRead(dgrm.nmea)
            if llPS.time >= 0
                lPS = llPS
            end
        elseif isa(dgrm, RAW0)
            ch = dgrm.sample.channel
            nPings2[ch] += 1
            idx = nPings2[ch]

            HS[ch][idx] = dgrm.sample
            PS[ch][idx] = lPS

            count = dgrm.sample.count

            # Efficient copy power (pad with NaN is already done)
            if hasfield(typeof(dgrm.data), :power) && !isnothing(dgrm.data.power)
                limit = min(count, length(dgrm.data.power))
                @views P[ch][idx, 1:limit] .= dgrm.data.power[1:limit]
            end

            # Waveform: placeholder fill NaN (replace if actual waveform exists)
            # Already NaN filled, skip or fill zeros if preferred
            # @views W[ch][idx, 1:count, 1] .= 0.0
            # Angle athwartship
            if !isempty(dgrm.data.angleAthwartship)
                limit = min(count, length(dgrm.data.angleAthwartship))
                
                @views At[ch][idx, 1:limit] .= dgrm.data.angleAthwartship[1:limit]
            end

            # Angle alongship
            if !isempty(dgrm.data.angleAlongship)
                limit = min(count, length(dgrm.data.angleAlongship))
                @views Al[ch][idx, 1:limit] .= dgrm.data.angleAlongship[1:limit]
            end

        elseif isa(dgrm, XML0)
            if !isnothing(dgrm.InitialParameter)
                chs = dgrm.InitialParameter[:"Channels"]
                for nc in 1:length(chs[:"Channel"])
                    chn = chs[:"Channel"][nc]
                    ch = findall(x -> x == chn[:"_ChannelID"], lChIds)[1]
                    if ch === nothing
                        println("Channel ID not found")
                        continue
                    end
                    lHS[ch][:channel] = ch
                    lHS[ch][:mode] = parse(Float64, chn[:"_ChannelMode"])
                    lHS[ch][:pulseForm] = parse(Float64, chn[:"_PulseForm"])

                    if haskey(chn, :_Slope)
                        lHS[ch][:slope] = parse(Float64, chn[:"_Slope"])
                    else
                        lHS[ch][:slope] = 0.0
                    end

                    if haskey(chn, :"_Frequency") && !isempty(chn[:"_Frequency"])
                        lHS[ch][:frequency] = parse(Float64, chn[:"_Frequency"])
                    elseif haskey(chn, :"_FrequencyStart")
                        lHS[ch][:frequency] = [
                            parse(Float64, chn[:"_FrequencyStart"]),
                            parse(Float64, chn[:"_FrequencyEnd"])
                        ]
                    else
                        lHS[ch][:frequency] = 0.0
                        @warn "Channel datagram without frequency?"
                    end

                    if isa(lHS[ch][:frequency], AbstractVector)
                        lHS[ch][:bandWidth] = abs(lHS[ch][:frequency][1] - lHS[ch][:frequency][2])
                    else
                        lHS[ch][:bandWidth] = 0.0
                    end

                    lHS[ch][:pulseLength] = parse(Float64, chn[:"_PulseDuration"])
                    lHS[ch][:sampleInterval] = parse(Float64, chn[:"_SampleInterval"])
                    lHS[ch][:transmitPower] = parse(Float64, chn[:"_TransmitPower"])
                end
            end
            if !isnothing(dgrm.Parameter)
                chn = dgrm.Parameter[:"Channel"]
                ch = findall(x -> x == chn[:"_ChannelID"], lChIds)[1]
                if ch !== nothing
                    lHS[ch][:channel] = ch
                    lHS[ch][:mode] = parse(Float64, chn[:"_ChannelMode"])
                    lHS[ch][:pulseForm] = parse(Float64, chn[:"_PulseForm"])

                    if haskey(chn, :"_Slope")
                        lHS[ch][:slope] = parse(Float64, chn[:"_Slope"])
                    else
                        lHS[ch][:slope] = 0.0
                    end

                    if haskey(chn, :"_Frequency") && !isempty(chn[:"_Frequency"])
                        lHS[ch][:frequency] = parse(Float64, chn[:"_Frequency"])
                    elseif haskey(chn, :"_FrequencyStart")
                        lHS[ch][:frequency] = [
                            parse(Float64, chn[:"_FrequencyStart"]),
                            parse(Float64, chn[:"_FrequencyEnd"])
                        ]
                    else
                        lHS[ch][:frequency] = 0.0
                        @warn "Channel datagram without frequency?"
                    end

                    if isa(lHS[ch][:frequency], AbstractVector)
                        lHS[ch][:bandWidth] = abs(lHS[ch][:frequency][1] - lHS[ch][:frequency][2])
                    else
                        lHS[ch][:bandWidth] = 0.0
                    end

                    lHS[ch][:pulseLength] = parse(Float64, chn[:"_PulseDuration"])
                    lHS[ch][:sampleInterval] = parse(Float64, chn[:"_SampleInterval"])
                    lHS[ch][:transmitPower] = parse(Float64, chn[:"_TransmitPower"])
                end
            end

            if !isnothing(dgrm.Environment) 
                env = dgrm.Environment
                depth = parse(Float64, env[:"_Depth"])
                soundVelocity = parse(Float64, env[:"_SoundSpeed"])
                temperature = parse(Float64, env[:"_Temperature"])
                salinity = parse(Float64, env[:"_Salinity"])
                acidity = parse(Float64, env[:"_Acidity"])

                for ch in 1:length(lChIds)
                    lHS[ch][:transducerDepth] = depth
                    lHS[ch][:soundVelocity] = soundVelocity
                    lHS[ch][:temperature] = temperature
                    lHS[ch][:salinity] = salinity
                    lHS[ch][:acidity] = acidity

                    if haskey(lHS[ch], :frequency)
                        lHS[ch][:absorptionCoefficient] = alphaAinslieMcColm(
                            lHS[ch][:frequency], temperature, salinity, depth, acidity)
                    else
                        lHS[ch][:absorptionCoefficient] = 0.0
                    end
                end
            end
           
        elseif isa(dgrm, MRU0)
            for ch in 1:length(lChIds)
                lHS[ch][:heave] = dgrm.heave
                lHS[ch][:roll] = dgrm.roll
                lHS[ch][:pitch] = dgrm.pitch
                lHS[ch][:heading] = dgrm.heading
            end 
        elseif isa(dgrm, CON0)
            if length(dgrm.transducer) > 0
                for ch in 1:length(lChIds)
                    lHS[ch][:beamType] = dgrm.transducer[1].beamType
                    lHS[ch][:gain] = dgrm.transducer[1].gain
                    lHS[ch][:equivalentBeamAngle] = dgrm.transducer[1].equivalentBeamAngle
                end
            end
        elseif isa(dgrm, RAW3)
            lH = dgrm.sample

            ch = findall(x -> x == lH.channelId, lChIds)[1]

            for (k, v) in lHS[ch]
                try
                    setproperty!(lH, k, v)
                catch err
                    @warn "Cannot set property $k on lH: $err"
                end
            end

            nPings2[ch] += 1
            HS[ch][nPings2[ch]] = lH
            PS[ch][nPings2[ch]] = lPS
            if !isnothing(dgrm.data.power)
                ll = min(lH.count, length(dgrm.data.power))
                P[ch][nPings2[ch], 1:ll] = dgrm.data.power[1:ll]
                if request_As[ch] && !isnothing(dgrm.data.angleAthwartship) && !isnothing(dgrm.data.angleAlongship)  
                    At[ch][nPings2[ch], 1:ll] = dgrm.data.angleAthwartship[1:ll]
                    Al[ch][nPings2[ch], 1:ll] = dgrm.data.angleAlongship[1:ll]
                end
            end

            if !isnothing(dgrm.data.waveform) && !isnothing(lH.pulseLength) && !isnothing(lH.sampleInterval)
                ll = min(lH.count, size(dgrm.data.waveform, 1))
                W[ch][nPings2[ch], 1:ll, :] = (1000 + 75) / 1000 * dgrm.data.waveform[1:ll, :]
                dTX = round(Int, 2 * lH.pulseLength / lH.sampleInterval)
                wfmean = vec(mean(dgrm.data.waveform[dTX+1:ll, :], dims=2)) 
                P[ch][nPings2[ch], 1:ll - dTX] = 10 .* log10.(0.5 .* abs2.(wfmean) ./ 75)
                if request_As[ch]
                    bt = hasfield(typeof(lH), :beamType) ? lH.beamType : (request_Wf[ch] == 1 ? 0 : request_Wf[ch] == 4 ? 1 : 17)
                    if bt > 0
                        paAt, paAl = phaseAngle(squeeze(W[ch][nPings2[ch], 1:ll, :], 1), bt)
                        At[ch][nPings2[ch], 1:ll - dTX] = paAt[dTX+1:end]
                        Al[ch][nPings2[ch], 1:ll - dTX] = paAl[dTX+1:end]
                    else
                        At[ch][nPings2[ch], 1:ll - dTX] .= NaN
                        Al[ch][nPings2[ch], 1:ll - dTX] .= NaN
                    end
                end
            end

        elseif isa(dgrm, FIL1)
            filt = [Dict(
                :noOfCoefficients => Dict{Int, Int}(),
                :decimationFactor => Dict{Int, Int}()
            ) for _ in 1:length(lChIds)]
            ch = findall(x -> x == dgrm.channelID, lChIds)[1]
            filt[ch][:noOfCoefficients][dgrm.stage] = dgrm.noOfCoefficients
            filt[ch][:decimationFactor][dgrm.stage] = dgrm.decimationFactor
        end       
    end
    close(sonarFile)
    return P, HS, PS, W
end
