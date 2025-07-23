include("parseXML.jl")
using Base: read, seek
using ..DataTypes
function readRawDatagram(sonarFile)
    
    length = read(sonarFile, Int32)
    
    # Check for EOF or zero length
    if eof(sonarFile) || length == 0
        type = "END0"
        return 
    end
    
    type  = String(read(sonarFile, 4))
    # date1 = read(sonarFile, Int32)
    # date2 = read(sonarFile, Int32)
    # date = [date2, date1] # Change the order to get the same result as Noela in Octave
    read(sonarFile, Int32)
    read(sonarFile, Int32)
    
    julia_type = get(DatagramTypeMap, type, nothing)

    if julia_type === nothing
        if 0 < length < 10^6
            try
                read(sonarFile, length - 3*4)
                read(sonarFile, Int32)
            catch e
                @warn "Failed to skip unknown datagram type $type – error: $e"
            end
        else
            seek(sonarFile, position(sonarFile) + 1)
        end
        return nothing
    else
        datagram = handle_datagram(julia_type, length, sonarFile)
        read(sonarFile, Int32)
        return datagram
    end
end

# Generic handler (fallback)
function handle_datagram(::Type{T}, length::Int32, sonarFile::IO) where T <: AbstractDatagramRAW
    error("Handler not implemented for datagram type: $T")
end

function handle_datagram(::Type{TAG0}, length::Int32, sonarFile::IO)
    # Implement specific logic for handling TAG0 datagrams
    aux = Int(length - 3*4)
    text = rstrip(String(read(sonarFile, aux)), '\0')
    if length(text) > 80
        text = text[1:80]
    end
    
    return TAG0(text)
end

# Specific handler for CON0
function handle_datagram(::Type{CON0}, length::Int32, sonarFile::IO)
    # Creation of the header object
    
    surveyName = rstrip(String(read(sonarFile, 128)), '\0')
    transectName = rstrip(String(read(sonarFile, 128)), '\0')
    sounderName = rstrip(String(read(sonarFile, 128)), '\0')
    version = rstrip(String(read(sonarFile, 30)), '\0')
    read(sonarFile, 98) # Skip 98 bytes
    transducerCount = read(sonarFile, Int32)
    
    header = Header(surveyName, transectName, sounderName, version, transducerCount)
    
    transducers = Vector{Transducer}()
    
    for _ in 1:header.transducerCount
        
        channelId = rstrip(String(read(sonarFile, 128)), '\0')  # Read 128 bytes and convert to String, then remove null characters
        beamType = read(sonarFile, Int32)
        frequency = read(sonarFile, Float32)
        gain = read(sonarFile, Float32)
        equivalentBeamAngle = read(sonarFile, Float32)
        beamAlongship = read(sonarFile, Float32)
        beamAthwartship = read(sonarFile, Float32)
        sensitivityAlongship = read(sonarFile, Float32)
        sensitivityAthwartship = read(sonarFile, Float32)
        offsetAlongship = read(sonarFile, Float32)
        offsetAthwartship = read(sonarFile, Float32)
        posX = read(sonarFile, Float32)
        posY = read(sonarFile, Float32)
        posZ = read(sonarFile, Float32)
        dirX = read(sonarFile, Float32)
        dirY = read(sonarFile, Float32)
        dirZ = read(sonarFile, Float32)
        read(sonarFile, 8)  # Skip 8 bytes
        pulseLengthTable = read(sonarFile, 5)
        read(sonarFile, 8)  # Skip 8 bytes
        gainTable = read(sonarFile, 5)
        read(sonarFile, 8)  # Skip 8 bytes
        saCorrectionTable = read(sonarFile, 5)
        read(sonarFile, 8)  # Skip 8 bytes
        gptSoftwareVersion = rstrip(String(read(sonarFile, 16)), '\0')  # Read 16 bytes and convert to String, then remove null characters
        read(sonarFile, 65)  # Skip 20 bytes in Noela's code, but 65 bytes in this code, I don't know why but.... it works...

        transducer = Transducer(channelId, beamType, frequency, gain, equivalentBeamAngle,
                                beamAlongship, beamAthwartship, sensitivityAlongship, sensitivityAthwartship,
                                offsetAlongship, offsetAthwartship, posX, posY, posZ, dirX, dirY, dirZ, pulseLengthTable,
                                gainTable, saCorrectionTable, gptSoftwareVersion)

        push!(transducers, transducer)
    end

    return CON0(header, transducers)
end

# Specific handler for NME0
function handle_datagram(::Type{NME0}, length::Int32, sonarFile::IO)
    dataLength = length - 3 * 4
    # Read the data and convert it to a string
    nmea = rstrip(String(read(sonarFile, dataLength)),'\0')
    # Create and return an NME0Datagram
    return NME0(nmea)
end

# Specific handler for RAW0
function handle_datagram(::Type{RAW0}, length::Int32, sonarFile::IO)
    # Implement specific logic for handling RAW0 datagrams
    channel = read(sonarFile, Int16)
    mode = read(sonarFile, Int16)
    transducerDepth = read(sonarFile, Float32)
    frequency = read(sonarFile, Float32)
    transmitPower = read(sonarFile, Float32)
    pulseLength = read(sonarFile, Float32)
    bandWidth = read(sonarFile, Float32)
    sampleInterval = read(sonarFile, Float32)
    soundVelocity = read(sonarFile, Float32)
    absorptionCoefficient = read(sonarFile, Float32)
    heave = read(sonarFile, Float32)
    roll = read(sonarFile, Float32)
    pitch = read(sonarFile, Float32)
    temperature = read(sonarFile, Float32)
    read(sonarFile, 12)  # Assuming skip is defined to advance the file pointer
    offset = read(sonarFile, Int32)
    count = read(sonarFile, Int32)
    
    sample = Sample(channel=channel, mode = mode, transducerDepth = transducerDepth, frequency = frequency,
                    transmitPower = transmitPower, pulseLength = pulseLength, bandWidth = bandWidth,
                    sampleInterval = sampleInterval, soundVelocity = soundVelocity, absorptionCoefficient = absorptionCoefficient,
                    heave = heave, roll = roll, pitch = pitch, temperature = temperature, offset = offset, count = count)
    
    power = Float64[]    
    if sample.mode == 1 || sample.mode == 3
        # Read the bytes from the file
        bytes = read(sonarFile, 2*sample.count)
        x = reinterpret(Int16, bytes)
        x = collect(x) # 
        
        # Calculate power for each element in `x`
        power = 10 .* log10.(2) .* x ./ 256  # Calculate power for each element in `x`
    end

    angleAthwartship = Float64[]
    angleAlongship = Float64[]
    if sample.mode == 2 || sample.mode == 3
        # Calculate the number of bytes to read
        num_bytes = 2 * sample.count  # 2 bytes for each count
    
        # Read the bytes from the file
        bytes = read(sonarFile, num_bytes)
    
        # Split the bytes into two arrays: one for the most significant byte (MSB) and one for the least significant byte (LSB)
        msb = bytes[1:2:end]  # Takes every other byte starting from the first
        lsb = bytes[2:2:end]  # Takes every other byte starting from the second
    
        # Convert bytes to angles. Julia uses 1-based indexing, and division by 128 is kept for compatibility with the original calculation
        angleAthwartship = 180 .* msb ./ 128
        angleAlongship = 180 .* lsb ./ 128
    
    end
   
    data = Data(power, angleAthwartship, angleAlongship)
    
    return RAW0(sample, data)
end

function handle_datagram(::Type{RAW3}, length::Int32, sonarFile::IO)
    # Read and clean channelId (128 bytes, remove trailing nulls)
    raw_id = read(sonarFile, 128)
    channelId = String(filter(!=(0), raw_id))  

    # Read basic fields
    dataType = read(sonarFile, Int16)  # little-endian by default
    spare    = read(sonarFile, Int16)
    offset   = read(sonarFile, Int32)
    count    = read(sonarFile, Int32)

    sample = Sample(channelId=channelId, dataType=dataType, spare=spare, offset=offset, count=count)

    # Initialize optional outputs
    power = nothing
    angleAthwartship = nothing
    angleAlongship = nothing
    waveform = nothing
   
    # Power (compressed int16)
    if (dataType & 1) != 0
        x = read!(sonarFile, Vector{Int16}(undef, count))
        power = 10 .* log10(2) .* Float64.(x) ./ 256
    end

    # Angles (encoded int8 pairs)
    if (dataType & 2) != 0
        x = read!(sonarFile, Vector{Int8}(undef, 2 * count))
        angleAthwartship = 180 .* Float64.(x[1:2:end]) ./ 128
        angleAlongship   = 180 .* Float64.(x[2:2:end]) ./ 128
    end

    # Waveform: complex float16
    if (dataType & 4) != 0
        cperSample = fld(dataType, 256)
        n = 2 * cperSample * count
        x = read!(sonarFile, Vector{Float16}(undef, n))
        waveform = Matrix(reshape(Complex.(x[1:2:end-1], x[2:2:end]), cperSample, count)')
    end

    # Waveform: complex float32
    if (dataType & 8) != 0
        cperSample = fld(dataType, 256)
        n = 2 * cperSample * count
        x = read!(sonarFile, Vector{Float32}(undef, n))
        waveform = Matrix(reshape(Complex.(x[1:2:end-1], x[2:2:end]), cperSample, count)')
    end

    data = DataRAW3(power, angleAthwartship, angleAlongship, waveform)
    return RAW3(sample, data)
end


function handle_datagram(::Type{FIL1}, length::Int32, sonarFile::IO)
    # Read filter stage
    stage = ntoh(read(sonarFile, Int16))

    # Discard one character (note: spec says 2 chars, commonly only 1 is used)
    read(sonarFile, Char)

    # Read filter type as a Char
    filterType = Char(read(sonarFile, UInt8))

    # Read 128-byte channel ID string, filter out nulls
    raw_id = read(sonarFile, 128)
    channelID = String(filter(!=(0x00), raw_id))

    # Read filter configuration
    noOfCoefficients = read(sonarFile, Int16)
    decimationFactor = read(sonarFile, Int16)

    # Read interleaved real/imag Float32s and convert to complex
    x = Vector{Float32}(undef, 2 * noOfCoefficients)
    read!(sonarFile, x)
    coefficients = complex.(x[1:2:end-1], x[2:2:end])

    # Return structured datagram
    return FIL1(stage, filterType, channelID, noOfCoefficients, decimationFactor, coefficients)
end

function handle_datagram(::Type{XML0}, length::Int32, sonarFile::IO)
    # Calculate payload length by subtracting 3 Int32 fields (usually header elements)
    payload_len = length - 3 * 4  # 3 * sizeof(Int32)

    # Read and decode the UTF-8 encoded XML string
    txt = String(read(sonarFile, payload_len))

    xml, _, _ = parseXML(txt)  # Requires using EzXML or LightXML
    
    return XML0(xml["__name"], get(xml, "__content", nothing),
                        get(xml, "Environment", nothing),
                        get(xml, "PingSequence", nothing),
                        get(xml, "Parameter", nothing),
                        get(xml, "InitialParameter", nothing),
                        get(xml, "Configuration", nothing),
                        )
end
    
function handle_datagram(::Type{MRU0}, length::Int32, sonarFile::IO)
    heave = read(sonarFile, Float32)
    roll = read(sonarFile, Float32)
    pitch = read(sonarFile, Float32)
    heading = read(sonarFile, Float32)
    return MRU0(heave, roll, pitch, heading)
end