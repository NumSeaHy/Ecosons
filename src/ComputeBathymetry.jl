"""Core algorithms to compute bathymetry (seafloor depth) from sonar data"""

module ComputeBathymetry

using ..DataTypes
using ..Models
using ..Utils

include("./lib/bathymetry/compute_bathymetry.jl")
include("./lib/bathymetry/bathymetry_subsampling.jl")
include("./lib/bathymetry/bathymetry_bottom.jl")
include("./lib/procs/bathymetryCrosses.jl")

export compute_bathymetry, compute_bottom, subsampleBathymetry!, bathymetryCrosses,
getAverageHit, getFirstHit, set_sound_velocity!

"""Set sound velocity"""
function set_sound_velocity!(data::Array{SonarDataRAW}; velocity::Float64 = 1500.0)::Array{SonarDataRAW}
    for sonar in data
        for q in sonar.Q
            q.soundVelocity = velocity
        end
    end
    return data
end


end