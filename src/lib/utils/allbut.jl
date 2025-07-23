"""
Return a collection containing all elements of `x_all` except those present in `x_but`.
This is equivalent to performing a set difference, but preserves the order and multiplicity 
(if any) from `x_all`.
"""
function allbut(x_all::AbstractVector, x_but::AbstractVector)::AbstractVector
    return filter(x -> x ∉ x_but, x_all) 
end