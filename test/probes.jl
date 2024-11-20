using Revise
# includet("../src/EA400Load.jl")

# using .Load


"""
This module contains all the neccesary functions to load the data the proceeds from the echosound <EA400
"""

abstract type AbstractDatagram end

# Define a structure for the header object
struct Header
    surveyName::String
    transectName::String
    sounderName::String
    version::String
    transducerCount::Int32
end


# Define a structure for the transducer
struct Transducer
    channelId::String
    beamType::Int32
    frequency::Float32
    gain::Float32
    equivalentBeamAngle::Float32
    beamAlongship::Float32
    beamAthwartship::Float32
    sensitivityAlongship::Float32
    sensitivityAthwartship::Float32
    offsetAlongship::Float32
    offsetAthwartship::Float32
    posX::Float32
    posY::Float32
    posZ::Float32
    dirX::Float32
    dirY::Float32
    dirZ::Float32
    pulseLengthTable::Vector{Float32}
    gainTable::Vector{Float32}
    saCorrectionTable::Vector{Float32}
    gptSoftwareVersion::String
end

# Define a structure for the sample
struct Sample
    channel::Int16
    mode::Int16
    transducerDepth::Float32
    frequency::Float32
    transmitPower::Float32
    pulseLength::Float32
    bandWidth::Float32
    sampleInterval::Float32
    soundVelocity::Float32
    absorptionCoefficient::Float32
    heave::Float32
    roll::Float32
    pitch::Float32
    temperature::Float32
    offset::Int32
    count::Int32
end

# Define a structure for the data
struct Data
    power::Vector{Float64}
    angleAthwartship::Vector{Float64}
    angleAlongship::Vector{Float64}
end


# Define a structure for GPS data
mutable struct GPSData
    time::Float64
    latitude::Float64
    longitude::Float64
end

# Define a structure for the configuration datagram
struct CON0 <: AbstractDatagram
    header::Header
    transducer::Vector{Transducer}
    
end

# Define a structure for the tag datagram
struct TAG0 <: AbstractDatagram
    gpsData::Vector{GPSData}
end

# Define a structure for the NMEA datagram
struct NME0 <: AbstractDatagram
    nmea:: String
    
end

# Define a structure for the raw datagram
struct RAW0 <: AbstractDatagram
    sample::Sample
    data::Data
    
end


# This are the differents types contained in an EA400 sound
const DatagramTypeMap = Dict(
    "CON0" => CON0,
    "NME0" => NME0,
    "TAG0" => TAG0,
    "RAW0" => RAW0
    # Add more mappings as needed
)


function fmt_simradRAW(fname::String)
    # Open file
    sonarFile = open(fname, "r")

    # Initial setup
    max_channels = 0
    max_counts = []
    nPings = nothing
    lPS = gpsRead("")
    preallocate_pings = []
    
    for pass in 1:2
        seekstart(sonarFile)  # Go to the beginning of the file 
        preallocate_pings = nPings  
        nPings = []
        if pass == 1
            # Main processing logic for the first pass
            while !eof(sonarFile) # Loop until the end of the file
                dgrm = readDatagram(sonarFile)
                if dgrm !== nothing
                    max_channels, max_counts, nPings = processFirstPass(dgrm, max_channels, max_counts, nPings)
                end
            end
        else
            # Initialize variables needed for the second pass here
            global P = [Matrix{Float64}(undef, preallocate_pings[i], max_counts[i]) for i in 1:max_channels]
            global HS = [Vector{Sample}(undef, preallocate_pings[i]) for i in 1:max_channels]
            global PS = [Vector{GPSData}(undef, preallocate_pings[i]) for i in 1:max_channels]
            nPings = zeros(Int,max_channels)
            
            while !eof(sonarFile) # Loop until the end of the file
                dgrm = readDatagram(sonarFile)
                P, HS, PS, lPS, nPings, max_counts = processSecondPass(dgrm, P, HS, PS, lPS, nPings, max_counts)
            end
            
        end  # while !eof(sonarFile)
    end  # for pass in 1:2
    close(sonarFile)
    # return max_channels, max_counts, nPings
    return P, HS, PS
end

function processFirstPass(dgrm, max_channels, max_counts, nPings)
    if isa(dgrm, RAW0)
        # sample header
        ch = dgrm.sample.channel

        if ch > max_channels
            push!(max_counts, 0)
            push!(nPings, 0)
            max_channels = ch
        end

        nPings[ch] += 1
        max_counts[ch] = max(max_counts[ch], dgrm.sample.count)
    end
    return max_channels, max_counts, nPings
end

function processSecondPass(dgrm, P, HS, PS, lPS, nPings, max_counts)
    if isa(dgrm, NME0)
        llPS = gpsRead(dgrm.nmea)
        if llPS.time >= 0
            lPS = llPS
        end
    
    elseif isa(dgrm, RAW0)
        # channels
        ch = dgrm.sample.channel

        nPings[ch] += 1

        # header and last GPS data
        HS[ch][nPings[ch]] = dgrm.sample
        PS[ch][nPings[ch]] = lPS

        # sample power
        if hasfield(typeof(dgrm.data), :power)
            ll = min(dgrm.sample.count, length(dgrm.data.power))
            P[ch][nPings[ch], 1:ll] = dgrm.data.power[1:ll]
        end
    end
    return P, HS, PS, lPS, nPings, max_counts
end

function readDatagram(sonarFile)
    
    length = read(sonarFile, Int32)
    
    # Check for EOF or zero length
    if eof(sonarFile) || length == 0
        dgrm.type = "END0"
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
        # @warn("Unsupported datagram type: $type")
        read(sonarFile, length - 3*4)
        read(sonarFile, Int32)
        return nothing
    else
        datagram = handle_datagram(julia_type, length, sonarFile)
        read(sonarFile, Int32)
        return datagram
    end
end

function gpsRead(nmea::String)
    # Default values for when no or unrecognized NMEA type is encountered
    defaultTime = -1.0
    defaultLatitude = 0.0
    defaultLongitude = 0.0

    # Initialize variables to hold the parsed data
    parsedTime = defaultTime
    parsedLatitude = defaultLatitude
    parsedLongitude = defaultLongitude

    if length(nmea) > 5
        ss = split(nmea[4:end], ',')
        messageType = ss[1]

        # Helper Functions for parsing
        parseTime(timeStr) = parse(Float64, timeStr[1:2]) + parse(Float64, timeStr[3:4])/60 + parse(Float64, timeStr[5:6])/3600
        parseLatitude(latStr, dir) = adjustSign(parse(Float64, latStr[1:2]) + parse(Float64, latStr[3:end])/60, dir == 'S')
        parseLongitude(longStr, dir) = adjustSign(parse(Float64, longStr[1:3]) + parse(Float64, longStr[4:end])/60, dir == 'W')
        adjustSign(val, condition) = condition ? -val : val

        # Check message type and parse accordingly
        if messageType == "GGA"
            parsedTime = parseTime(ss[2])
            parsedLatitude = parseLatitude(ss[3], ss[4])
            parsedLongitude = parseLongitude(ss[5], ss[6])
        elseif messageType == "GLL"
            parsedLatitude = parseLatitude(ss[2], ss[3])
            parsedLongitude = parseLongitude(ss[4], ss[5])
            parsedTime = length(ss) > 6 ? parseTime(ss[6]) : defaultTime
        elseif messageType == "GNS"
            parsedTime = parseTime(ss[2])
            parsedLatitude = parseLatitude(ss[3], ss[4])
            parsedLongitude = parseLongitude(ss[5], ss[6])
        elseif messageType == "GXA"
            parsedTime = parseTime(ss[2])
            parsedLatitude = parseLatitude(ss[3], ss[4])
            parsedLongitude = parseLongitude(ss[5], ss[6])
        else
            # If the message type is not recognized, the defaults are already set
        end
    end

    # Create the GPSData struct with the parsed or default values
    lPS = GPSData(parsedTime, parsedLatitude, parsedLongitude)
    return lPS
end


# Generic handler (fallback)
function handle_datagram(::Type{T}, length::Int32, sonarFile::IO) where T <: AbstractDatagram
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
    
    sample = Sample(channel, mode, transducerDepth, frequency,
                    transmitPower, pulseLength, bandWidth, sampleInterval,
                    soundVelocity, absorptionCoefficient, heave, roll, pitch,
                    temperature, offset, count)
    
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

fname = "./data/L0044-D20140719-T133114-EA400.raw"
PS, HS, CS = fmt_simradRAW(fname)
# max_channels, max_counts, Pings = fmt_simradRAW(fname)



# Example matrix of pings (rows represent pings, columns represent different data for each ping)
pings_matrix = rand(10, 5)  # 10 pings, 5 data points each, for example

# Example array of GPS data corresponding to each ping
gps_data = rand(-10:10, 10)  # 10 GPS data points, some are <= 0

# Create a logical index for rows where GPS data is greater than zero
index = gps_data .> 0

# Filter the matrix to keep only rows where GPS data is greater than zero
filtered_pings_matrix = pings_matrix[index, :]


A = [1.; 2.; 3.; 4.]

add1!(A::Vector{Float64}) = A.+=1

add1!(A)

A = [1, 2, 3, 4, 5, 6]

diff(A)