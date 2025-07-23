module DataTypesLowrance

mutable struct LowranceSampleSL1
    channel::Int
    frequency::Int            # Hz, usual carrier frequency
    transmitPower::Int        # placeholder, unknown actual emission power
    sampleInterval::Float64   # bin length
    pulseLength::Float64      # 4 * bin length
    soundVelocity::Float64
    absorptionCoefficient::Float64
    temperature::Float64
    count::Int
    _depth::Float64
    _tobDepth::Float64
    _schem::Any               # keep `Any` if unknown type; specify if known
end

mutable struct LowranceSampleSL2
    ping::UInt32
    offset::Float32
    freq::Float32
    channel::UInt8
end

mutable struct GPSDataLowrance
    time:: Float64
    latitude::Float32
    longitude::Float32
    GPSDataLowrance() = new(-1.0, 0.0, 0.0)  # Constructor sets default values
    GPSDataLowrance(t::Float64, lat::Float32, lon::Float32) = new(t, lat, lon)
end 

mutable struct SonarDataLowrance
    name::String
    P::Matrix{UInt8} 
    Q::Union{Vector{LowranceSampleSL1},
     Vector{LowranceSampleSL2}}
    G::Vector{
        GPSDataLowrance
        }
    R::Union{
        Nothing,
         Vector{Int}}
end

SonarDataLowrance(name::String, P::Matrix{UInt8}, Q::Vector{LowranceSampleSL1}, G::Vector{GPSDataLowrance}) = 
    SonarDataLowrance(name, P, Q, G, nothing)

SonarDataLowrance(name::String, P::Matrix{UInt8}, Q::Vector{LowranceSampleSL2}, G::Vector{GPSDataLowrance}) = 
    SonarDataLowrance(name, P, Q, G, nothing)

export LowranceSampleSL1, LowranceSampleSL2, GPSDataLowrance, SonarDataLowrance

end