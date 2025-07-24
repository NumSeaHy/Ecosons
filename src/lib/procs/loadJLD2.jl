using JLD2

"""
Load an array (or nested array) of SonarDataRAW or Bathymetry objects from a `.jld2` file.

# Arguments
- `fn::String`: Path to the `.jld2` file (without extension).
- `isbath::Bool`: Set `true` to load Bathymetry array.
- `isdata::Bool`: Set `true` to load SonarDataRAW array.

# Returns
- An array of Bathymetry or SonarDataRAW objects (can be nested for SONAR_ARRAY).

# Notes
- Exactly one of `isbath` or `isdata` must be true.
- Expects arrays saved with keys `"BATHY_ARRAY"` or `"SONAR_ARRAY"` respectively.
"""
function loadJLD2(fn::String; isbath::Bool=false, isdata::Bool=false)
    if isbath == isdata
        throw(ArgumentError("Exactly one of `isbath` or `isdata` must be true"))
    end

    filepath = fn * ".jld2"
    if !isfile(filepath)
        throw(ArgumentError("File does not exist: $filepath"))
    end

    if isbath
        @load filepath BATHY_ARRAY
        if !@isdefined BATHY_ARRAY
            throw(KeyError("Key 'BATHY_ARRAY' not found in $filepath"))
        end
        println("Bathymetry array loaded from $filepath")
        return BATHY_ARRAY

    else 
        @load filepath SONAR_ARRAY
        if !@isdefined SONAR_ARRAY
            throw(KeyError("Key 'SONAR_ARRAY' not found in $filepath"))
        end
        
        # Sanity check: should be Vector or Vector of Vectors
        if !(SONAR_ARRAY isa Vector)
            throw(TypeError(:SONAR_ARRAY, "Vector or Vector of Vectors", typeof(SONAR_ARRAY)))
        end

        return SONAR_ARRAY
    end
end
