""" Interpolation functions"""
module Interpolation

using LinearAlgebra, Statistics, ImageFiltering, DSP
using ..DataTypes:GPSDataRAW

include("./lib/utils/intershapes.jl")
include("./lib/utils/xyz2img.jl")
include("./lib/utils/trinterpmap.jl")
include("./lib/utils/trinterpmapUTM.jl")
include("./lib/procs/interpPS.jl")
include("./lib/utils/triginterp.jl")
include("./lib/procs/interpolateGrid.jl")

export intershapes, xyz2img, trinterpmap, interpPS!,
trinterpmapUTM, triginterp, interpolateGrid
    
end