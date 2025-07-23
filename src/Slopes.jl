"""Computation of seafloor slopes or gradients from bathymetry data"""
module Slopes

using Statistics
using ..DataTypes: Bathymetry, Slope
using ..Utils: latlon2utmxy, csvreadcols, extractCols

include("./lib/bathymetry/bathymetry_resampling.jl")
include("./lib/procs/slopesFromBathymetry.jl")
include("./lib/bathymetry/computeSlopes.jl")

export computeSlopes, resampleBathymetry, slopesFromBathymetry

end