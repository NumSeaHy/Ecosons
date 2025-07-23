module DataTypesSimradDG
abstract type AbstractTelegramDG end

mutable struct HSInfo
    channel::Int
    transducerDepth::Float64
    heave::Float64
    roll::Float64
    pitch::Float64
    frequency::Int
    transmitPower::Float64
    pulseLength::Float64
    bandWidth::Float64
    sampleInterval::Float64
    soundVelocity::Float64
    absorptionCoefficient::Float64
    temperature::Float64
    offset::Int
    count::Int
end

function HSInfo(; channel=1, transducerDepth=0.0, heave=0.0, roll=0.0, pitch=0.0,
                  frequency=200_000, transmitPower=125.0, pulseLength=0.0, bandWidth=NaN,
                  sampleInterval=0.0, soundVelocity=1500.0, absorptionCoefficient=10.0,
                  temperature=NaN, offset=0, count=0)
    new_instance = HSInfo(
        channel, transducerDepth, heave, roll, pitch,
        frequency, transmitPower, pulseLength, bandWidth,
        sampleInterval, soundVelocity, absorptionCoefficient,
        temperature, offset, count
    )
    return new_instance
end

mutable struct GPSDataDG
    time::Float64
    latitude::Float64
    longitude::Float64
    GPSDataDG() = new(-1.0, 0.0, 0.0)  # Constructor sets default values
    GPSDataDG(t::Float64, lat::Float64, lon::Float64) = new(t, lat, lon)

end

struct DGTelegram
    length::Int32
    type::String
    time::Float64
    data::Dict{Symbol,Any}
end

    
struct UnknownTelegram <: AbstractTelegramDG end

mutable struct SonarDataDG
    name::String
    P::Matrix{Float64} 
    Q::Vector{HSInfo}
    G::Vector{GPSDataDG}
    R::Union{Nothing, Vector{Int}}
end

SonarDataDG(name::String, P::Matrix{Float64}, 
    Q::Vector{HSInfo}, G::Vector{GPSDataDG}) = 
    SonarDataDG(name, P, Q, G, nothing
)


# A default unknown telegram
struct UnknownTelegramDG <: AbstractTelegramDG end

# A skipped telegram, e.g., for types we don't parse
struct SkippedTelegram <: AbstractTelegramDG
    time::Float64
    info::Dict{Symbol, Any}
end

# Individual telegram structures
struct W1Telegram <: AbstractTelegramDG
    time::Float64
    data::Dict{Symbol, Any}
end

struct B1Telegram <: AbstractTelegramDG
    time::Float64
    data::Dict{Symbol, Any}
end

struct GLTelegram <: AbstractTelegramDG
    time::Float64
    gpos::Dict{Symbol, Float64}
end

struct D1Telegram <: AbstractTelegramDG
    time::Float64
    data::Dict{Symbol, Any}
end

struct E1Telegram <: AbstractTelegramDG
    time::Float64
    data::Dict{Symbol, Any}
end

struct S1Telegram <: AbstractTelegramDG
    time::Float64
    data::Dict{Symbol, Any}
end

struct Q1Telegram <: AbstractTelegramDG
    time::Float64
    data::Dict{Symbol, Any}
end

struct V1Telegram <: AbstractTelegramDG
    time::Float64
    data::Dict{Symbol, Any}
end

struct P1Telegram <: AbstractTelegramDG
    time::Float64
    data::Dict{Symbol, Any}
end

struct VLTelegram <: AbstractTelegramDG
    time::Float64
    data::Dict{Symbol, Any}
end

export AbstractTelegramDG, UnknownTelegramDG, SkippedTelegram, 
       W1Telegram, B1Telegram, GLTelegram, D1Telegram,
       E1Telegram, S1Telegram, Q1Telegram, V1Telegram,
       GPSDataDG, HSInfo, DGTelegram, P1Telegram, VLTelegram,
       SonarDataDG
end