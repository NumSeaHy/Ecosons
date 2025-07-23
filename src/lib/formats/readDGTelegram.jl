include("DataTypesSimradDG.jl")

"""
Reads one Simrad DG telegram from the IO stream `f`.
Returns a DGTelegram or a Dict with minimal info on EOF.
"""
function readDGTelegram(f::IO)
    if eof(f)
        return Dict(:length => 0, :type => "END0")
    end

    # Read telegram length (Int32)
    n = read(f, Int32)
    if n == 0
        return Dict(:length => 0, :type => "END0")
    end

    # Read telegram type (2 bytes)
    ttype_bytes = read(f, 2)
    ttype = String(ttype_bytes)

    # Skip 1 padding byte
    read(f, UInt8)

    # Read telegram time string (8 bytes)
    tme_bytes = read(f, 8)
    tme = String(tme_bytes)

    # Skip 1 padding byte
    read(f, UInt8)

    # Parse telegram time: HHMMSShh -> fractional hours
    h = parse(Int, tme[1:2])
    m = parse(Int, tme[3:4])
    s = parse(Int, tme[5:6])
    hs = parse(Int, tme[7:8])
    time = h + m/60 + s/3600 + hs/360000

    payload_len = n - 12  # Header is 12 bytes

    data = Dict{Symbol, Any}()

    # Helper function to skip payload
    function skip_payload()
        read(f, payload_len)
    end

    # Parse payload by telegram type
    if ttype in ["PR", "PE", "CS", "ST", "LL", "A1", "H1"]
        skip_payload()

    elseif ttype == "GL"
        glc_bytes = read(f, payload_len)
        glc = String(glc_bytes)
        m = match(r"([\d.]+),([NS]),([\d.]+),([EW])", glc)
        if m !== nothing
            lat = parse(Float64, m.captures[1])
            lon = parse(Float64, m.captures[3])
            if m.captures[2] == "S"
                lat = -lat
            end
            if m.captures[4] == "W"
                lon = -lon
            end
            data[:latitude] = lat
            data[:longitude] = lon
        else
            data[:latitude] = NaN
            data[:longitude] = NaN
        end

    elseif ttype == "D1"
        dph = read(f, Float32)
        ss = read(f, Float32)
        channel = read(f, Int32)
        read(f, Float32)  # dummy
        data[:depth] = dph
        data[:Ss] = ss
        data[:channel] = channel

    elseif ttype == "E1"
        ntr = read(f, Int32)
        a = read!(f, Vector{Float32}(undef, 5 * ntr))
        # Here, a can be split into fields as needed
        data[:sat] = a

    elseif ttype == "S1"
        nly = read(f, Int32)
        a = read!(f, Vector{Float32}(undef, 3 * nly))
        data[:raw] = a

    elseif ttype == "Q1"
        tvg = read(f, Int32)
        dph = read(f, Float32)
        dpu = read(f, Float32)
        dpb = read(f, Float32)
        dpc = read(f, Int32)
        dbu = read(f, Float32)
        dbb = read(f, Float32)
        dbc = read(f, Int32)
        n_bins = (payload_len - 8 * 4) ÷ 2
        bins = read!(f, Vector{Int16}(undef, n_bins))

        data[:TVG] = 20 + tvg * 20
        data[:depth] = dph
        data[:pelagicUpper] = dpu
        data[:pelagicLower] = dpb
        data[:pelagicCount] = dpc
        data[:bottomUpper] = dbu
        data[:bottomLower] = dbb
        data[:bottomCount] = dbc
        data[:power] = bins

    elseif ttype == "B1"
        a = read!(f, Vector{Int8}(undef, payload_len))
        aaln = a[1:2:end]
        aath = a[2:2:end]
        data[:angleAthwartship] = 180 .* aaln ./ 64
        data[:angleAlongship] = 180 .* aath ./ 64

    elseif ttype == "W1"
        wbin = read!(f, Vector{Int16}(undef, payload_len ÷ 2))
        data[:power] = 10 * log10(2) .* wbin ./ 256

    elseif ttype == "V1"
        sbin = read!(f, Vector{Int16}(undef, payload_len ÷ 2))
        data[:cpower] = sbin

    elseif ttype == "P1"
        pbin = read!(f, Vector{Int16}(undef, payload_len ÷ 2))
        data[:cpower] = pbin

    elseif ttype == "VL"
        ymd_bytes = read(f, 6)
        ymd = String(ymd_bytes)
        read(f, UInt8)  # padding byte
        dist = read(f, Float32)
        data[:date] = ymd
        data[:distance] = dist

    else
        # Unknown telegram type — skip payload
        skip_payload()
    end

    return DGTelegram(n, ttype, time, data)
end