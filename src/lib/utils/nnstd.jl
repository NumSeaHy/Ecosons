"""std ignoring NaNs"""
function nnstd(x::AbstractArray)
    if minimum(size(x)) == 1
        xm = .!isnan.(x)
        if any(xm)
            return std(x[xm])
        else
            return NaN
        end
    else
        s = similar(x, axes(x, 2))
        for n in axes(x, 2)
            xc = x[:, n]
            xm = .!isnan.(xc)
            s[n] = any(xm) ? std(xc[xm]) : NaN
        end
        return s
    end
end