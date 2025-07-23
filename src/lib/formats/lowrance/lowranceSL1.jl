include("gpsLowrance.jl")

using ..DataTypes

"""
Reads a single-beam Lowrance SL1 sonar file into memory (SL1 parser)
fname: RAW file filename
"""
function lowranceSL1(fname::String)
    # Initialize returned values
    P = Vector{Matrix{UInt8}}(undef, 1)
    HS = Vector{Vector{LowranceSampleSL1}}(undef, 1)
    PS = Vector{Vector{GPSDataLowrance}}(undef,1)
    
    # Get file info and open file
    s = stat(fname)
    ftime = Dates.unix2datetime(s.mtime)
    
    sonarFile = open(fname, "r")
    # compute file length
    seekend(sonarFile)
    sonarFileSize = position(sonarFile)
    seekstart(sonarFile)
    
    # Read number of available channels (int32)
    nchan = read(sonarFile, Int32)
    
    # Read block size: 3 bytes combined as uint8
    b1 = read(sonarFile, UInt8)
    b2 = read(sonarFile, UInt8)
    b3 = read(sonarFile, UInt8)
    blksz = UInt32(b1) + 256 * UInt32(b2) + 65536 * UInt32(b3)
    
    # Compression scheme
    schem = read(sonarFile, UInt8)
    
    # Number of pings in file
    npings = floor(Int, sonarFileSize / blksz)
    
    # Reserve space for P
    # P: npings x (blksz - 3*4) UInt8 matrix
    bin_len = Int(blksz) - 3*4

    # Initialize variables
    P[1] = zeros(npings, bin_len)
    HS[1] = Vector{LowranceSampleSL1}()
    PS[1] = Vector{GPSDataLowrance}()
    X = NaN
    Y = NaN
    T = 0
    temperature = 0
    soundSpeed = 1500.0
    
    T0 = (Dates.hour(ftime) + Dates.minute(ftime)/60 +
         Dates.second(ftime)/3600 + Dates.millisecond(ftime) / 3.6e6
         ) # decimal hour
    
    for n in 1:npings
        vmask = read(sonarFile, UInt32)
        
        lowerLimit = 0.3048 * read(sonarFile, Float32)  # ft to m
        depth = 0.3048 * read(sonarFile, Float32)
        
        hdrsz = 3 * 4
        
        # Process fields based on bitmask
        if (vmask & 0x00080000) != 0
            hdrsz += 4
            upperLimit = 0.3048 * read(sonarFile, Float32)
        else
            upperLimit = 0.0
        end
        
        if (vmask & 0x00100000) != 0
            hdrsz += 4
            temperature = 0.3048 * read(sonarFile, Float32)
        else
            temperature = 0.0
        end
        
        if (vmask & 0x00800000) != 0
            hdrsz += 4
            waterSpeed = 0.514444 * read(sonarFile, Float32)
        else
            waterSpeed = NaN
        end
        
        if (vmask & 0x01000000) != 0
            hdrsz += 4
            Y = read(sonarFile, UInt32)
            hdrsz += 4
            X = read(sonarFile, UInt32)
        end
        
        if (vmask & 0x04000000) != 0
            hdrsz += 4
            surfaceDepth = 0.3048 * read(sonarFile, Float32)
        end
        
        if (vmask & 0x08000000) != 0
            hdrsz += 4
            topOfBottomDepth = 0.3048 * read(sonarFile, Float32)
        else
            topOfBottomDepth = NaN
        end
        
        if (vmask & 0x00200000) != 0
            hdrsz += 4
            temperature2 = read(sonarFile, Float32)
        end
        
        if (vmask & 0x00400000) != 0
            hdrsz += 4
            temperature3 = read(sonarFile, Float32)
        end
        
        if (vmask & 0x20000000) != 0
            hdrsz += 4
            T = read(sonarFile, UInt32)
        end
        
        if (vmask & 0x40000000) != 0
            hdrsz += 4
            gps_speed = read(sonarFile, Float32)
            hdrsz += 4
            heading = read(sonarFile, Float32)
        end
        
        if (vmask & 0x00040000) != 0
            hdrsz += 4
            altitude = read(sonarFile, Float32)
        end
        
        if (vmask & 0x10000000) != 0
            hdrsz += 4
            packetsize = read(sonarFile, UInt16)
        end
        
        # Load ping
        if schem == 0
            read!(sonarFile, view(P[1], n, 1:(blksz - hdrsz)))
        else
            # For unknown compression schemes, skip the block and fill with NaNs
            seek(sonarFile, position(sonarFile) + blksz - hdrsz)
            P[1][n, 1:(blksz - hdrsz)] .= 0xFF # Use 0xFF as a placeholder for NaN equivalent in UInt8
        end
        
        # Calculate bin length (in meters)
        binLength = 2 * lowerLimit / (soundSpeed * (blksz - hdrsz))
        
        # Create structure with relevant info
        samp = LowranceSampleSL1(nchan, 200_000, 1000, binLength, 4 * binLength, soundSpeed, 
        0.0, temperature, n, depth, topOfBottomDepth, schem)
        push!(HS[1], samp)
        push!(PS[1], gpsLowrance(X, Y, T))
    end
    
    # Adjust time in hours
    T0 -= PS[1][end].time / 3600
    for n in 1:npings
        PS[1][n].time = PS[1][n].time / 3600 + T0
    end
    
    # Return data as arrays in a tuple
    return P, HS, PS
end