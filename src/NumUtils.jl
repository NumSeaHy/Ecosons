""""Numerical utilities"""
module NumUtils

using Statistics, LinearAlgebra

include("./lib/utils/nnstd.jl")
include("./lib/utils/nnmean.jl")
include("./lib/utils/wmean.jl")
include("./lib/utils/nnsum.jl")
include("./lib/utils/linreg.jl")

export nnstd, nnmean, wmean, nnsum, linreg

end 