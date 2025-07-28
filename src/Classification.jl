module Classification

using Statistics, LinearAlgebra
using ..DataTypes: classifStruct
using ..Models: convert_true_depth
using ..Utils: nnmean, nnstd

include("./lib/classif/clsplot.jl")
include("./lib/classif/test_class_config.jl")
include("./lib/classif/test_class_load.jl")
include("./lib/classif/test_class_class.jl")
include("./lib/classif/test_class_Es.jl")
include("./lib/classif/test_class_plots.jl")
include("./lib/classif/mrinterp.jl")

export test_class_class, ping_average0, test_class_Es, mrinterp, clsplot, test_class_load,
ping_average1, ping_distance1, ping_distance1a, ping_distance2, ping_distance2a, ping_distance3,
plot_class_map, plot_mean_std, plot_median_range, plot_min_max

end