module DataTypes

using Reexport

include("./lib/formats/DataTypesLowrance.jl")
include("./lib/formats/DataTypesSimradDG.jl")
include("./lib/formats/DataTypesSimradRaw.jl")
include("./lib/formats/dataTypesGeneral.jl")

@reexport using .DataTypesLowrance
@reexport using .DataTypesSimradRaw
@reexport using .DataTypesGeneral
@reexport using .DataTypesSimradDG


end