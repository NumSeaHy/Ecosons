module DataTypesSimradRaw

abstract type AbstractDatagramRAW end

abstract type AbstractSample end

struct Header
    surveyName::String
    transectName::String
    sounderName::String
    version::String
    transducerCount::Int32
end

mutable struct Sample <: AbstractSample
    channel:: Union{Int16, Nothing}
    channelId:: Union{String, Nothing}
    dataType:: Union{Int16, Nothing}
    spare:: Union{Int16, Nothing}
    heading:: Union{Float32, Nothing}
    acidity:: Union{Float32, Nothing}
    pulseForm:: Union{Float32, Nothing}
    slope:: Union{Float32, Nothing}
    salinity:: Union{Float32, Nothing}
    mode:: Union{Int16, Nothing}
    transducerDepth:: Union{Float32, Nothing}
    frequency:: Union{Float32, Float64, Vector{Float64}, Nothing}
    transmitPower:: Union{Float32, Nothing}
    pulseLength:: Union{Float32, Nothing}
    bandWidth:: Union{Float32, Nothing}
    sampleInterval:: Union{Float32, Nothing}
    soundVelocity:: Union{Float32, Nothing}
    absorptionCoefficient:: Union{Float32, Float64, Vector{Float64}, Nothing}
    heave:: Union{Float32, Nothing}
    roll:: Union{Float32, Nothing}
    pitch:: Union{Float32, Nothing}
    temperature:: Union{Float32, Nothing}
    offset:: Union{Int32, Nothing}
    count:: Union{Int32, Nothing}
end

function Sample(; channel=nothing, channelId=nothing, dataType=nothing, spare=nothing,
    heading=nothing, acidity=nothing, pulseForm=nothing, slope=nothing, salinity=nothing,
    mode=nothing, transducerDepth=nothing, frequency=nothing, transmitPower=nothing,
    pulseLength=nothing, bandWidth=nothing, sampleInterval=nothing, soundVelocity=nothing,
    absorptionCoefficient=nothing, heave=nothing, roll=nothing, pitch=nothing,
    temperature=nothing, offset=nothing, count=nothing)

    Sample(channel, channelId, dataType, spare,
           heading, acidity, pulseForm, slope, salinity,
           mode, transducerDepth, frequency, transmitPower,
           pulseLength, bandWidth, sampleInterval, soundVelocity,
           absorptionCoefficient, heave, roll, pitch,
           temperature, offset, count)
end
# Define a structure for the data
struct Data
    power::Vector{Float64}
    angleAthwartship::Vector{Float64}
    angleAlongship::Vector{Float64}
end

mutable struct GPSDataRAW
    time::Float64
    latitude::Float64
    longitude::Float64
    GPSDataRAW() = new(-1.0, 0.0, 0.0)  # Constructor sets default values
    GPSDataRAW(t::Float64, lat::Float64, lon::Float64) = new(t, lat, lon)
end 


struct DataRAW3
    power::Union{Vector{Float64}, Nothing}                  # Optional backscatter power values
    angleAthwartship::Union{Vector{Float64}, Nothing}       # Optional athwartship beam angle
    angleAlongship::Union{Vector{Float64}, Nothing}         # Optional alongship beam angle
    waveform::Union{Matrix{ComplexF16}, Matrix{ComplexF32}, Nothing}  # Optional waveform matrix
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

# Define a structure for the configuration datagram
struct CON0 <: AbstractDatagramRAW
    header::Header
    transducer::Vector{Transducer}
    
end

# Define a structure for the tag datagram
struct TAG0 <: AbstractDatagramRAW
    GPSDataRAW::Vector{GPSDataRAW}
end

# Define a structure for the NMEA datagram
struct NME0 <: AbstractDatagramRAW
    nmea:: String
end

# Define a structure for the raw datagram
struct RAW0 <: AbstractDatagramRAW
    sample::Sample
    data::Data
end

struct RAW3 <: AbstractDatagramRAW
    sample::Sample
    data::DataRAW3
end

struct MRU0
    heave::Float32
    roll::Float32
    pitch::Float32
    heading::Float32
end


struct XML0Transducer
    TransducerName::String
    SoundSpeed::Float64
end

struct Channel
    SampleInterval::Float64
    PulseForm::Int
    TransmitPower::Float64
    SoundVelocity::Float64
    Slope::Float64
    FrequencyEnd::Float64
    ChannelMode::Int
    PulseDuration::Float64
    FrequencyStart::Float64
    ChannelID::String
end

struct Environment
    _Depth::Float64
    SoundVelocitySource::String
    DropKeelOffset::Float64
    WaterLevelDraftIsManual::Bool
    _SoundSpeed::Float64
    _Temperature::Float64
    _Salinity::Float64
    _Acidity::Float64
    DropKeelOffsetIsManual::Bool
    SoundVelocityProfile::String  # You could parse it into a vector of tuples if needed
    TowedBodyDepth::Float64
    TowedBodyDepthIsManual::Bool
    WaterLevelDraft::Float64
    Latitude::Float64
    Transducer::XML0Transducer
end

struct Parameter
    Channel::Channel
end

struct Ping
    ChannelID::String
end

struct PingSequence
    Pings::Vector{Ping}
end

struct XML0
    name::String
    content::Union{Nothing, String}
    Environment::Union{Nothing, Dict{String, Any}}
    PingSequence::Union{Nothing, Dict{String, Any}}
    Parameter::Union{Nothing, Dict{String, Any}}
    InitialParameter::Union{Nothing, Dict{String, Any}}
    configuration:: Union{Nothing, Dict{String, Any}}
end


mutable struct FIL1
    stage::Int16
    filterType::Char
    channelID::String
    noOfCoefficients::Int16
    decimationFactor::Int16
    coefficients::Vector{ComplexF32}
end

mutable struct SonarDataRAW
    name::String
    P::Matrix{Float64} 
    Q::Vector{Sample}  
    G::Vector{GPSDataRAW}
    R::Union{Nothing,
     Union{Vector{Int64}, Vector{Float64}}}
end

SonarDataRAW(name::String, P::Matrix{Float64}, Q::Vector{Sample}, G::Vector{GPSDataRAW}) = 
    SonarDataRAW(name, P, Q, G, nothing)


# Constants
const DatagramTypeMap = Dict(
    "CON0" => CON0,
    "NME0" => NME0,
    "TAG0" => TAG0,
    "RAW0" => RAW0,
    "MRU0" => MRU0,
    "RAW3" => RAW3,
    "XML0" => XML0,
    "FIL1" => FIL1
    # Add more mappings as needed
)

export DatagramTypeMap, SonarDataRAW, Header, Sample, RAW0, RAW3, NME0, TAG0, CON0, Transducer,
GPSDataRAW, MRU0, AbstractDatagramRAW, FIL1, XML0, Data, DataRAW3, AbstractSample

end