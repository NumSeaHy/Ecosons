include("interp1.jl")
using Interpolations

function pingStretch(
    P::Vector{Float64},
    R::Union{Int64, Float64}, 
    Rmx::Int64, 
    R2::Union{Nothing, Int64, Float64} = nothing
    )

    PP = fill(NaN, Rmx)
    PP2 = fill(NaN, Rmx)

    if R > 4
        R = Int64(R)
        ll = min(R - 2, length(P) - R)
        if ll > 1
            x_orig = 0:ll
            x_new = ((R - 2) / (Rmx - 1)) * collect(0:(Rmx - 1))
            PP = interp1(x_orig, P[R:(R + ll)], x_new; method="nearest", extrap=NaN)
        end

        if R2 !== nothing && R2 > R + 4
            R2 = Int64(R2)
            ll2 = min(R - 2, length(P) - R2)
            if ll2 > 1
                x_orig2 = 0:ll2
                x_new2 = ((R - 2) / (Rmx - 1)) * collect(0:(Rmx - 1))
                PP2 = interp1(x_orig2, P[R2:(R2 + ll2)], x_new2; method="linear", extrap=NaN)     
            end
        end
    end

    return PP, PP2
end


