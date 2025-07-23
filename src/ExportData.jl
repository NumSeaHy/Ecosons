"""Exporting processed data to various file formats (e.g., JLD2, CSV)"""
module ExportData 

using ..DataTypes: Bathymetry, SonarDataRAW, TransectCross, Slope
using ..Utils: latlon2utm
using ..Models: convert_true_depth

include("./lib/bathymetry/export_bathycross.jl")
include("./lib/bathymetry/export_bathymetry.jl")
include("./lib/bathymetry/export_transects.jl")
include("./lib/bathymetry/export_echobottom.jl")
include("./lib/bathymetry/export_interpolation.jl")
include("./lib/bathymetry/export_slopes.jl")

export export_bathycross, export_echobottom, export_transects,
export_interpolation, export_slopes, export_bathymetry, img2esriascii,
img2envi, img2enviUTM

end