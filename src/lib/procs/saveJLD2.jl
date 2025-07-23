using JLD2

"""
Saves an array of SonarDataRAW objects to a single `.jld2` file.
"""
function saveJLD2(fn::String, dataArray::Vector{SonarDataRAW})
    isempty(fn) && throw(ArgumentError("Filename cannot be empty"))

    # Validate each element
    for (i, data) in enumerate(dataArray)
        for fld in (:name, :P, :Q, :G, :R)
            if !(fld in fieldnames(typeof(data))) || getfield(data, fld) === nothing
                throw(ArgumentError("SonarDataRAW element $i missing or empty field: $fld"))
            end
        end
    end

    filepath = fn * ".jld2"
    @save filepath SONAR_ARRAY=dataArray
    println("Saved $(length(dataArray)) SonarDataRAW objects to $(filepath)")
end


"""
Saves an array of Bathymetry objects to a single `.jld2` file.
"""
function saveJLD2(fn::String, baths::Vector{Bathymetry})
    isempty(fn) && throw(ArgumentError("Filename cannot be empty"))

    # Validate each element
    for (i, bath) in enumerate(baths)
        for fld in (:name, :time, :longitude, :latitude, :depth)
            if !(fld in fieldnames(typeof(bath))) || getfield(bath, fld) === nothing
                throw(ArgumentError("Bathymetry element $i missing or empty field: $fld"))
            end
        end
    end

    filepath = fn * ".jld2"
    @save filepath BATHY_ARRAY=baths
    println("Saved $(length(baths)) Bathymetry objects to $(filepath)")
end

"""
Saves a vector of vector with generic type.
"""
function saveJLD2(fn::String, dataArray::Vector{Any})
    isempty(fn) && throw(ArgumentError("Filename cannot be empty"))

    filepath = fn * "_classification.jld2"
    @save filepath SONAR_ARRAY=dataArray
    println("Save sonar_data object for classification tasks!")
end

