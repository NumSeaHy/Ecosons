"""Miscellaneous utility functions used throughout the package"""
module OtherUtils

using ..GeoTimeUtils: latlon2utmxy

include("./lib/utils/csvreadcols.jl")
include("./lib/utils/tsvreadcols.jl")
include("./lib/utils/extractCols.jl")
include("./lib/utils/convertMatrices.jl")
include("./lib/procs/radialSubsampling.jl")
include("./lib/utils/trims.jl")
include("./lib/utils/allbut.jl")
include("./lib/utils/parseFnameDate.jl")
include("./lib/procs/resampleANDrescale.jl")

export extractCols, matrix2PGM, matrix2PPM, matrix2PPM_RGB,
radialSubsampling, trims, allbut, resampleANDrescale, parseFnameDate,
csvreadcols, parseCSVline, tsvreadcols

end