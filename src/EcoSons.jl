module EcoSons

using Reexport

# Include all source modules here
include("DataTypes.jl")
include("Models.jl")
include("Utils.jl")
include("LoadData.jl")
include("SelectData.jl")
include("SignalProcessing.jl")
include("ComputeBathymetry.jl")
include("Plotting.jl")
include("Interpolation.jl")
include("Preprocessing.jl")
include("ExportData.jl")
include("Tides.jl")
include("Slopes.jl")
include("Classification.jl")

@reexport using .DataTypes
@reexport using .Models
@reexport using .Utils
@reexport using .LoadData
@reexport using .SelectData
@reexport using .SignalProcessing
@reexport using .ComputeBathymetry
@reexport using .Plotting
@reexport using .Interpolation
@reexport using .Preprocessing
@reexport using .ExportData
@reexport using .Tides
@reexport using .Slopes
@reexport using .Classification

function print_about()
    println("Ecosons is free software released under the GNU General Public License (GNU-GPL).")
    println("  → http://www.gnu.org/copyleft/gpl.html")
    println("http://www.kartenn.net")
    println("This is the Julia version of Ecosons, developed by Carlos Vázquez Monzón")
end

print_about()

end
