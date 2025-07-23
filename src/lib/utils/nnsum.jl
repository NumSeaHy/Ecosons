"""
Sum ignoring NaNs. Supports scalars, vectors, matrices, and arrays with a `dim` keyword.
Returns NaN if all elements along a slice are NaN.
"""
function nnsum(x::Union{Float64, AbstractArray{Float64}}; dim::Int=1)::Union{AbstractArray{Float64}, Float64}
    if isa(x, Float64)
        return isnan(x) ? NaN : x
    elseif ndims(x) == 1
        vals = x[.!isnan.(x)]
        return isempty(vals) ? NaN : sum(vals)
    else
        sz = size(x)
        out = Array{Float64}(undef, Tuple(deleteat!(collect(sz), dim)))
        inds = CartesianIndices(out)
        for I in inds
            idx = ntuple(d -> d < dim ? I[d] : d == dim ? Colon() : I[d-1], ndims(x))
            slice = view(x, idx...)
            vals = slice[.!isnan.(slice)]
            out[I] = isempty(vals) ? NaN : sum(vals)
        end

        return out
    end
end
