"""Preprocessing functions before exporting/plotting data"""
module Preprocessing

using ..Utils:latlon2utmxy
using ..DataTypes: Bathymetry, TransectCross, SonarDataRAW

include("./lib/bathymetry/computeCrosses.jl")
include("./lib/bathymetry/preproc_transects.jl")
include("./lib/bathymetry/preproc_interpolation.jl")

export computeCrosses, preproc_interpolation, preproc_transects

end