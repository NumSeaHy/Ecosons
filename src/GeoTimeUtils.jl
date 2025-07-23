""" Geospatial and temporal utility functions (coordinate conversions, time handling)"""
module GeoTimeUtils

using Statistics, Dates, LinearAlgebra
using ..DataTypes: SonarDataRAW, GPSDataRAW
using ..Models: ArcLengthOfMeridian
include("./lib/utils/latlon2utmxy.jl")
include("./lib/utils/latlon2utm.jl")
include("./lib/utils/hms2frachrs.jl")
include("./lib/utils/localtime.jl")
include("./lib/procs/gcoords2distances.jl")
include("./lib/procs/trload.jl")


export latlon2utmxy, latlon2utm, hms2t, gcoords2distances, trload, localtime

end