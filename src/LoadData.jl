"""Functions to load and parse sonar data files"""
module LoadData
using Dates
using ..DataTypes
using ..Utils

include("./lib/procs/loadJLD2.jl")
include("./lib/procs/saveJLD2.jl")
include("./lib/formats/simradRAW.jl")
include("./lib/utils/extractIdentifier.jl")
include("./lib/formats/simradDG.jl")
include("./lib/formats/lowrance/lowranceSLG.jl")


function load_sonar_data(
    channel::Int,
    f_dir_raw::Vector{String};
    jld2_path::Union{Nothing, String} = nothing,
    sel::Int = 1,
    load_cached::Bool = true,
    )

    angles = nothing

    # Attempt to load cached data if requested
    if load_cached && jld2_path !== nothing
        try
            sonar_array = loadJLD2(jld2_path; isdata=true)
            println("Loaded sonar data from $(jld2_path).jld2")
            return sonar_array, length(sonar_array)
        catch e
            println("Failed to load cached data: ", e.msg)
            println("Proceeding to parse raw files...")
        end
    end

    n = length(f_dir_raw)
    if sel == 1
        sonar_data = Vector{SonarDataRAW}(undef, n)
    elseif sel == 2
        sonar_data = Vector{SonarDataDG}(undef, n)
    else
        sonar_data = Vector{SonarDataLowrance}(undef, n)
    end
    successful_loads = 0 # To count successfully loaded files
    for i in 1:n
        try
            name = extract_identifier(f_dir_raw[i])
            if sel == 1
                P, Q, G, _ = simradRAW(f_dir_raw[i])
                sonar_data[successful_loads + 1] = SonarDataRAW(name, P[channel], Q[channel], G[channel])
            elseif sel == 2
                P, Q, G = simradDG(f_dir_raw[i])
                sonar_data[successful_loads + 1] = SonarDataDG(name, P[channel], Q[channel], G[channel])
            elseif sel == 3
                if channel != 1
                    error("Doesn't support more than one channel")
                end
                P, Q, G = lowranceSLG(f_dir_raw[i])
                println(G)
                sonar_data[successful_loads + 1] = SonarDataLowrance(name, P[channel], Q[channel], G[channel])
            end
            successful_loads += 1
            println("Loaded: ", name) 
        catch e
            if isa(e, EOFError)
                println("EOFError encountered for file: ", f_dir_raw[i], ". Skipping this file.")
            else
                # Re-throw the exception if it's not an EOFError
                rethrow()
            end
        end
    end
    # Resize sonar_data to the number of successfully loaded entries
    resize!(sonar_data, successful_loads)

    return sonar_data, successful_loads, angles
end

export load_sonar_data, loadJLD2, saveJLD2, simradRAW, extract_identifier



end