function clsintree(classvec::Vector{Int}, idx::Int)::Int
    while 1 <= idx <= length(classvec) && classvec[idx] != idx
        idx = classvec[idx]
    end
    return idx
end