"""Mean ignoring NaNs"""
function nnmean(x::AbstractArray)
    if minimum(size(x)) == 1
        xm = .!isnan.(x)
        if any(xm)
            return mean(x[xm])
        else
            return NaN
        end
    else
        s = similar(x, axes(x, 2))
        for n in axes(x, 2)
            xc = x[:, n]
            xm = .!isnan.(xc)
            s[n] = any(xm) ? mean(xc[xm]) : NaN
        end
        return s
    end
end