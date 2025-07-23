using ..Utils: localtime
using Printf

"""
Reads a single-beam Lowrance SL2 sonar file (v.2) into memory (SL2 parser)

# Arguments
- `fname::String`: SL2 file filename

# Returns
- `P::Vector{Matrix{Float64}}`: cell array with ping matrices (rows: ping no., columns: echo sample)
- `Q::Vector{Vector{NamedTuple}}`: cell array with transducer header info structs
- `G::Vector{NamedTuple}`: GPS + time data (time=-1: no data)

A 162-byte file size is exactly what your function would create:

    2 bytes (format UInt16)

    2 bytes (version UInt16)

    4 bytes (datagram length UInt32) = 140 + 10 = 150

    140 bytes (header)

    10 bytes (echo data)

    4 bytes (trailing length UInt32)
"""
function lowranceSL2(filename::String)  
    # Constants
    Sm = 6356752.3142  # Earth radius
    dg = 180 / π
    temperature = 0.0
    soundSpeed = 1500.0
    P = Vector{Matrix{UInt8}}(undef,1 )          # Echo samples
    Q = Vector{Vector{LowranceSampleSL2}}(undef, 1)      # Transducer metadata
    G = Vector{Vector{GPSDataLowrance}}(undef, 1)        # GPS and time
    nchannels = UInt8[]                          # Seen channels
    npings = 0                                   # Ping counters per channel (unused here but initialized)
    lpings = Int[]                               # Last ping seen (unused here but initialized)
    record_num = 0

    Q[1] = Vector{LowranceSampleSL2}()
    G[1] = Vector{GPSDataLowrance}()
    
    open(filename, "r") do f
        while !eof(f)
            npings += 1
            pos_start = position(f)
            # Read SL2 packet
            slF     = read(f, UInt16)
            slV     = read(f, UInt16)
            dg_len  = read(f, UInt32)
            header  = read(f, 140)
            echo    = read(f, 10)          # Adjust if echo length is dynamic
            trail   = read(f, UInt32)
            # Determine channel
            channel = header[29]
            if !(channel in nchannels)
                push!(nchannels, channel)
                push!(lpings, 0)
            end

            n = reinterpret(UInt32, hd[33:36])[1] + 1
            chidx = findfirst(==(channel), nchannels)

            # Extract fields
            sec = reinterpret(UInt32, header[5:8])[1]
            sec = Float64(sec)
            lat = reinterpret(Float32, header[53:56])[1]
            lon = reinterpret(Float32, header[57:60])[1]
            depth_offset = reinterpret(Float32, header[109:112])[1]
            ping = reinterpret(UInt32, header[113:116])[1]
            freq = reinterpret(Float32, header[137:140])[1]

            l = header[31]+256*header[2]
            lpings[chidx] = max(l, lpings[chidx])
            
            P[1] = zeros(32, l)
            P[1][npings, 1:l] = 1:l
            # Push parsed values
            push!(Q[1], LowranceSampleSL2(ping, depth_offset, freq, channel))
            push!(G[1], GPSDataLowrance(
                sec == 0 ? -1.0 : localtime(sec), lat, lon
            ))
            record_num += 1
        end
    end

    return P, Q, G
end
