"""Mathematical models used in sonar interpretation"""
module Models

using ..DataTypes

include("./lib/models/alphaAinslieMcColm.jl")
include("./lib/models/velocityUNESCO.jl")
include("./lib/models/convertTrueDepth.jl")
include("./lib/models/ArcLengthOfMeridian.jl")

export alphaAinslieMcColm, velocityUNESCO, convert_true_depth, ArcLengthOfMeridian
    
end