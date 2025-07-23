"""Functions related to tidal calculations and corrections"""
module Tides

using ..DataTypes: Bathymetry
using ..Utils: parseFnameDate
using ..Interpolation: triginterp

include("./lib/bathymetry/bathymetry_tidecorrection.jl")

export tidecorrect, tidecorrectDay, tideCorrection!

end