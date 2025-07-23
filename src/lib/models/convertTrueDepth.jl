"""
Converts raw depth measurements to true depth in meters.
"""
function convert_true_depth(depth::Union{Int64, Vector{Int64}, Float64, Vector{Float64}}, data::SonarDataRAW; ping::Int = 1)
    factor = 0.5 * data.Q[ping].sampleInterval * data.Q[ping].soundVelocity
    return depth .* factor
end

function convert_true_depth(depth::Union{Int64, Vector{Int64}, Float64, Vector{Float64}}, Q::Vector{Sample}; ping::Int = 1)
    factor = 0.5 * Q[ping].sampleInterval * Q[ping].soundVelocity
    return depth .* factor
end
